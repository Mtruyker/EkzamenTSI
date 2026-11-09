class ExamSession {
  final String sessionKey;
  String sessionToken;
  int remainingSeconds;
  final List<dynamic> questions;
  final Map<int, StudentAnswer> answers;
  bool linkLost;
  bool hasUnsynced;

  ExamSession({
    required this.sessionKey,
    required this.sessionToken,
    required this.remainingSeconds,
    required this.questions,
    this.linkLost = false,
    this.hasUnsynced = false,
  }) : answers = {};

  void restoreSavedAnswers(Map<String, dynamic>? saved) {
    if (saved == null) return;
    saved.forEach((k, v) {
      final qId = int.tryParse(k);
      if (qId != null && v is Map<String, dynamic>) {
        answers[qId] = StudentAnswer.fromJson(qId, v);
      }
    });
  }

  bool isAnswered(int questionId) {
    final ans = answers[questionId];
    if (ans == null) return false;
    return ans.selected.isNotEmpty || ans.textAnswer.trim().isNotEmpty;
  }

  int countUnanswered() {
    int count = 0;
    for (final q in questions) {
      if (!isAnswered(q['id'])) count++;
    }
    return count;
  }
}

class StudentAnswer {
  final int questionId;
  List<int> selected;
  String textAnswer;
  bool flagged;

  StudentAnswer({
    required this.questionId,
    this.selected = const [],
    this.textAnswer = '',
    this.flagged = false,
  });

  factory StudentAnswer.fromJson(int qId, Map<String, dynamic> json) {
    return StudentAnswer(
      questionId: qId,
      selected: List<int>.from(json['selected'] ?? []),
      textAnswer: (json['text_answer'] ?? '').toString(),
      flagged: json['flagged'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'selected': selected,
      'text_answer': textAnswer,
      'flagged': flagged,
    };
  }
}

class ExamResult {
  final String status;
  final String reason;
  final int score;
  final int maxScore;
  final double percentage;
  final int grade;

  ExamResult({
    required this.status,
    this.reason = '',
    required this.score,
    required this.maxScore,
    required this.percentage,
    required this.grade,
  });

  factory ExamResult.fromJson(Map<String, dynamic> json) {
    return ExamResult(
      status: json['status'] ?? '',
      reason: json['reason'] ?? '',
      score: json['score'] ?? 0,
      maxScore: json['max_score'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
      grade: json['grade'] ?? 2,
    );
  }

  bool get isBlocked => status == 'blocked';
}
