import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/exam_session.dart';

class ExamApiService {
  String serverUrl;

  ExamApiService(this.serverUrl);

  static Future<ExamApiService> create() async {
    String url = 'http://10.164.203.35:8080';

    // 1. --dart-define=SERVER_URL
    const definedUrl = String.fromEnvironment('SERVER_URL', defaultValue: '');
    if (definedUrl.isNotEmpty) {
      return ExamApiService(definedUrl);
    }

    // 2. server_ip.txt
    try {
      final file = File('server_ip.txt');
      if (await file.exists()) {
        final content = (await file.readAsString()).trim();
        if (content.isNotEmpty) {
          url = content.startsWith('http') ? content : 'http://$content:8080';
        }
      }
    } catch (_) {}

    return ExamApiService(url);
  }

  Future<String> fetchExamTitle() async {
    try {
      final res = await http
          .get(Uri.parse('$serverUrl/api/info'))
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        return data['title'] ?? 'Теоретический экзамен';
      }
    } catch (_) {}
    return 'Не удалось подключиться к серверу ($serverUrl)';
  }

  Future<({ExamSession? session, String? error})> startExam(
      String fullName,
      String group,
      ) async {
    try {
      final res = await http.post(
        Uri.parse('$serverUrl/api/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'full_name': fullName, 'group': group}),
      );

      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (res.statusCode == 403) {
        final String err = data['error'] ?? 'Доступ запрещен';
        return (session: null, error: err);
      }
      if (res.statusCode != 200) {
        return (session: null, error: 'Ошибка: ${res.body}');
      }

      final session = ExamSession(
        sessionKey: data['session_key'],
        sessionToken: data['session_token'] ?? '',
        remainingSeconds: data['remaining_seconds'] ?? 1500,
        questions: data['questions'] ?? [],
      );
      session.restoreSavedAnswers(data['saved_answers']);

      return (session: session, error: null);
    } catch (e) {
      return (session: null, error: 'Ошибка соединения: $e');
    }
  }

  Future<({int? remaining, String? status, bool sessionLost})> sendHeartbeat(
      String sessionKey,
      String sessionToken,
      ) async {
    try {
      final res = await http
          .post(
        Uri.parse('$serverUrl/api/heartbeat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'session_key': sessionKey,
          'session_token': sessionToken,
        }),
      )
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final int? rem = data['remaining_seconds'] as int?;
        final String? st = data['status'] as String?;
        return (
          remaining: rem,
          status: st,
          sessionLost: false,
        );
      }
      if (res.statusCode == 403) {
        return (remaining: null, status: null, sessionLost: true);
      }
    } catch (_) {}
    return (remaining: null, status: null, sessionLost: false);
  }

  Future<bool> sendAnswer(
      String sessionKey,
      String sessionToken,
      StudentAnswer answer,
      ) async {
    try {
      final res = await http
          .post(
        Uri.parse('$serverUrl/api/progress'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'session_key': sessionKey,
          'session_token': sessionToken,
          'answer': answer.toJson(),
        }),
      )
          .timeout(const Duration(seconds: 5));

      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<({ExamResult? result, bool retry, bool sessionLost})> submitExam(
      String sessionKey,
      String sessionToken,
      String status,
      String reason,
      Map<int, StudentAnswer> answers,
      ) async {
    final Map<String, dynamic> serialized = {};
    answers.forEach((k, v) {
      serialized[k.toString()] = v.toJson();
    });

    try {
      final res = await http
          .post(
        Uri.parse('$serverUrl/api/submit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'session_key': sessionKey,
          'session_token': sessionToken,
          'status': status,
          'reason': reason,
          'answers': serialized,
        }),
      )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200 || res.statusCode == 409) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        return (
          result: ExamResult.fromJson(data),
          retry: false,
          sessionLost: false,
        );
      }
      if (res.statusCode == 403) {
        return (result: null, retry: false, sessionLost: true);
      }
    } catch (_) {}

    return (result: null, retry: true, sessionLost: false);
  }
}
