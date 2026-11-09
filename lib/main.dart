import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1024, 768),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'ExamTheory-Local — Клиент тестирования',
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const ExamClientApp());
}

/// Фильтр защиты от вставки из буфера обмена или автотайпера:
/// блокирует разовое добавление более 2 символов за один такт ввода.
class AntiPasteFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final int addedChars = newValue.text.length - oldValue.text.length;
    if (addedChars > 2) {
      return oldValue;
    }
    return newValue;
  }
}

class ExamClientApp extends StatelessWidget {
  const ExamClientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ExamTheory-Local',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E40AF)),
        useMaterial3: true,
      ),
      home: const ExamHomeScreen(),
    );
  }
}

class ExamHomeScreen extends StatefulWidget {
  const ExamHomeScreen({super.key});

  @override
  State<ExamHomeScreen> createState() => _ExamHomeScreenState();
}

class _ExamHomeScreenState extends State<ExamHomeScreen> with WindowListener {
  // Состояние экрана: "login", "exam", "result"
  String _screenState = 'login';
  String _serverUrl = 'http://10.164.203.35:8080';

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _groupCtrl = TextEditingController();
  final TextEditingController _textAnswerCtrl = TextEditingController();

  String _examTitle = 'Загрузка параметров экзамена...';
  String _sessionKey = '';
  String _sessionToken = '';
  int _remainingSeconds = 0;
  Timer? _countdownTimer;
  Timer? _heartbeatTimer;
  Timer? _retryTimer;
  bool _linkLost = false;
  // true, если часть ответов не дошла до сервера и должна быть досылана при восстановлении связи
  bool _hasUnsynced = false;

  List<dynamic> _questions = [];
  int _currentIndex = 0;

  // Локальное хранилище ответов: question_id -> {selected: List<int>, text_answer: String, flagged: bool}
  final Map<int, Map<String, dynamic>> _answers = {};

  bool _antiCheatActive = false;
  bool _isSubmitting = false;

