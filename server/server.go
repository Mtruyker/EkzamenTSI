package main

import (
	crand "crypto/rand"
	"crypto/subtle"
	"encoding/base64"
	"encoding/csv"
	"encoding/json"
	"fmt"
	"math"
	"math/rand"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"time"
)

// --- СТРУКТУРЫ БАЗЫ ВОПРОСОВ ---

type Question struct {
	ID          int      `json:"id"`
	Type        string   `json:"type"` // single, multiple, text, essay
	Text        string   `json:"text"`
	Options     []string `json:"options,omitempty"`
	Correct     []int    `json:"correct,omitempty"`
	CorrectText []string `json:"correct_text,omitempty"`
	Points      int      `json:"points"`
}

type ExamConfig struct {
	Title               string     `json:"title"`
	TimeLimitMinutes    int        `json:"time_limit_minutes"`
	QuestionsPerStudent int        `json:"questions_per_student"`
	Questions           []Question `json:"questions"`
}

// --- СТРУКТУРЫ КЛИЕНТА И СЕССИЙ ---

type ClientQuestion struct {
	ID      int      `json:"id"`
	Type    string   `json:"type"`
	Text    string   `json:"text"`
	Options []string `json:"options,omitempty"`
	Points  int      `json:"points"`
}

type StudentAnswer struct {
	QuestionID int    `json:"question_id"`
	Selected   []int  `json:"selected,omitempty"`    // Индексы, которые выбрал студент (в перемешанном виде)
	TextAnswer string `json:"text_answer,omitempty"` // Текстовый ответ для text / essay
	Flagged    bool   `json:"flagged"`               // Пометка "Вернуться позже"
}

type StudentSession struct {
	SessionKey       string                `json:"session_key"`
	FullName         string                `json:"full_name"`
	Group            string                `json:"group"`
	IP               string                `json:"ip"`
	Status           string                `json:"status"` // "testing", "submitted", "blocked", "timeout"
	BlockReason      string                `json:"block_reason,omitempty"`
	StartedAt        time.Time             `json:"started_at"`
	FinishedAt       *time.Time            `json:"finished_at,omitempty"`
	Deadline         time.Time             `json:"deadline"`          // Серверный дедлайн: единственный источник времени
	RemainingSeconds int                   `json:"remaining_seconds"` // Фиксируется при завершении попытки
	Token            string                `json:"token,omitempty"`   // Секрет сессии; скрывается в админке
	LastSeen         time.Time             `json:"last_seen"`         // Время последнего heartbeat клиента
	AssignedQs       []ClientQuestion      `json:"assigned_qs"`
	OptionMapping    map[int][]int         `json:"option_mapping"` // QuestionID -> [ShuffledIdx -> OriginalIdx]
	Answers          map[int]StudentAnswer `json:"answers"`
	Score            int                   `json:"score"`
	MaxScore         int                   `json:"max_score"`
	Percentage       float64               `json:"percentage"`
	Grade            int                   `json:"grade"`
}

type ServerState struct {
	CurrentFile string                     `json:"current_file"`
	Config      ExamConfig                 `json:"config"`
	Sessions    map[string]*StudentSession `json:"sessions"`
}

var (
	state = ServerState{
		CurrentFile: "questions.json",
		Sessions:    make(map[string]*StudentSession),
	}
	mu sync.RWMutex
)

const backupFile = "backup_state.json"

// Порог, после которого отсутствие heartbeat помечается в панели как потеря связи
const heartbeatLostAfter = 30 * time.Second

// Пароль панели преподавателя (HTTP Basic Auth, логин не используется)
var adminPassword string

// Собственный генератор для перемешивания билетов; rand.Seed глобальный и устарел
var rng = rand.New(rand.NewSource(time.Now().UnixNano()))

func main() {
	initAdminPassword()

	// Загружаем вопросы и восстанавливаем бэкап при наличии
	if err := loadQuestions(state.CurrentFile); err != nil {
		fmt.Printf("[!] Внимание: не удалось загрузить %s: %v\n", state.CurrentFile, err)
	}
	loadBackup()

	// Фоновый таймер: завершает попытки, у которых истекло серверное время
	go func() {
		for range time.Tick(time.Second) {
			mu.Lock()
			now := time.Now()
			changed := false
			for _, s := range state.Sessions {
				if finishExpiredLocked(s, now) {
					changed = true
				}
			}
			if changed {
				saveBackupLocked()
			}
			mu.Unlock()
		}
	}()

	// Роутинг API Студента
	http.HandleFunc("/api/info", cors(handleInfo))
	http.HandleFunc("/api/start", cors(handleStart))
	http.HandleFunc("/api/progress", cors(handleProgress))
	http.HandleFunc("/api/submit", cors(handleSubmit))
	http.HandleFunc("/api/heartbeat", cors(handleHeartbeat))

	// Роутинг Веб-панели Преподавателя
	http.HandleFunc("/admin", requireAdmin(handleAdminPage))
	http.HandleFunc("/api/admin/state", requireAdmin(handleAdminState))
	http.HandleFunc("/api/admin/action", requireAdmin(handleAdminAction))
	http.HandleFunc("/api/admin/config", requireAdmin(handleAdminConfig))
	http.HandleFunc("/api/admin/export", requireAdmin(handleAdminExport))

	port := "8080"
	fmt.Println("=========================================================")
	fmt.Println("  Система «ExamTheory-Local» запущена!")
	fmt.Printf("  Панель преподавателя: http://localhost:%s/admin\n", port)
	printLocalIPs(port)
	fmt.Println("=========================================================")

	// Таймауты защищают от зависших соединений; ответы сервера небольшие
	srv := &http.Server{
		Addr:              "0.0.0.0:" + port,
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       15 * time.Second,
		WriteTimeout:      30 * time.Second,
		IdleTimeout:       60 * time.Second,
	}
	if err := srv.ListenAndServe(); err != nil {
		fmt.Printf("Ошибка запуска сервера: %v\n", err)
	}
}

