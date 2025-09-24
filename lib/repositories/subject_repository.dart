import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../model/chapter_model.dart';
import '../model/exercise_model.dart';
import '../model/lesson_model.dart';

class SubjectRepository {
  late final String baseUrl;
  late final http.Client client;

  SubjectRepository() {
    if (kIsWeb) {
      baseUrl = "http://10.0.2.2:8080/api";
    } else if (Platform.isAndroid) {
      baseUrl = "http://10.0.2.2:8080/api";
    } else if (Platform.isIOS) {
      baseUrl = "http://localhost:8080/api";
    } else {
      baseUrl = "http://10.0.2.2:8080/api";
    }

    print("Using baseUrl: $baseUrl");
    client = _createHttpClient();
  }

  http.Client _createHttpClient() {
    if (kIsWeb) return http.Client();

    final httpClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 30)
      ..idleTimeout = const Duration(seconds: 30)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

    return IOClient(httpClient);
  }

  String _normalizeSubjectCode(String subjectName) {
    final mapping = {
      "Toán": "toan",
      "Ngữ Văn": "nguvan",
      "Khoa học Tự nhiên": "khoahoctunhien",
      "Tiếng Anh": "tienganh",
    };

    return mapping[subjectName] ??
        subjectName.toLowerCase().replaceAll(" ", "");
  }

  /// ✅ Lấy chapters + lessons + contents + exercises theo subjectCode + grade
  Future<List<Chapter>> fetchTheory(String subjectName, int grade) async {
    try {
      final subjectCode = _normalizeSubjectCode(subjectName);
      print("🔎 Fetching subject=$subjectName (code=$subjectCode), grade=$grade");

      // 1️⃣ Lấy subject theo grade + code
      final subjectRes = await _getWithRetry(
          "$baseUrl/subjects?grade=$grade&code=$subjectCode");
      final subjectData = json.decode(subjectRes);

      if (subjectData == null ||
          subjectData is! Map ||
          subjectData['id'] == null) {
        throw Exception("❌ Không tìm thấy môn học: $subjectName - Khối $grade");
      }
      final int subjectId = subjectData['id'];

      // 2️⃣ Lấy danh sách chapters
      final chaptersRes =
      await _getWithRetry("$baseUrl/subjects/$subjectId/chapters");
      final chaptersJson = json.decode(chaptersRes) as List;

      List<Chapter> chapters = [];

      for (var chapterJson in chaptersJson) {
        final chapterId = chapterJson['id'];
        if (chapterId == null) continue;

        // 3️⃣ Lấy danh sách lessons
        final lessonsRes =
        await _getWithRetry("$baseUrl/chapters/$chapterId/lessons");
        final lessonsJson = json.decode(lessonsRes) as List;

        List<Lesson> lessons = [];

        for (var lessonJson in lessonsJson) {
          lessonJson['subjectId'] = subjectId; // gán subjectId cho lesson
          Lesson lesson = Lesson.fromJson(Map<String, dynamic>.from(lessonJson));

          // 4️⃣ Lấy contents
          final contentsRes =
          await _getWithRetry("$baseUrl/lessons/${lesson.id}/contents");
          final contentsJson = json.decode(contentsRes) as List;

          final contents = contentsJson
              .map<ContentItem>(
                  (x) => ContentItem.fromJson(Map<String, dynamic>.from(x)))
              .toList()
            ..sort((a, b) => a.order.compareTo(b.order));

          lesson = lesson.copyWith(contents: contents);

          // 5️⃣ Lấy exercises
          final exercisesRes =
          await _getWithRetry("$baseUrl/lessons/${lesson.id}/exercises");
          final exercisesJson = json.decode(exercisesRes) as List;

          List<Exercise> exercises = [];

          for (var exJson in exercisesJson) {
            Exercise exercise =
            Exercise.fromJson(Map<String, dynamic>.from(exJson));

            // 6️⃣ Lấy solutions
            final solutionsRes = await _getWithRetry(
                "$baseUrl/exercises/${exercise.id}/solutions");
            final solutionsJson = json.decode(solutionsRes) as List;

            final solutions = solutionsJson
                .map<ExerciseSolution>(
                    (x) => ExerciseSolution.fromJson(Map<String, dynamic>.from(x)))
                .toList();

            exercise = exercise.copyWith(solutions: solutions);
            exercises.add(exercise);
          }

          lesson = lesson.copyWith(exercises: exercises);
          lessons.add(lesson);
        }

        Chapter chapter =
        Chapter.fromJson(Map<String, dynamic>.from(chapterJson))
            .copyWith(lessons: lessons);
        chapters.add(chapter);
      }

      return chapters;
    } catch (e) {
      print("❌ ERROR fetchTheory: $e");
      throw Exception("Không thể tải dữ liệu từ API: $e");
    }
  }

  Future<String> _getWithRetry(String url, {int maxRetries = 3}) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        print("🌐 Calling API (attempt ${i + 1}/$maxRetries): $url");
        final response = await client
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 15));

        if (response.statusCode != 200) {
          print("❌ Server error ${response.statusCode}: ${response.body}");
          throw Exception("Lỗi server: ${response.statusCode} khi gọi $url");
        }

        return response.body;
      } catch (e) {
        if (i == maxRetries - 1) rethrow;
        print("🔁 Retrying API call after error: $e");
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    throw Exception("❌ Failed to call API after $maxRetries attempts");
  }

  void dispose() {
    client.close();
  }
}