  // Итоговые данные после завершения
  String _finalStatus = '';
  String _finalReason = '';
  int _finalScore = 0;
  int _finalMaxScore = 0;
  double _finalPercentage = 0.0;
  int _finalGrade = 2;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _initServerAddress();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _countdownTimer?.cancel();
    _heartbeatTimer?.cancel();
    _retryTimer?.cancel();
    _nameCtrl.dispose();
    _groupCtrl.dispose();
    _textAnswerCtrl.dispose();
    super.dispose();
  }

  Future<void> _initServerAddress() async {
    // 1. Проверяем --dart-define=SERVER_URL
    const definedUrl = String.fromEnvironment('SERVER_URL', defaultValue: '');
    if (definedUrl.isNotEmpty) {
      _serverUrl = definedUrl;
    } else {
      // 2. Ищем локальный файл server_ip.txt рядом с client.exe
      try {
        final file = File('server_ip.txt');
        if (await file.exists()) {
          final content = (await file.readAsString()).trim();
          if (content.isNotEmpty) {
            _serverUrl = content.startsWith('http') ? content : 'http://$content:8080';
          }
        }
      } catch (_) {}
    }
    _fetchExamInfo();
  }

  Future<void> _fetchExamInfo() async {
    try {
      final res = await http
          .get(Uri.parse('$_serverUrl/api/info'))
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        setState(() {
          _examTitle = data['title'] ?? 'Теоретический экзамен';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _examTitle = 'Не удалось подключиться к серверу ($_serverUrl)';
      });
    }
  }

  // --- СОБЫТИЯ АНТИ-ЧИТА (WINDOW_MANAGER) ---

  @override
  void onWindowBlur() {
    if (_antiCheatActive && !_isSubmitting) {
      _triggerAntiCheatViolation('АВТО-ЗАВЕРШЕНИЕ: Потеря фокуса окна (Alt+Tab / Win / Второй монитор)');
    }
  }

  @override
  void onWindowMinimize() {
    if (_antiCheatActive && !_isSubmitting) {
      _triggerAntiCheatViolation('АВТО-ЗАВЕРШЕНИЕ: Попытка свернуть окно');
    }
  }

  @override
  void onWindowClose() async {
    if (_antiCheatActive && !_isSubmitting) {
      await _triggerAntiCheatViolation('АВТО-ЗАВЕРШЕНИЕ: Попытка закрытия окна (Alt+F4)');
    }
    await windowManager.destroy();
  }

  Future<void> _enableExamLockdown() async {
    // Очищаем системный буфер обмена при старте теста
    await Clipboard.setData(const ClipboardData(text: ''));

    await windowManager.setPreventClose(true);
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    await windowManager.setFullScreen(true);
    await windowManager.setAlwaysOnTop(true);
    await windowManager.focus();

    // Даем ОС Windows 600 мс на переключение видеорежима, затем взводим триггер анти-чита
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && _screenState == 'exam') {
        _antiCheatActive = true;
      }
    });
  }

  Future<void> _disableExamLockdown() async {
    _antiCheatActive = false;
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setFullScreen(false);
    await windowManager.setTitleBarStyle(TitleBarStyle.normal);
    await windowManager.setPreventClose(false);
  }

  Future<void> _triggerAntiCheatViolation(String reason) async {
    if (_isSubmitting) return;
    await _submitExam(status: 'blocked', reason: reason);
  }

  // --- ЛОГИКА ЭКЗАМЕНА И СИНХРОНИЗАЦИИ ---

  Future<void> _startExam() async {
    final name = _nameCtrl.text.trim();
    final group = _groupCtrl.text.trim();
    if (name.isEmpty || group.isEmpty) {
      _showSnack('Введите ФИО и номер учебной группы!');
      return;
    }

    try {
      final res = await http.post(
        Uri.parse('$_serverUrl/api/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'full_name': name, 'group': group}),
      );

      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (res.statusCode == 403) {
        _showSnack(data['error'] ?? 'Доступ запрещен сервером');
        return;
      }
      if (res.statusCode != 200) {
        _showSnack('Ошибка старта: ${res.body}');
        return;
      }

      _sessionKey = data['session_key'];
      _sessionToken = data['session_token'] ?? '';
      _linkLost = false;
      _hasUnsynced = false;
      _examTitle = data['title'] ?? _examTitle;
      _remainingSeconds = data['remaining_seconds'] ?? 1500;
      _questions = data['questions'] ?? [];
      _answers.clear();

      // Если это разблокированная преподавателем сессия (Soft Reset) — восстанавливаем ответы
      final saved = data['saved_answers'] as Map<String, dynamic>?;
      if (saved != null) {
        saved.forEach((k, v) {
          final qId = int.tryParse(k);
          if (qId != null && v is Map<String, dynamic>) {
            _answers[qId] = {
              'question_id': qId,
              'selected': List<int>.from(v['selected'] ?? []),
              'text_answer': (v['text_answer'] ?? '').toString(),
              'flagged': v['flagged'] == true,
            };
          }
        });
      }

      _currentIndex = 0;
      _syncTextControllerWithQuestion();

      setState(() {
        _screenState = 'exam';
      });

      await _enableExamLockdown();
      _startTimer();
      _startHeartbeat();
    } catch (e) {
      _showSnack('Ошибка соединения с сервером: $e');
    }
  }

  // Локальный таймер только для отображения; окончательное время ведёт сервер
  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _submitExam(status: 'submitted', reason: 'Время вышло');
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  // Heartbeat раз в 10 секунд: сверяет время с сервером и фиксирует потерю связи
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) => _sendHeartbeat());
  }

  Future<void> _sendHeartbeat() async {
    if (_sessionKey.isEmpty || _sessionToken.isEmpty || _isSubmitting) return;
    try {
      final res = await http
          .post(
            Uri.parse('$_serverUrl/api/heartbeat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'session_key': _sessionKey, 'session_token': _sessionToken}),
          )
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        if (mounted) {
          setState(() {
            _linkLost = false;
            _remainingSeconds = data['remaining_seconds'] ?? _remainingSeconds;
          });
        }
        // Связь восстановилась: досылаем ответы, которые не ушли во время сбоя
        if (_hasUnsynced) {
          _flushAnswers();
        }
        // Сервер уже завершил попытку (например, по времени) — фиксируем итог
        if (data['status'] != 'testing') {
          _submitExam(status: 'submitted');
        }
      } else if (res.statusCode == 403) {
        // Сессия удалена или перевыпущена преподавателем: токен больше не действует
        _handleSessionLost();
      }
    } catch (_) {
      if (mounted) setState(() => _linkLost = true);
    }
  }

  // Сессия недействительна (перевыпущена или удалена преподавателем): выходим на экран входа
  Future<void> _handleSessionLost() async {
    if (_isSubmitting || _screenState != 'exam') return;
    _countdownTimer?.cancel();
    _heartbeatTimer?.cancel();
    _retryTimer?.cancel();
    _sessionKey = '';
    _sessionToken = '';
    _hasUnsynced = false;
    if (mounted) {
      setState(() {
        _screenState = 'login';
        _linkLost = false;
      });
    }
    _showSnack('Сессия закрыта преподавателем. Войдите заново.');
    await _disableExamLockdown();
  }

  void _syncTextControllerWithQuestion() {
    if (_questions.isEmpty) return;
    final q = _questions[_currentIndex];
    final int qId = q['id'];
    final existing = _answers[qId];
    _textAnswerCtrl.text = existing != null ? (existing['text_answer'] ?? '') : '';
  }

  Map<String, dynamic> _newAnswer(int qId) => {
        'question_id': qId,
        'selected': <int>[],
        'text_answer': '',
        'flagged': false,
      };

  // Запись ответа создаётся только при действии студента
  Map<String, dynamic> _ensureAnswer(int qId) {
    return _answers.putIfAbsent(qId, () => _newAnswer(qId));
  }

  // Для отрисовки: не сохраняет пустой ответ в _answers (build не меняет состояние)
  Map<String, dynamic> _answerOrEmpty(int qId) => _answers[qId] ?? _newAnswer(qId);

  // Единое правило «вопрос отвечен» для навигации, диалога сдачи и проверок
  bool _isAnswered(Map<String, dynamic>? ans) {
    if (ans == null) return false;
    return (ans['selected'] as List).isNotEmpty ||
        (ans['text_answer'] as String).trim().isNotEmpty;
  }

  Future<void> _sendProgress(int qId) async {
    final ans = _answers[qId];
    if (ans == null || _sessionKey.isEmpty) return;
    await _postAnswer(ans);
  }

  // Возвращает true, если сервер подтвердил сохранение ответа
  Future<bool> _postAnswer(Map<String, dynamic> ans) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_serverUrl/api/progress'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'session_key': _sessionKey,
              'session_token': _sessionToken,
              'answer': ans,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        if (_linkLost && mounted) setState(() => _linkLost = false);
        return true;
      }
      if (res.statusCode == 403) {
        _handleSessionLost();
      } else if (res.statusCode == 409 || res.statusCode == 410) {
        // Попытка уже завершена на сервере (время вышло или преподаватель завершил)
        _submitExam(status: 'submitted');
      } else {
        _hasUnsynced = true;
      }
      return false;
    } catch (_) {
      // Ответ сохранён локально; будет досыл при восстановлении связи
      _hasUnsynced = true;
      if (mounted) setState(() => _linkLost = true);
      return false;
    }
  }

  // Досылает все локальные ответы; останавливается при первом сбое
  Future<void> _flushAnswers() async {
    _hasUnsynced = false;
    for (final ans in _answers.values.toList()) {
      if (!await _postAnswer(ans)) break;
    }
  }

  void _switchQuestion(int newIndex) {
    if (_questions.isEmpty) return;
    final currentQ = _questions[_currentIndex];
    _sendProgress(currentQ['id']);

    setState(() {
      _currentIndex = newIndex;
      _syncTextControllerWithQuestion();
    });
  }

  Future<void> _submitExam({required String status, String reason = ''}) async {
    if (_isSubmitting) return;
    _isSubmitting = true;
    _countdownTimer?.cancel();
    _heartbeatTimer?.cancel();
    _retryTimer?.cancel();

    // Преобразуем ключи в строки для JSON
    final Map<String, dynamic> serializedAnswers = {};
    _answers.forEach((k, v) {
      serializedAnswers[k.toString()] = v;
    });

    try {
      final res = await http
          .post(
            Uri.parse('$_serverUrl/api/submit'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'session_key': _sessionKey,
              'session_token': _sessionToken,
              'status': status,
              'reason': reason,
              'answers': serializedAnswers,
            }),
          )
          .timeout(const Duration(seconds: 10));

      // 200 — попытка завершена сейчас; 409 — уже завершена ранее, сервер вернул итог
      if (res.statusCode == 200 || res.statusCode == 409) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        _finalScore = data['score'] ?? 0;
        _finalMaxScore = data['max_score'] ?? 0;
        _finalPercentage = (data['percentage'] ?? 0).toDouble();
        _finalGrade = data['grade'] ?? 2;
        _finishWithResult(
          data['status'] ?? status,
          data['reason'] ?? reason,
        );
        return;
      }
      if (res.statusCode == 403) {
        // Сессия больше не действительна — сдать с этого токена нельзя
        _isSubmitting = false;
        _handleSessionLost();
        return;
      }
      _scheduleSubmitRetry(status, reason);
    } catch (_) {
      // Нет связи: итог не получен от сервера, результат не показываем, повторяем отправку
      _scheduleSubmitRetry(status, reason);
    }
  }

  // Показываем результат только после подтверждения сервера
  Future<void> _finishWithResult(String status, String reason) async {
    _retryTimer?.cancel();
    await _disableExamLockdown();
    if (mounted) {
      setState(() {
        _finalStatus = status;
        _finalReason = reason;
        _screenState = 'result';
        _isSubmitting = false;
        _linkLost = false;
      });
    }
  }

  void _scheduleSubmitRetry(String status, String reason) {
    _isSubmitting = false;
    if (mounted) setState(() => _linkLost = true);
    _showSnack('Нет связи с сервером. Работа не отправлена, повторная попытка...');
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 5), () {
      if (_screenState == 'exam') {
        _submitExam(status: status, reason: reason);
      }
    });
  }

  void _confirmAndSubmit() {
    // Считаем неотвеченные вопросы
    int unanswered = 0;
    for (final q in _questions) {
      if (!_isAnswered(_answers[q['id']])) unanswered++;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Завершить тестирование?'),
        content: Text(
          unanswered > 0
              ? 'Внимание! У вас осталось неотвеченных вопросов: $unanswered.\nВы действительно хотите сдать тест?'
              : 'Вы ответили на все вопросы билета. Отправить работу на проверку?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Вернуться к тесту'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _submitExam(status: 'submitted');
            },
            child: const Text('Да, завершить и сдать'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _formatTimer(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // --- ЭКРАНЫ ИНТЕРФЕЙСА ---

  @override
  Widget build(BuildContext context) {
    // Блокируем горячие клавиши копирования и вставки на уровне всего дерева виджетов
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyC, control: true): () {},
        const SingleActivator(LogicalKeyboardKey.keyV, control: true): () {},
        const SingleActivator(LogicalKeyboardKey.insert, shift: true): () {},
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_screenState) {
      case 'exam':
        return _buildExamScreen();
      case 'result':
        return _buildResultScreen();
      default:
        return _buildLoginScreen();
    }
  }

  Widget _buildLoginScreen() {
    return Center(
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 16)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.shield_outlined, size: 54, color: Color(0xFF1E40AF)),
            const SizedBox(height: 12),
            Text(
              _examTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'ФИО студента (полностью)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _groupCtrl,
              decoration: const InputDecoration(
                labelText: 'Номер учебной группы (например, П-21)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.group_outlined),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ Правила системы Анти-чит:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '• После нажатия кнопки «Начать тест» окно перейдет в полноэкранный режим.\n'
                        '• Любая попытка переключить окно (Alt+Tab, клавиша Win, клик на второй монитор или уведомление) мгновенно завершает попытку и блокирует тест.\n'
                        '• Буфер обмена и вставка текста (Ctrl+V) заблокированы.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF7F1D1D)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _startExam,
              icon: const Icon(Icons.play_arrow),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Начать тест', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamScreen() {
    if (_questions.isEmpty) {
      return const Center(child: Text('Нет доступных вопросов в билете'));
    }

    final q = _questions[_currentIndex];
    final int qId = q['id'];
    final String qType = q['type'];
    final ans = _answerOrEmpty(qId);
    final List<int> selected = ans['selected'] as List<int>;
    final bool isFlagged = ans['flagged'] == true;

    return Column(
      children: [
        // ВЕРХНЯЯ ПАНЕЛЬ
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          color: const Color(0xFF1E3A8A),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Студент: ${_nameCtrl.text} (${_groupCtrl.text})',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                'Вопрос ${_currentIndex + 1} из ${_questions.length}',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _remainingSeconds < 120 ? Colors.red.shade700 : Colors.white24,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: Colors.white, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      _formatTimer(_remainingSeconds),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_linkLost) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.wifi_off, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      const Text(
                        'Нет связи',
                        style: TextStyle(color: Colors.amber, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // ОСНОВНАЯ РАБОЧАЯ ОБЛАСТЬ
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Левая панель: навигационная сетка вопросов
              Container(
                width: 260,
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Навигация по билету',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemCount: _questions.length,
                        itemBuilder: (ctx, idx) {
                          final itemQ = _questions[idx];
                          final itemAns = _answers[itemQ['id']];
                          final bool hasAnswered = _isAnswered(itemAns);
                          final bool itemFlagged = itemAns != null && itemAns['flagged'] == true;
                          final bool isCurrent = idx == _currentIndex;

                          Color bgColor = Colors.grey.shade200;
                          Color txtColor = Colors.black87;
                          if (isCurrent) {
                            bgColor = const Color(0xFF2563EB);
                            txtColor = Colors.white;
                          } else if (itemFlagged) {
                            bgColor = Colors.amber.shade400;
                          } else if (hasAnswered) {
                            bgColor = Colors.green.shade100;
                            txtColor = Colors.green.shade900;
                          }

                          return InkWell(
                            onTap: () => _switchQuestion(idx),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(8),
                                border: isCurrent
                                    ? Border.all(color: Colors.black, width: 2)
                                    : null,
                              ),
                              child: Text(
                                '${idx + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: txtColor,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    FilledButton.tonalIcon(
                      onPressed: _confirmAndSubmit,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Завершить и сдать тест'),
                      ),
                    ),
                  ],
                ),
              ),

              // Правая область: текст вопроса и варианты ответа
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Chip(
                              label: Text('Баллов за вопрос: ${q['points']}'),
                              backgroundColor: Colors.blue.shade50,
                            ),
                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _ensureAnswer(qId)['flagged'] = !isFlagged;
                                });
                                _sendProgress(qId);
                              },
                              icon: Icon(
                                isFlagged ? Icons.flag : Icons.outlined_flag,
                                color: isFlagged ? Colors.amber.shade800 : null,
                              ),
                              label: Text(isFlagged ? 'Отмечен «Вернуться позже»' : 'Вернуться позже'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Текст вопроса защищен от выделения (обычный Text без SelectionArea)
                        Text(
                          q['text'] ?? '',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.4),
                        ),
                        const SizedBox(height: 24),

                        // Варианты ответа или текстовое поле
                        Expanded(
                          child: SingleChildScrollView(
                            child: _buildAnswerInput(q, qId, qType, selected),
                          ),
                        ),

                        // Кнопки переключения "Назад / Далее"
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _currentIndex > 0
                                  ? () => _switchQuestion(_currentIndex - 1)
                                  : null,
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Предыдущий вопрос'),
                            ),
                            FilledButton.icon(
                              onPressed: _currentIndex < _questions.length - 1
                                  ? () => _switchQuestion(_currentIndex + 1)
                                  : _confirmAndSubmit,
                              icon: Icon(_currentIndex < _questions.length - 1
                                  ? Icons.arrow_forward
                                  : Icons.done_all),
                              label: Text(_currentIndex < _questions.length - 1
                                  ? 'Следующий вопрос'
                                  : 'Завершить тест'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerInput(
      Map<String, dynamic> q,
      int qId,
      String qType,
      List<int> selected,
      ) {
    final List<dynamic> options = q['options'] ?? [];

    if (qType == 'single') {
      return Column(
        children: List.generate(options.length, (idx) {
          final isSelected = selected.contains(idx);
          return Card(
            elevation: 0,
            color: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: isSelected ? Colors.blue.shade600 : Colors.grey.shade300,
              ),
            ),
            child: RadioListTile<int>(
              value: idx,
              groupValue: selected.isNotEmpty ? selected.first : null,
              title: Text(options[idx].toString(), style: const TextStyle(fontSize: 16)),
              onChanged: (val) {
                if (val == null) return;
                setState(() {
                  _ensureAnswer(qId)['selected'] = <int>[val];
                });
                _sendProgress(qId);
              },
            ),
          );
        }),
      );
    }

    if (qType == 'multiple') {
      return Column(
        children: List.generate(options.length, (idx) {
          final isSelected = selected.contains(idx);
          return Card(
            elevation: 0,
            color: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: isSelected ? Colors.blue.shade600 : Colors.grey.shade300,
              ),
            ),
            child: CheckboxListTile(
              value: isSelected,
              title: Text(options[idx].toString(), style: const TextStyle(fontSize: 16)),
              onChanged: (checked) {
                final sel = _ensureAnswer(qId)['selected'] as List<int>;
                setState(() {
                  if (checked == true) {
                    if (!sel.contains(idx)) sel.add(idx);
                  } else {
                    sel.remove(idx);
                  }
                });
                _sendProgress(qId);
              },
            ),
          );
        }),
      );
    }

    // Краткий ("text") или развернутый ("essay") ответ с блокировкой буфера обмена
    final bool isEssay = qType == 'essay';
    return TextField(
      controller: _textAnswerCtrl,
      maxLines: isEssay ? 8 : 1,
      enableInteractiveSelection: false,
      contextMenuBuilder: (context, editableTextState) => const SizedBox.shrink(),
      inputFormatters: [
        AntiPasteFormatter(),
      ],
      decoration: InputDecoration(
        hintText: isEssay
            ? 'Введите развернутый ответ своими словами (вставка из буфера обмена отключена)...'
            : 'Введите краткий ответ с клавиатуры...',
        border: const OutlineInputBorder(),
      ),
      onChanged: (val) {
        _ensureAnswer(qId)['text_answer'] = val;
        _sendProgress(qId);
      },
    );
  }

  void _resetForNextStudent() {
    _nameCtrl.clear();
    _groupCtrl.clear();
    setState(() {
      _screenState = 'login';
      _finalStatus = '';
      _finalReason = '';
      _finalScore = 0;
      _finalMaxScore = 0;
      _finalPercentage = 0;
      _finalGrade = 2;
    });
  }

  Widget _buildResultScreen() {
    final bool isBlocked = _finalStatus == 'blocked';
    return Center(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 16)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isBlocked ? Icons.gpp_bad_outlined : Icons.task_alt_outlined,
              size: 64,
              color: isBlocked ? Colors.red.shade700 : Colors.green.shade700,
            ),
            const SizedBox(height: 16),
            Text(
              isBlocked ? 'Попытка заблокирована Анти-читом!' : 'Тестирование завершено',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            if (_finalReason.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                _finalReason,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.w600),
              ),
            ],
            const Divider(height: 32),
            Text(
              'Набрано тестовых баллов: $_finalScore из $_finalMaxScore ($_finalPercentage%)',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Рекомендуемая оценка: $_finalGrade',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const SizedBox(height: 24),
            if (isBlocked)
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _screenState = 'login';
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Повторить вход (после разрешения преподавателя)'),
              )
            else
              FilledButton.icon(
                onPressed: _resetForNextStudent,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Следующий студент'),
              ),
          ],
        ),
      ),
    );
  }
}