// --- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ---

func printLocalIPs(port string) {
	addrs, err := net.InterfaceAddrs()
	if err != nil {
		return
	}
	for _, address := range addrs {
		if ipnet, ok := address.(*net.IPNet); ok && !ipnet.IP.IsLoopback() {
			if ipnet.IP.To4() != nil {
				fmt.Printf("  Адрес для клиентов в ЛВС: http://%s:%s\n", ipnet.IP.String(), port)
			}
		}
	}
}

func cors(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusOK)
			return
		}
		next(w, r)
	}
}

// Пароль берётся из переменной окружения ADMIN_PASSWORD; если она не задана,
// генерируется случайный и выводится в консоль при запуске.
func initAdminPassword() {
	adminPassword = os.Getenv("ADMIN_PASSWORD")
	if adminPassword != "" {
		fmt.Println("[+] Пароль панели преподавателя задан через ADMIN_PASSWORD")
		return
	}
	buf := make([]byte, 12)
	if _, err := crand.Read(buf); err != nil {
		panic(fmt.Sprintf("не удалось сгенерировать пароль панели: %v", err))
	}
	adminPassword = base64.RawURLEncoding.EncodeToString(buf)
	fmt.Printf("[!] ADMIN_PASSWORD не задан. Временный пароль панели преподавателя: %s\n", adminPassword)
}

func requireAdmin(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		_, pass, ok := r.BasicAuth()
		if !ok || subtle.ConstantTimeCompare([]byte(pass), []byte(adminPassword)) != 1 {
			w.Header().Set("WWW-Authenticate", `Basic realm="ExamTheory-Local admin", charset="UTF-8"`)
			http.Error(w, "Требуется авторизация", http.StatusUnauthorized)
			return
		}
		next(w, r)
	}
}

func getClientIP(r *http.Request) string {
	ip, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		return r.RemoteAddr
	}
	return ip
}

func normalizeKey(fullName, group, ip string) string {
	cleanName := strings.ToLower(strings.TrimSpace(fullName))
	cleanGroup := strings.ToLower(strings.TrimSpace(group))
	return fmt.Sprintf("%s|%s|%s", cleanName, cleanGroup, ip)
}

// Разрешаем только простое имя *.json из рабочей папки сервера: без путей и служебных файлов
func safeBankFileName(name string) (string, error) {
	base := filepath.Base(name)
	if base != name || strings.ContainsAny(name, `/\:`) {
		return "", fmt.Errorf("имя файла должно быть без пути")
	}
	if !strings.HasSuffix(strings.ToLower(base), ".json") || strings.HasPrefix(base, ".") {
		return "", fmt.Errorf("допускаются только файлы .json")
	}
	if base == backupFile {
		return "", fmt.Errorf("этот файл нельзя использовать как банк вопросов")
	}
	return base, nil
}

func loadQuestions(filename string) error {
	data, err := os.ReadFile(filename)
	if err != nil {
		return err
	}
	var cfg ExamConfig
	if err := json.Unmarshal(data, &cfg); err != nil {
		return err
	}
	state.Config = cfg
	state.CurrentFile = filename
	fmt.Printf("[+] Загружен банк вопросов '%s' (%d вопр., лимит %d мин.)\n",
		cfg.Title, len(cfg.Questions), cfg.TimeLimitMinutes)
	return nil
}

// Атомарная запись: во временный файл, затем переименование, чтобы сбой питания
// во время записи не оставлял битый backup_state.json
func saveBackupLocked() {
	data, err := json.MarshalIndent(state.Sessions, "", "  ")
	if err != nil {
		return
	}
	tmp := backupFile + ".tmp"
	if err := os.WriteFile(tmp, data, 0644); err != nil {
		return
	}
	if err := os.Rename(tmp, backupFile); err != nil {
		_ = os.Remove(tmp)
	}
}

func loadBackup() {
	data, err := os.ReadFile(backupFile)
	if err != nil {
		return
	}
	var loaded map[string]*StudentSession
	if err := json.Unmarshal(data, &loaded); err == nil && loaded != nil {
		// Для сессий из старых бэкапов без дедлайна восстанавливаем его по сохранённому остатку
		now := time.Now()
		for _, s := range loaded {
			if s.Status == "testing" && s.Deadline.IsZero() {
				s.Deadline = now.Add(time.Duration(s.RemainingSeconds) * time.Second)
			}
		}
		state.Sessions = loaded
		fmt.Printf("[+] Восстановлено сессий из backup_state.json: %d\n", len(loaded))
	}
}

// Оставшееся время считается от серверного дедлайна, а не от данных клиента
func remainingNow(s *StudentSession, now time.Time) int {
	if s.Status != "testing" {
		return s.RemainingSeconds
	}
	left := int(math.Ceil(s.Deadline.Sub(now).Seconds()))
	if left < 0 {
		return 0
	}
	return left
}

