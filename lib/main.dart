import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import 'models/exam_session.dart';
import 'services/exam_api_service.dart';
import 'services/anti_cheat_service.dart';
import 'screens/login_screen.dart';
import 'screens/exam_screen.dart';
import 'screens/result_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
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
  // --- Экранное состояние ---
  String _screenState = 'login'; // login | exam | result

  // --- Сервисы ---
  late ExamApiService _api;
  final AntiCheatService _antiCheat = AntiCheatService();

  // --- Данные сессии ---
  ExamSession? _session;
  ExamResult? _result;
  String _examTitle = 'Загрузка параметров экзамена...';

  // --- Таймеры ---
  Timer? _countdownTimer;
  Timer? _heartbeatTimer;
  Timer? _retryTimer;

  // --- UI-контроллеры ---
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _groupCtrl = TextEditingController();
  final TextEditingController _textAnswerCtrl = TextEditingController();

  int _currentIndex = 0;
  bool _isSubmitting = false;

  // Плоское представление ответов для ExamScreen и QuestionNavigator
  // (хранится в session.answers; здесь — адаптер для старых виджетов)
  Map<int, Map<String, dynamic>> get _answersMap {
    final m = <int, Map<String, dynamic>>{};
    _session?.answers.forEach((k, v) {
      m[k] = v.toJson();
    });
    return m;
  }

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _initApi();
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

  Future<void> _initApi() async {
    _api = await ExamApiService.create();
    final title = await _api.fetchExamTitle();
    if (mounted) {
      setState(() => _examTitle = title);
    }
  }

  // ─── Анти-чит события ──────────────────────────────────────────────────────

  @override
  void onWindowBlur() {
    if (_antiCheat.isActive && !_isSubmitting) {
      _triggerViolation(
          'АВТО-ЗАВЕРШЕНИЕ: Потеря фокуса окна (Alt+Tab / Win / Второй монитор)');
    }
  }

  @override
  void onWindowMinimize() {
    if (_antiCheat.isActive && !_isSubmitting) {
      _triggerViolation('АВТО-ЗАВЕРШЕНИЕ: Попытка свернуть окно');
    }
  }

  @override
  void onWindowClose() async {
    if (_antiCheat.isActive && !_isSubmitting) {
      await _triggerViolation('АВТО-ЗАВЕРШЕНИЕ: Попытка закрытия окна (Alt+F4)');
    }
    await windowManager.destroy();
  }

  Future<void> _triggerViolation(String reason) async {
    if (_isSubmitting) return;
    await _submitExam(status: 'blocked', reason: reason);
  }

  // ─── Экзамен: старт ────────────────────────────────────────────────────────

  Future<void> _startExam() async {
    final name = _nameCtrl.text.trim();
    final group = _groupCtrl.text.trim();
    if (name.isEmpty || group.isEmpty) {
      _showSnack('Введите ФИО и номер учебной группы!');
      return;
    }

    final (:session, :error) = await _api.startExam(name, group);
    if (error != null) {
      _showSnack(error);
      return;
    }

    _session = session;
    _currentIndex = 0;
    _syncTextController();

    setState(() => _screenState = 'exam');

    await _antiCheat.enable();
    _startTimer();
    _startHeartbeat();
  }

  // ─── Таймер и heartbeat ────────────────────────────────────────────────────

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final s = _session;
      if (s == null) {
        timer.cancel();
        return;
      }
      if (s.remainingSeconds <= 1) {
        timer.cancel();
        _submitExam(status: 'submitted', reason: 'Время вышло');
      } else {
        setState(() => s.remainingSeconds--);
      }
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
        const Duration(seconds: 10), (_) => _sendHeartbeat());
  }

  Future<void> _sendHeartbeat() async {
    final s = _session;
    if (s == null || _isSubmitting) return;
    final r = await _api.sendHeartbeat(s.sessionKey, s.sessionToken);
    if (!mounted) return;

    if (r.sessionLost) {
      _handleSessionLost();
      return;
    }

    if (r.remaining != null) {
      setState(() {
        s.linkLost = false;
        s.remainingSeconds = r.remaining!;
      });
      if (s.hasUnsynced) _flushAnswers();
      if (r.status != null && r.status != 'testing') {
        _submitExam(status: 'submitted');
      }
    } else {
      setState(() => s.linkLost = true);
    }
  }

  Future<void> _handleSessionLost() async {
    if (_isSubmitting || _screenState != 'exam') return;
    _cancelTimers();
    _session = null;
    if (mounted) {
      setState(() {
        _screenState = 'login';
      });
    }
    _showSnack('Сессия закрыта преподавателем. Войдите заново.');
    await _antiCheat.disable();
  }

  void _cancelTimers() {
    _countdownTimer?.cancel();
    _heartbeatTimer?.cancel();
    _retryTimer?.cancel();
  }

  // ─── Ответы ────────────────────────────────────────────────────────────────

  void _syncTextController() {
    final s = _session;
    if (s == null || s.questions.isEmpty) return;
    final q = s.questions[_currentIndex];
    final ans = s.answers[q['id']];
    _textAnswerCtrl.text = ans?.textAnswer ?? '';
  }

  StudentAnswer _ensureStudentAnswer(int qId) {
    final s = _session!;
    return s.answers.putIfAbsent(
        qId,
        () => StudentAnswer(questionId: qId, selected: []));
  }

  Map<String, dynamic> _answerOrEmpty(int qId) {
    return _session?.answers[qId]?.toJson() ??
        {'question_id': qId, 'selected': <int>[], 'text_answer': '', 'flagged': false};
  }

  bool _isAnswered(Map<String, dynamic>? ans) {
    if (ans == null) return false;
    return (ans['selected'] as List).isNotEmpty ||
        (ans['text_answer'] as String).trim().isNotEmpty;
  }

  Future<void> _onSendProgress(int qId) async {
    final s = _session;
    if (s == null) return;
    final ans = s.answers[qId];
    if (ans == null) return;
    if (!await _api.sendAnswer(s.sessionKey, s.sessionToken, ans)) {
      setState(() => s.hasUnsynced = true);
      setState(() => s.linkLost = true);
    }
  }

  Future<void> _flushAnswers() async {
    final s = _session;
    if (s == null) return;
    s.hasUnsynced = false;
    final failed = <StudentAnswer>[];
    for (final ans in s.answers.values.toList()) {
      if (!await _api.sendAnswer(s.sessionKey, s.sessionToken, ans)) {
        failed.add(ans);
      }
    }
    if (failed.isNotEmpty && mounted) {
      setState(() => s.hasUnsynced = true);
    }
  }

  void _switchQuestion(int newIndex) {
    final s = _session;
    if (s == null || s.questions.isEmpty) return;
    final currentQ = s.questions[_currentIndex];
    _onSendProgress(currentQ['id']);
    setState(() {
      _currentIndex = newIndex;
      _syncTextController();
    });
  }

  // ─── Сдача ─────────────────────────────────────────────────────────────────

  Future<void> _submitExam({required String status, String reason = ''}) async {
    final s = _session;
    if (s == null || _isSubmitting) return;
    _isSubmitting = true;
    _cancelTimers();

    final r = await _api.submitExam(
        s.sessionKey, s.sessionToken, status, reason, s.answers);

    if (r.result != null) {
      _result = r.result;
      _retryTimer?.cancel();
      await _antiCheat.disable();
      if (mounted) {
        setState(() {
          _screenState = 'result';
          _isSubmitting = false;
          s.linkLost = false;
        });
      }
      return;
    }

    if (r.sessionLost) {
      _isSubmitting = false;
      _handleSessionLost();
      return;
    }

    // retry
    _isSubmitting = false;
    if (mounted) setState(() => s.linkLost = true);
    _showSnack('Нет связи с сервером. Работа не отправлена, повторная попытка...');
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 5), () {
      if (_screenState == 'exam') {
        _submitExam(status: status, reason: reason);
      }
    });
  }

  void _confirmAndSubmit() {
    final s = _session;
    if (s == null) return;
    final unanswered = s.countUnanswered();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Завершить тестирование?'),
        content: Text(
          unanswered > 0
              ? 'Внимание! У вас осталось неотвеченных вопросов: $unanswered.\n'
                  'Вы действительно хотите сдать тест?'
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

  void _resetForNextStudent() {
    _nameCtrl.clear();
    _groupCtrl.clear();
    _session = null;
    _result = null;
    setState(() => _screenState = 'login');
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  void _onAnswerChanged(int qId, String key, dynamic value) {
    final ans = _ensureStudentAnswer(qId);
    switch (key) {
      case 'selected':
        ans.selected = List<int>.from(value as List);
        break;
      case 'text_answer':
        ans.textAnswer = value as String;
        break;
      case 'flagged':
        ans.flagged = value as bool;
        break;
    }
    setState(() {});
  }

  // ─── Сборка ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyC, control: true): () {},
        const SingleActivator(LogicalKeyboardKey.keyV, control: true): () {},
        const SingleActivator(LogicalKeyboardKey.insert, shift: true): () {},
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0D12),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final s = _session;
    switch (_screenState) {
      case 'exam':
        if (s == null) return const SizedBox.shrink();
        return ExamScreen(
          studentName: _nameCtrl.text,
          studentGroup: _groupCtrl.text,
          questions: s.questions,
          currentIndex: _currentIndex,
          answers: _answersMap,
          remainingSeconds: s.remainingSeconds,
          linkLost: s.linkLost,
          onSwitchQuestion: _switchQuestion,
          onConfirmSubmit: _confirmAndSubmit,
          isAnswered: _isAnswered,
          onSendProgress: _onSendProgress,
          onAnswerChanged: _onAnswerChanged,
          answerOrEmpty: _answerOrEmpty,
          textAnswerController: _textAnswerCtrl,
        );
      case 'result':
        return ResultScreen(
          result: _result!,
          onNextStudent: _resetForNextStudent,
        );
      default:
        return LoginScreen(
          examTitle: _examTitle,
          nameController: _nameCtrl,
          groupController: _groupCtrl,
          onStartExam: _startExam,
        );
    }
  }
}

