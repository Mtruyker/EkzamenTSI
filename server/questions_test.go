package main

import (
	"encoding/json"
	"fmt"
	"os"
	"strings"
	"testing"
)

func readQuestionBank(t *testing.T) ExamConfig {
	t.Helper()
	data, err := os.ReadFile("questions.json")
	if err != nil {
		t.Fatal(err)
	}
	var cfg ExamConfig
	if err := json.Unmarshal(data, &cfg); err != nil {
		t.Fatal(err)
	}
	return cfg
}

func TestQuestionBankIntegrity(t *testing.T) {
	cfg := readQuestionBank(t)
	if cfg.QuestionsPerStudent <= 0 || cfg.QuestionsPerStudent > len(cfg.Questions) || cfg.TimeLimitMinutes <= 0 {
		t.Fatal("invalid exam settings")
	}
	ids, texts := map[int]bool{}, map[string]bool{}
	for _, q := range cfg.Questions {
		if q.ID <= 0 || ids[q.ID] {
			t.Fatalf("invalid or duplicate ID: %d", q.ID)
		}
		ids[q.ID] = true
		text := normalizeAnswer(q.Text)
		if text == "" || texts[text] || q.Points <= 0 {
			t.Fatalf("question %d: invalid text, duplicate text or invalid points", q.ID)
		}
		texts[text] = true
		switch q.Type {
		case "single", "multiple":
			if len(q.Options) < 2 || len(q.Correct) == 0 || len(q.Correct) > len(q.Options) {
				t.Fatalf("question %d: invalid choices", q.ID)
			}
			if q.Type == "single" && len(q.Correct) != 1 || q.Type == "multiple" && len(q.Correct) < 2 {
				t.Fatalf("question %d: incorrect answer count for type", q.ID)
			}
			options, keys := map[string]bool{}, map[int]bool{}
			for _, option := range q.Options {
				value := normalizeAnswer(option)
				if value == "" || options[value] {
					t.Fatalf("question %d: empty or duplicate option", q.ID)
				}
				options[value] = true
			}
			for _, key := range q.Correct {
				if key < 0 || key >= len(q.Options) || keys[key] {
					t.Fatalf("question %d: invalid or duplicate answer index", q.ID)
				}
				keys[key] = true
			}
		case "text":
			if len(q.CorrectText) == 0 {
				t.Fatalf("question %d: missing text answers", q.ID)
			}
			for _, answer := range q.CorrectText {
				if normalizeAnswer(answer) == "" {
					t.Fatalf("question %d: empty text answer", q.ID)
				}
			}
		default:
			t.Fatalf("question %d: unsupported auto-graded type %q", q.ID, q.Type)
		}
	}
	questions, mapping, maxScore := generateTicket(cfg)
	if len(questions) != cfg.QuestionsPerStudent {
		t.Fatal("incorrect ticket size")
	}
	seen, total := map[int]bool{}, 0
	for _, q := range questions {
		if !ids[q.ID] || seen[q.ID] {
			t.Fatalf("unknown or duplicate ticket question %d", q.ID)
		}
		seen[q.ID] = true
		total += q.Points
		if len(mapping[q.ID]) != len(q.Options) {
			t.Fatalf("question %d: incorrect option mapping size", q.ID)
		}
	}
	if total != maxScore {
		t.Fatal("incorrect maximum score")
	}
}

func TestBankAnswersAfterShuffle(t *testing.T) {
	cfg := readQuestionBank(t)
	original := state.Config
	t.Cleanup(func() { state.Config = original })
	for _, q := range cfg.Questions {
		t.Run(fmt.Sprint(q.ID), func(t *testing.T) {
			one := ExamConfig{QuestionsPerStudent: 1, Questions: []Question{q}}
			state.Config = one
			questions, mapping, maxScore := generateTicket(one)
			answer := StudentAnswer{QuestionID: q.ID}
			for shuffled, originalIndex := range mapping[q.ID] {
				if questions[0].Options[shuffled] != q.Options[originalIndex] {
					t.Fatal("option text does not match answer mapping")
				}
				for _, correct := range q.Correct {
					if originalIndex == correct {
						answer.Selected = append(answer.Selected, shuffled)
					}
				}
			}
			s := &StudentSession{AssignedQs: questions, OptionMapping: mapping, MaxScore: maxScore}
			check := func(a StudentAnswer, want int) {
				t.Helper()
				s.Answers = map[int]StudentAnswer{q.ID: a}
				calculateScore(s)
				if s.Score != want {
					t.Fatalf("score = %d, want %d", s.Score, want)
				}
			}
			if q.Type == "text" {
				for _, valid := range q.CorrectText {
					answer.TextAnswer = "  " + strings.ToUpper(valid) + "  "
					check(answer, q.Points)
				}
				answer.TextAnswer = "заведомо неверный ответ для проверки"
				check(answer, 0)
			} else {
				check(answer, q.Points)
				if q.Type == "multiple" {
					partial := answer
					partial.Selected = answer.Selected[:len(answer.Selected)-1]
					check(partial, 0)
				}
				for shuffled, originalIndex := range mapping[q.ID] {
					correct := false
					for _, key := range q.Correct {
						correct = correct || key == originalIndex
					}
					if !correct {
						wrong := StudentAnswer{QuestionID: q.ID, Selected: []int{shuffled}}
						if q.Type == "multiple" {
							wrong.Selected = append(append([]int{}, answer.Selected...), shuffled)
						}
						check(wrong, 0)
					}
				}
			}
			check(StudentAnswer{QuestionID: q.ID}, 0)
		})
	}
}