// Переводит попытку в "timeout", если серверное время вышло. Возвращает true, если статус изменился.
func finishExpiredLocked(s *StudentSession, now time.Time) bool {
	if s.Status != "testing" || now.Before(s.Deadline) {
		return false
	}
	s.Status = "timeout"
	s.RemainingSeconds = 0
	s.FinishedAt = &now
	calculateScore(s)
	return true
}

func newToken() string {
	buf := make([]byte, 32)
	if _, err := crand.Read(buf); err != nil {
		panic(fmt.Sprintf("не удалось сгенерировать токен сессии: %v", err))
	}
	return base64.RawURLEncoding.EncodeToString(buf)
}

func checkToken(s *StudentSession, token string) bool {
	return s.Token != "" && subtle.ConstantTimeCompare([]byte(s.Token), []byte(token)) == 1
}

func writeResult(w http.ResponseWriter, s *StudentSession, code int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	json.NewEncoder(w).Encode(map[string]any{
		"score":      s.Score,
		"max_score":  s.MaxScore,
		"percentage": s.Percentage,
		"grade":      s.Grade,
		"status":     s.Status,
		"reason":     s.BlockReason,
	})
}

// Формирование индивидуального перемешанного билета
func generateTicket(cfg ExamConfig) ([]ClientQuestion, map[int][]int, int) {
	pool := make([]Question, len(cfg.Questions))
	copy(pool, cfg.Questions)

	// Перемешиваем вопросы
	rng.Shuffle(len(pool), func(i, j int) {
		pool[i], pool[j] = pool[j], pool[i]
	})

	count := cfg.QuestionsPerStudent
	if count <= 0 || count > len(pool) {
		count = len(pool)
	}
	selected := pool[:count]

	clientQs := make([]ClientQuestion, 0, count)
	mapping := make(map[int][]int)
	maxScore := 0

	for _, q := range selected {
		maxScore += q.Points
		cq := ClientQuestion{
			ID:     q.ID,
			Type:   q.Type,
			Text:   q.Text,
			Points: q.Points,
		}

		// Если есть варианты ответов — перемешиваем их индивидуально
		if len(q.Options) > 0 {
			perm := rng.Perm(len(q.Options)) // perm[newIdx] = origIdx
			shuffledOpts := make([]string, len(q.Options))
			for newIdx, origIdx := range perm {
				shuffledOpts[newIdx] = q.Options[origIdx]
			}
			cq.Options = shuffledOpts
			mapping[q.ID] = perm
		}
		clientQs = append(clientQs, cq)
	}

	return clientQs, mapping, maxScore
}

// Нормализация текстового ответа: регистр, ё→е, лишние пробелы
func normalizeAnswer(s string) string {
	s = strings.ToLower(strings.TrimSpace(s))
	s = strings.ReplaceAll(s, "ё", "е")
	return strings.Join(strings.Fields(s), " ")
}

// Сравнение ответа студента с допустимыми эталонами
func isTextMatch(userText string, valid []string) bool {
	u := normalizeAnswer(userText)
	if u == "" {
		return false
	}
	for _, v := range valid {
		if u == normalizeAnswer(v) {
			return true
		}
	}
	return false
}

// Подсчет баллов и рекомендуемой оценки
func calculateScore(s *StudentSession) {
	qMap := make(map[int]Question)
	for _, q := range state.Config.Questions {
		qMap[q.ID] = q
	}

	totalScore := 0
	for _, cq := range s.AssignedQs {
		origQ, exists := qMap[cq.ID]
		if !exists {
			continue
		}
		ans, answered := s.Answers[cq.ID]
		if !answered {
			continue
		}

		switch origQ.Type {
		case "single":
			if len(ans.Selected) == 1 && len(origQ.Correct) == 1 {
				shuffledIdx := ans.Selected[0]
				perm := s.OptionMapping[cq.ID]
				if shuffledIdx >= 0 && shuffledIdx < len(perm) {
					origIdx := perm[shuffledIdx]
					if origIdx == origQ.Correct[0] {
						totalScore += origQ.Points
					}
				}
			}
		case "multiple":
			if len(ans.Selected) == len(origQ.Correct) && len(origQ.Correct) > 0 {
				perm := s.OptionMapping[cq.ID]
				origSelected := make([]int, 0, len(ans.Selected))
				for _, shIdx := range ans.Selected {
					if shIdx >= 0 && shIdx < len(perm) {
						origSelected = append(origSelected, perm[shIdx])
					}
				}
				sort.Ints(origSelected)
				correctSorted := make([]int, len(origQ.Correct))
				copy(correctSorted, origQ.Correct)
				sort.Ints(correctSorted)

				match := true
				for i := range origSelected {
					if origSelected[i] != correctSorted[i] {
						match = false
						break
					}
				}
				if match {
					totalScore += origQ.Points
				}
			}
		case "text":
			if isTextMatch(ans.TextAnswer, origQ.CorrectText) {
				totalScore += origQ.Points
			}
		case "essay":
			// Открытый вопрос проверяется преподавателем визуально (или добавляется вручную)
		}
	}

	s.Score = totalScore
	if s.MaxScore > 0 {
		s.Percentage = math.Round((float64(s.Score)/float64(s.MaxScore))*1000) / 10
	} else {
		s.Percentage = 0
	}

	switch {
	case s.Percentage >= 85:
		s.Grade = 5
	case s.Percentage >= 70:
		s.Grade = 4
	case s.Percentage >= 50:
		s.Grade = 3
	default:
		s.Grade = 2
	}
}

