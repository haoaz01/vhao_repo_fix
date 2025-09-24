import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/progress_model.dart';
import '../model/progress_history_model.dart';

class ProgressService {
  // Thay đổi baseUrl nếu cần: trỏ tới server Spring Boot của bạn
  // Nếu dùng Android emulator: 10.0.2.2 thay cho localhost
  final String baseUrl = "http://192.168.15.192:8080/api/progress";

  Future<List<ProgressModel>> fetchProgressByUserAndGrade(int userId, int grade) async {
    final url = Uri.parse("$baseUrl/$userId/$grade");
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final List data = json.decode(res.body) as List;
      return data.map((e) => ProgressModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load progress: ${res.statusCode}');
    }
  }

  Future<List<ProgressModel>> fetchProgressByUser(int userId) async {
    final url = Uri.parse("$baseUrl/$userId");
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final List data = json.decode(res.body) as List;
      return data.map((e) => ProgressModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load progress: ${res.statusCode}');
    }
  }

  Future<void> updateProgress({
    required int userId,
    required int grade,
    required String subject,
    required int completedLessons,
    required int totalLessons,
  }) async {
    final url = Uri.parse("$baseUrl/update");
    final body = json.encode({
      "userId": userId,
      "grade": grade,
      "subject": subject,
      "completedLessons": completedLessons,
      "totalLessons": totalLessons
    });

    final res = await http.post(url, headers: {'Content-Type': 'application/json'}, body: body);
    if (res.statusCode != 200) {
      throw Exception('Failed to update progress: ${res.statusCode} - ${res.body}');
    }
  }

  Future<List<ProgressHistoryModel>> fetchHistory({
    required int userId,
    required String subject,
    required String range, // "day", "week", "month"
  }) async {
    final url = Uri.parse("$baseUrl/history/$userId?subject=${Uri.encodeComponent(subject)}&range=${Uri.encodeComponent(range)}");
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final List data = json.decode(res.body) as List;
      return data.map((e) => ProgressHistoryModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load history: ${res.statusCode}');
    }
  }
}