// --- ОБРАБОТЧИКИ API КЛИЕНТА ---

func handleInfo(w http.ResponseWriter, r *http.Request) {
	mu.RLock()
	defer mu.RUnlock()
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{
		"title":              state.Config.Title,
		"time_limit_minutes": state.Config.TimeLimitMinutes,
		"questions_count":    state.Config.QuestionsPerStudent,
	})
}

func handleStart(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req struct {
		FullName string `json:"full_name"`
		Group    string `json:"group"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Bad request", http.StatusBadRequest)
		return
	}

	req.FullName = strings.TrimSpace(req.FullName)
	req.Group = strings.TrimSpace(req.Group)
	if req.FullName == "" || req.Group == "" {
		http.Error(w, "ФИО и группа обязательны", http.StatusBadRequest)
		return
	}

	ip := getClientIP(r)
	key := normalizeKey(req.FullName, req.Group, ip)

	mu.Lock()
	defer mu.Unlock()

	now := time.Now()

	// Проверяем существующую сессию с этого IP или ФИО
	for _, existing := range state.Sessions {
		if finishExpiredLocked(existing, now) {
			saveBackupLocked()
		}

		sameIP := existing.IP == ip
		samePerson := strings.EqualFold(existing.FullName, req.FullName) && strings.EqualFold(existing.Group, req.Group)

		// Тот же человек: возобновление (если преподаватель разрешил) или повторный вход заблокирован
		if samePerson {
			if existing.Status == "testing" {
				// Новый токен при возобновлении: прежний клиент (если он ещё открыт) теряет доступ
				existing.Token = newToken()
				existing.LastSeen = now
				saveBackupLocked()
				writeSessionPayload(w, existing, now, true)
				return
			}

			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusForbidden)
			json.NewEncoder(w).Encode(map[string]string{
				"error": fmt.Sprintf("Повторный вход заблокирован (Статус: %s). Обратитесь к преподавателю для разблокировки.", existing.Status),
			})
			return
		}

		// Другой студент на этом компьютере блокирует вход, только пока его попытка активна.
		// Завершённые попытки не мешают следующему студенту сесть за тот же ПК.
		if sameIP && existing.Status == "testing" {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusForbidden)
			json.NewEncoder(w).Encode(map[string]string{
				"error": "За этим компьютером уже идёт тестирование другого студента. Обратитесь к преподавателю.",
			})
			return
		}
	}

	// Создаем новый индивидуальный билет
	qs, mapping, maxScore := generateTicket(state.Config)
	sess := &StudentSession{
		SessionKey:       key,
		FullName:         req.FullName,
		Group:            req.Group,
		IP:               ip,
		Status:           "testing",
		StartedAt:        now,
		Deadline:         now.Add(time.Duration(state.Config.TimeLimitMinutes) * time.Minute),
		RemainingSeconds: state.Config.TimeLimitMinutes * 60,
		Token:            newToken(),
		LastSeen:         now,
		AssignedQs:       qs,
		OptionMapping:    mapping,
		Answers:          make(map[int]StudentAnswer),
		MaxScore:         maxScore,
		Grade:            2,
	}

	state.Sessions[key] = sess
	saveBackupLocked()

	writeSessionPayload(w, sess, now, false)
}

// Ответ на старт/возобновление: билет, сохранённые ответы, токен и серверное оставшееся время
func writeSessionPayload(w http.ResponseWriter, s *StudentSession, now time.Time, resumed bool) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{
		"session_key":       s.SessionKey,
		"session_token":     s.Token,
		"title":             state.Config.Title,
		"remaining_seconds": remainingNow(s, now),
		"questions":         s.AssignedQs,
		"saved_answers":     s.Answers,
		"resumed":           resumed,
	})
}

// Ответ можно сохранить только на вопрос из билета студента
func isAssigned(s *StudentSession, questionID int) bool {
	for _, cq := range s.AssignedQs {
		if cq.ID == questionID {
			return true
		}
	}
	return false
}

func handleProgress(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// remaining_seconds намеренно не принимается: время ведёт только сервер
	var req struct {
		SessionKey   string        `json:"session_key"`
		SessionToken string        `json:"session_token"`
		Answer       StudentAnswer `json:"answer"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Bad request", http.StatusBadRequest)
		return
	}

	mu.Lock()
	defer mu.Unlock()

	sess, exists := state.Sessions[req.SessionKey]
	if !exists || !checkToken(sess, req.SessionToken) {
		w.WriteHeader(http.StatusForbidden)
		return
	}

	now := time.Now()
	sess.LastSeen = now
	if finishExpiredLocked(sess, now) {
		saveBackupLocked()
		w.WriteHeader(http.StatusGone)
		w.Write([]byte(`{"error":"time_expired"}`))
		return
	}
	if sess.Status != "testing" {
		w.WriteHeader(http.StatusConflict)
		w.Write([]byte(`{"error":"not_testing"}`))
		return
	}

	if req.Answer.QuestionID != 0 && isAssigned(sess, req.Answer.QuestionID) {
		sess.Answers[req.Answer.QuestionID] = req.Answer
	}

	calculateScore(sess)
	saveBackupLocked()

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{
		"ok":                true,
		"remaining_seconds": remainingNow(sess, now),
	})
}

// Heartbeat: клиент сообщает, что он жив, и получает серверное оставшееся время
func handleHeartbeat(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req struct {
		SessionKey   string `json:"session_key"`
		SessionToken string `json:"session_token"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Bad request", http.StatusBadRequest)
		return
	}

	mu.Lock()
	defer mu.Unlock()

	sess, exists := state.Sessions[req.SessionKey]
	if !exists || !checkToken(sess, req.SessionToken) {
		w.WriteHeader(http.StatusForbidden)
		return
	}

	now := time.Now()
	sess.LastSeen = now
	if finishExpiredLocked(sess, now) {
		saveBackupLocked()
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{
		"status":            sess.Status,
		"remaining_seconds": remainingNow(sess, now),
	})
}

func handleSubmit(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Клиент может прислать только "submitted" или "blocked"; "timeout" ставит сервер
	var req struct {
		SessionKey   string                `json:"session_key"`
		SessionToken string                `json:"session_token"`
		Status       string                `json:"status"`
		Reason       string                `json:"reason"`
		Answers      map[int]StudentAnswer `json:"answers"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Bad request", http.StatusBadRequest)
		return
	}
	if req.Status != "submitted" && req.Status != "blocked" {
		http.Error(w, "Недопустимый статус", http.StatusBadRequest)
		return
	}

	mu.Lock()
	defer mu.Unlock()

	sess, exists := state.Sessions[req.SessionKey]
	if !exists || !checkToken(sess, req.SessionToken) {
		http.Error(w, "Session not found", http.StatusForbidden)
		return
	}

	now := time.Now()
	sess.LastSeen = now

	// Повторная сдача отклоняется: итог попытки уже зафиксирован
	if sess.Status != "testing" {
		writeResult(w, sess, http.StatusConflict)
		return
	}
	if finishExpiredLocked(sess, now) {
		saveBackupLocked()
		writeResult(w, sess, http.StatusOK)
		return
	}

	// Лимит количества ответов: студент не может прислать больше, чем ему назначено
	if len(req.Answers) > len(sess.AssignedQs) {
		http.Error(w, "Слишком много ответов", http.StatusBadRequest)
		return
	}

	for k, v := range req.Answers {
		if isAssigned(sess, k) {
			v.QuestionID = k
			sess.Answers[k] = v
		}
	}

	sess.RemainingSeconds = remainingNow(sess, now)
	sess.Status = req.Status
	if len(req.Reason) > 200 {
		req.Reason = req.Reason[:200]
	}
	sess.BlockReason = req.Reason
	sess.FinishedAt = &now
	sess.Token = ""

	calculateScore(sess)
	saveBackupLocked()

	writeResult(w, sess, http.StatusOK)
}

// --- ОБРАБОТЧИКИ ПАНЕЛИ ПРЕПОДАВАТЕЛЯ (/admin) ---

type DetailedAnswerView struct {
	QuestionID int    `json:"question_id"`
	Type       string `json:"type"`
	Text       string `json:"text"`
	StudentAns string `json:"student_ans"`
	CorrectAns string `json:"correct_ans"`
	IsCorrect  bool   `json:"is_correct"`
	Points     int    `json:"points"`
}

func handleAdminState(w http.ResponseWriter, r *http.Request) {
	mu.RLock()
	defer mu.RUnlock()

	// Поиск доступных файлов questions*.json в папке сервера
	files, _ := filepath.Glob("*.json")
	var qFiles []string
	for _, f := range files {
		if f != backupFile {
			qFiles = append(qFiles, f)
		}
	}

	qMap := make(map[int]Question)
	for _, q := range state.Config.Questions {
		qMap[q.ID] = q
	}

	type SessionView struct {
		*StudentSession
		AnsweredCount int                  `json:"answered_count"`
		TotalCount    int                  `json:"total_count"`
		LinkLost      bool                 `json:"link_lost"` // Нет heartbeat дольше порога; только для информации, не нарушение
		Details       []DetailedAnswerView `json:"details"`
	}

	now := time.Now()
	views := make([]SessionView, 0, len(state.Sessions))
	for _, src := range state.Sessions {
		// Копия без секрета сессии: токен не должен попадать в панель преподавателя
		cp := *src
		cp.Token = ""
		cp.RemainingSeconds = remainingNow(src, now)
		s := &cp

		answered := 0
		details := make([]DetailedAnswerView, 0, len(s.AssignedQs))

		for _, cq := range s.AssignedQs {
			origQ := qMap[cq.ID]
			ans, has := s.Answers[cq.ID]
			isNonEmpty := has && (len(ans.Selected) > 0 || strings.TrimSpace(ans.TextAnswer) != "")
			if isNonEmpty {
				answered++
			}

			// Формируем читаемый вид ответа студента и правильного ответа
			stuStr := "— нет ответа —"
			corrStr := ""
			isCorr := false

			switch origQ.Type {
			case "single", "multiple":
				var sOpts []string
				for _, idx := range ans.Selected {
					if idx >= 0 && idx < len(cq.Options) {
						sOpts = append(sOpts, cq.Options[idx])
					}
				}
				if len(sOpts) > 0 {
					stuStr = strings.Join(sOpts, "; ")
				}
				var cOpts []string
				for _, cIdx := range origQ.Correct {
					if cIdx >= 0 && cIdx < len(origQ.Options) {
						cOpts = append(cOpts, origQ.Options[cIdx])
					}
				}
				corrStr = strings.Join(cOpts, "; ")
				// Сравниваем множества оригинальных индексов, а не строки: порядок вариантов
				// у студента перемешан, тексты вариантов могут совпадать
				if len(ans.Selected) > 0 {
					perm := s.OptionMapping[cq.ID]
					selSet := make(map[int]bool, len(ans.Selected))
					for _, shIdx := range ans.Selected {
						if shIdx >= 0 && shIdx < len(perm) {
							selSet[perm[shIdx]] = true
						}
					}
					corSet := make(map[int]bool, len(origQ.Correct))
					for _, cIdx := range origQ.Correct {
						corSet[cIdx] = true
					}
					isCorr = len(selSet) > 0 && len(selSet) == len(corSet)
					for idx := range selSet {
						if !corSet[idx] {
							isCorr = false
							break
						}
					}
				}

			case "text":
				if strings.TrimSpace(ans.TextAnswer) != "" {
					stuStr = ans.TextAnswer
				}
				corrStr = strings.Join(origQ.CorrectText, " / ")
				isCorr = isTextMatch(ans.TextAnswer, origQ.CorrectText)
			case "essay":
				// Эссе не автоматическая проверка: верным его не помечаем, выводим как «на проверке»
				if strings.TrimSpace(ans.TextAnswer) != "" {
					stuStr = ans.TextAnswer
				}
				corrStr = "[Развернутый ответ — проверка преподавателем]"
			}

			details = append(details, DetailedAnswerView{
				QuestionID: cq.ID,
				Type:       origQ.Type,
				Text:       origQ.Text,
				StudentAns: stuStr,
				CorrectAns: corrStr,
				IsCorrect:  isCorr,
				Points:     origQ.Points,
			})
		}

		views = append(views, SessionView{
			StudentSession: s,
			AnsweredCount:  answered,
			TotalCount:     len(s.AssignedQs),
			LinkLost:       s.Status == "testing" && now.Sub(s.LastSeen) > heartbeatLostAfter,
			Details:        details,
		})
	}

	sort.Slice(views, func(i, j int) bool {
		return views[i].FullName < views[j].FullName
	})

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{
		"current_file":          state.CurrentFile,
		"available_files":       qFiles,
		"title":                 state.Config.Title,
		"time_limit_minutes":    state.Config.TimeLimitMinutes,
		"questions_per_student": state.Config.QuestionsPerStudent,
		"total_questions_bank":  len(state.Config.Questions),
		"sessions":              views,
	})
}

func handleAdminAction(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	var req struct {
		SessionKey  string `json:"session_key"`
		Action      string `json:"action"` // "soft_reset", "hard_reset", "add_essay_points"
		BonusPoints int    `json:"bonus_points,omitempty"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Bad request", http.StatusBadRequest)
		return
	}

	mu.Lock()
	defer mu.Unlock()

	if req.Action == "clear_all" {
		state.Sessions = make(map[string]*StudentSession)
		saveBackupLocked()
		w.Write([]byte(`{"ok":true}`))
		return
	}

	sess, exists := state.Sessions[req.SessionKey]
	if !exists {
		http.Error(w, "Not found", http.StatusNotFound)
		return
	}

	switch req.Action {
	case "soft_reset":
		// Разблокировка с сохранением ответов и оставшегося времени.
		// Токен сбрасывается: студент получит новый при повторном входе.
		if sess.RemainingSeconds <= 60 {
			sess.RemainingSeconds += 180 // Добавляем 3 минуты, если время почти кончилось
		}
		sess.Status = "testing"
		sess.BlockReason = ""
		sess.FinishedAt = nil
		sess.Token = ""
		sess.Deadline = time.Now().Add(time.Duration(sess.RemainingSeconds) * time.Second)
	case "finish":
		// Досрочное завершение активной попытки преподавателем: освобождает компьютер
		if sess.Status == "testing" {
			now := time.Now()
			sess.RemainingSeconds = remainingNow(sess, now)
			sess.Status = "submitted"
			sess.BlockReason = "Завершено преподавателем"
			sess.FinishedAt = &now
			sess.Token = ""
			calculateScore(sess)
		}
	case "hard_reset":
		// Полное удаление попытки — студент сможет войти заново и получить новый билет
		delete(state.Sessions, req.SessionKey)
	}

	saveBackupLocked()
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(`{"ok":true}`))
}

func handleAdminConfig(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	var req struct {
		File                string `json:"file"`
		TimeLimitMinutes    int    `json:"time_limit_minutes"`
		QuestionsPerStudent int    `json:"questions_per_student"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Bad request", http.StatusBadRequest)
		return
	}

	mu.Lock()
	defer mu.Unlock()

	if req.File != "" && req.File != state.CurrentFile {
		// Смена банка во время экзамена изменит вопросы у уже идущих попыток
		for _, s := range state.Sessions {
			if s.Status == "testing" {
				http.Error(w, "Нельзя сменить банк вопросов: есть активные попытки", http.StatusConflict)
				return
			}
		}
		name, err := safeBankFileName(req.File)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		if err := loadQuestions(name); err != nil {
			http.Error(w, "Не удалось загрузить банк: "+err.Error(), http.StatusBadRequest)
			return
		}
	}
	if req.TimeLimitMinutes > 0 {
		state.Config.TimeLimitMinutes = req.TimeLimitMinutes
	}
	if req.QuestionsPerStudent > 0 {
		state.Config.QuestionsPerStudent = req.QuestionsPerStudent
	}

	saveBackupLocked()

	w.WriteHeader(http.StatusOK)
	w.Write([]byte(`{"ok":true}`))
}

func handleAdminExport(w http.ResponseWriter, r *http.Request) {
	mu.RLock()
	defer mu.RUnlock()

	w.Header().Set("Content-Type", "text/csv; charset=utf-8")
	w.Header().Set("Content-Disposition", `attachment; filename="results.csv"`)

	// UTF-8 BOM для корректного открытия кириллицы в MS Excel
	w.Write([]byte("\xEF\xBB\xBF"))

	writer := csv.NewWriter(w)
	writer.Comma = ';'

	_ = writer.Write([]string{
		"ФИО Студента", "Группа", "IP-адрес", "Статус", "Причина блокировки",
		"Отвечено вопросов", "Набранный балл", "Макс. балл", "Процент (%)", "Оценка", "Время сдачи",
	})

	for _, s := range state.Sessions {
		finTime := "-"
		if s.FinishedAt != nil {
			finTime = s.FinishedAt.Format("2006-01-02 15:04:05")
		}
		_ = writer.Write([]string{
			s.FullName,
			s.Group,
			s.IP,
			s.Status,
			s.BlockReason,
			fmt.Sprintf("%d из %d", len(s.Answers), len(s.AssignedQs)),
			fmt.Sprintf("%d", s.Score),
			fmt.Sprintf("%d", s.MaxScore),
			fmt.Sprintf("%.1f", s.Percentage),
			fmt.Sprintf("%d", s.Grade),
			finTime,
		})
	}
	writer.Flush()
}

func handleAdminPage(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.Write([]byte(adminHTML))
}

const adminHTML = `<!DOCTYPE html>
<html lang="ru">
<head>
<meta charset="UTF-8">
<title>ExamTheory-Local — Панель преподавателя</title>
<style>
  body { font-family: 'Segoe UI', Tahoma, sans-serif; background: #f3f4f6; margin: 0; padding: 20px; color: #1f2937; }
  .header { background: #fff; padding: 18px 24px; border-radius: 10px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; flex-wrap: wrap; gap: 15px; }
  h1 { margin: 0; font-size: 20px; color: #111827; }
  .controls { display: flex; gap: 10px; align-items: center; flex-wrap: wrap; }
  input, select, button { padding: 8px 12px; border: 1px solid #d1d5db; border-radius: 6px; font-size: 14px; }
  button { cursor: pointer; background: #2563eb; color: #fff; border: none; font-weight: 500; }
  button:hover { background: #1d4ed8; }
  .btn-green { background: #059669; } .btn-green:hover { background: #047857; }
  .btn-amber { background: #d97706; } .btn-amber:hover { background: #b45309; }
  .btn-red { background: #dc2626; } .btn-red:hover { background: #b91c1c; }
  table { width: 100%; border-collapse: collapse; background: #fff; border-radius: 10px; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
  th, td { padding: 12px 15px; text-align: left; border-bottom: 1px solid #e5e7eb; font-size: 14px; }
  th { background: #f9fafb; font-weight: 600; color: #374151; }
  .badge { padding: 4px 8px; border-radius: 9999px; font-size: 12px; font-weight: 600; display: inline-block; }
  .st-testing { background: #dbeafe; color: #1e40af; }
  .st-submitted { background: #d1fae5; color: #065f46; }
  .st-blocked { background: #fee2e2; color: #991b1b; }
  .st-timeout { background: #fef3c7; color: #92400e; }
  .details-row { background: #f8fafc; display: none; }
  .q-card { padding: 8px 12px; border-left: 4px solid #cbd5e1; margin-bottom: 8px; background: #fff; border-radius: 4px; }
  .q-ok { border-left-color: #10b981; }
  .q-err { border-left-color: #ef4444; }
  .q-review { border-left-color: #f59e0b; }
</style>
</head>
<body>

<div class="header">
  <div>
    <h1 id="examTitle">Загрузка...</h1>
    <small id="bankInfo" style="color:#6b7280;"></small>
  </div>
  <div class="controls">
    <label>Файл: <select id="fileSelect"></select></label>
    <label>Вопросов: <input type="number" id="qCount" style="width:60px;"></label>
    <label>Минут: <input type="number" id="tLimit" style="width:60px;"></label>
    <button onclick="applyConfig()">Применить</button>
    <button class="btn-green" onclick="window.location.href='/api/admin/export'">📥 Экспорт в CSV (Excel)</button>
  </div>
</div>

<table>
  <thead>
    <tr>
      <th>ФИО и Группа</th>
      <th>IP-адрес</th>
      <th>Статус</th>
      <th>Прогресс</th>
      <th>Осталось</th>
      <th>Балл / %</th>
      <th>Оценка</th>
      <th>Управление попыткой</th>
    </tr>
  </thead>
  <tbody id="studentsBody"></tbody>
</table>

<script>
let openDetails = {};
let configInitialized = false;

function esc(value) {
  return String(value == null ? '' : value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

async function fetchState() {
  try {
    const res = await fetch('/api/admin/state');
    const data = await res.json();

    document.getElementById('examTitle').innerText = data.title || 'Экзамен';
    document.getElementById('bankInfo').innerText = 'Всего вопросов в базе: ' + data.total_questions_bank;

    if (!configInitialized) {
      const sel = document.getElementById('fileSelect');
      sel.innerHTML = '';
      (data.available_files || []).forEach(f => {
        const opt = document.createElement('option');
        opt.value = f; opt.innerText = f;
        if (f === data.current_file) opt.selected = true;
        sel.appendChild(opt);
      });
      document.getElementById('qCount').value = data.questions_per_student;
      document.getElementById('tLimit').value = data.time_limit_minutes;
      configInitialized = true;
    }

    const tbody = document.getElementById('studentsBody');
    tbody.innerHTML = '';

    (data.sessions || []).forEach(s => {
      const tr = document.createElement('tr');
      let stBadge = '';
      if (s.status === 'testing') stBadge = '<span class="badge st-testing">Тестируется</span>';
      else if (s.status === 'submitted') stBadge = '<span class="badge st-submitted">Сдано</span>';
      else if (s.status === 'timeout') stBadge = '<span class="badge st-timeout">Время вышло</span>';
      else stBadge = '<span class="badge st-blocked">Заблокирован (' + esc(s.block_reason || 'Анти-чит') + ')</span>';

      const mins = Math.floor(s.remaining_seconds / 60);
      const secs = s.remaining_seconds % 60;
      const timeStr = mins + ':' + (secs < 10 ? '0' : '') + secs;
      const key = esc(s.session_key);
      const linkBadge = s.link_lost ? ' <span class="badge st-blocked" title="Нет heartbeat дольше 30 с. Нарушением не считается">Нет связи</span>' : '';

      tr.innerHTML =
        '<td><b>' + esc(s.full_name) + '</b>' + linkBadge + '<br><small style="color:#6b7280">' + esc(s.group) + '</small></td>' +
        '<td><code>' + esc(s.ip) + '</code></td>' +
        '<td>' + stBadge + '</td>' +
        '<td>' + s.answered_count + ' / ' + s.total_count + '</td>' +
        '<td>' + timeStr + '</td>' +
        '<td><b>' + s.score + '</b> из ' + s.max_score + ' (' + s.percentage + '%)</td>' +
        '<td style="font-size:18px;font-weight:bold;">' + s.grade + '</td>' +
        '<td>' +
          '<button data-act="details" data-key="' + key + '" style="background:#4b5563;margin-right:6px;">Ответы</button>' +
          (s.status === 'testing' ? '<button data-act="finish" data-key="' + key + '" style="background:#059669;margin-right:6px;" title="Завершить попытку досрочно и освободить компьютер">Завершить</button>' : '') +
          '<button class="btn-amber" data-act="soft_reset" data-key="' + key + '" style="margin-right:6px;" title="Разблокировать с сохранением ответов">Продолжить</button>' +
          '<button class="btn-red" data-act="hard_reset" data-key="' + key + '" title="Аннулировать и выдать новый билет">Полный сброс</button>' +
        '</td>';
      tbody.appendChild(tr);

      const dTr = document.createElement('tr');
      dTr.id = 'det-' + s.session_key;
      dTr.className = 'details-row';
      dTr.style.display = openDetails[s.session_key] ? 'table-row' : 'none';

      let dHtml = '<td colspan="8"><b>Детализация ответов студента:</b><div style="margin-top:10px;">';
      (s.details || []).forEach((d, idx) => {
        const cls = d.type === 'essay' ? 'q-review' : (d.is_correct ? 'q-ok' : 'q-err');
        dHtml += '<div class="q-card ' + cls + '">' +
          '<div><b>' + (idx+1) + '. ' + esc(d.text) + '</b> (' + d.points + ' б.)</div>' +
          '<div style="margin-top:4px;">Ответ студента: <b>' + esc(d.student_ans) + '</b></div>' +
          '<div style="color:#6b7280;font-size:12px;">Эталон: ' + esc(d.correct_ans) + '</div>' +
        '</div>';
      });
      dHtml += '</div></td>';
      dTr.innerHTML = dHtml;
      tbody.appendChild(dTr);
    });
  } catch (e) {
    console.error(e);
  }
}

// Делегирование кликов: ключ сессии берётся из data-атрибута, а не из JS-строки
document.getElementById('studentsBody').addEventListener('click', (ev) => {
  const btn = ev.target.closest('button[data-act]');
  if (!btn) return;
  const key = btn.dataset.key;
  if (btn.dataset.act === 'details') toggleDetails(key);
  else doAction(key, btn.dataset.act);
});

function toggleDetails(key) {
  openDetails[key] = !openDetails[key];
  const el = document.getElementById('det-' + key);
  if (el) el.style.display = openDetails[key] ? 'table-row' : 'none';
}

async function doAction(key, action) {
  if (action === 'hard_reset' && !confirm('Вы уверены? Попытка будет полностью удалена!')) return;
  if (action === 'finish' && !confirm('Завершить попытку досрочно? Ответы будут засчитаны как есть.')) return;
  const resp = await fetch('/api/admin/action', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({session_key: key, action: action})
  });
  if (!resp.ok) alert('Действие не выполнено: ' + (await resp.text()).trim());
  fetchState();
}

async function applyConfig() {
  const file = document.getElementById('fileSelect').value;
  const qCount = parseInt(document.getElementById('qCount').value, 10);
  const tLimit = parseInt(document.getElementById('tLimit').value, 10);
  const resp = await fetch('/api/admin/config', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({file: file, questions_per_student: qCount, time_limit_minutes: tLimit})
  });
  if (!resp.ok) {
    alert('Не применено: ' + (await resp.text()).trim());
    return;
  }
  configInitialized = false;
  fetchState();
  alert('Настройки экзамена обновлены!');
}

setInterval(fetchState, 2000);
fetchState();
</script>
</body>
</html>`
