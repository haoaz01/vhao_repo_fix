import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../api/api_service.dart';
import '../model/chapter_model.dart';
import '../model/exercise_model.dart';
import '../model/lesson_model.dart';

class SubjectRepository {
  final APIService api = APIService();

  late final String baseUrl;
  late final http.Client client;

  SubjectRepository() {
    if (kIsWeb) {
      baseUrl = "http://192.168.1.219:8080/api";
    } else if (Platform.isAndroid) {
      baseUrl = "http://192.168.1.219:8080/api";
    } else if (Platform.isIOS) {
      baseUrl = "http://localhost:8080/api";
    } else {
      baseUrl = "http://192.168.1.219:8080/api";
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
  String _normalizeVn(String input) {
    const src =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ'
        'ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ';
    const dst =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuyyyyyd'
        'AAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIoooooooooooooooooUUUUUUUUUUYYYYYĐ';
    var out = input;
    for (int i = 0; i < src.length; i++) {
      out = out.replaceAll(src[i], dst[i]);
    }
    return out.toLowerCase().trim();
  }

  String _normalizeSubjectCode(String subjectName) {
    final n = _normalizeVn(subjectName).replaceAll(' ', '');
    if (n.contains('toan')) return 'toan';
    if (n.contains('nguvan') || n == 'van') return 'nguvan';
    if (n.contains('tienganh') || n == 'anh') return 'tienganh';
    if (n.contains('khoahoctunhien')) return 'khoahoctunhien';
    // fallback: dùng chuỗi đã normalize
    return n;
  }

  // Khử dấu để so khớp tên


  // Map ngược code -> tên “ước lượng” để match theo name khi code không khớp
  String _mapCodeToNameFallback(String code) {
    switch (code.toLowerCase()) {
      case 'toan':
        return 'toan'; // không dấu để so khớp sau khi normalize
      case 'nguvan':
        return 'ngu van';
      case 'tienganh':
        return 'tieng anh';
      case 'khoahoctunhien':
        return 'khoa hoc tu nhien';
      default:
        return code.toLowerCase();
    }
  }

  /// ✅ Lấy chapters + lessons + contents + exercises theo subjectName + grade
  Future<List<Chapter>> fetchTheory(String subjectName, int grade) async {
    // ===========================
    // NEW LOGIC (ổn định + fallback)
    // ===========================
    final subjectCode = _normalizeSubjectCode(subjectName);
    print("🔎 Fetching subject=$subjectName (code=$subjectCode), grade=$grade");

    // 1) Thử tìm subject theo grade+code bằng APIService (sửa lại cho đúng query param)
    try {
      final res1 = await api.get('/subjects?grade=$grade&code=$subjectCode');
      if (res1['statusCode'] == 200) {
        final data = res1['data'];
        int? subjectId;
        // backend có thể trả List hoặc Object
        if (data is List && data.isNotEmpty) {
          subjectId = (data.first as Map)['id'] as int?;
        } else if (data is Map && data['id'] != null) {
          subjectId = data['id'] as int?;
        }
        if (subjectId != null) {
          return await _fetchChaptersLessons(subjectId);
        }
      }
    } catch (_) {
      // cho qua để thử fallback
    }

    // 2) Fallback: lấy list theo grade, match theo code hoặc name (khử dấu)
    try {
      final res2 = await api.get('/subjects?grade=$grade');
      if (res2['statusCode'] == 200) {
        final list = (res2['data'] as List?) ?? [];
        Map<String, dynamic>? found;

        // match theo code
        for (final s in list) {
          final code = (s['code']?.toString().toLowerCase() ?? '');
          if (code == subjectCode.toLowerCase()) {
            found = Map<String, dynamic>.from(s);
            break;
          }
        }

        // nếu chưa thấy, match theo name (khử dấu)
        if (found == null) {
          final target = _mapCodeToNameFallback(subjectCode); // đã lowercase
          for (final s in list) {
            final nameNorm = _normalizeVn(s['name']?.toString() ?? '');
            if (nameNorm.contains(target)) {
              found = Map<String, dynamic>.from(s);
              break;
            }
          }
        }

        if (found != null) {
          final subjectId = found['id'] as int;
          return await _fetchChaptersLessons(subjectId);
        }
      }
    } catch (_) {
      // rơi xuống DEPRECATED hoặc throw
    }

    // ===========================
    // DEPRECATED (giữ lại để tham chiếu – từng giả định API /subjects trả object)
    // ===========================
    /*
    // DEPRECATED: đoạn này giả định /subjects?grade=&code= trả về 1 object có {id}, nhưng backend của bạn trả List.
    // Để tránh hỏng cấu trúc, mình giữ lại cho bạn tham khảo:
    try {
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
          Lesson lesson =
              Lesson.fromJson(Map<String, dynamic>.from(lessonJson));

          // 4️⃣ Lấy contents
          final contentsRes = await _getWithRetry(
              "$baseUrl/lessons/${lesson.id}/contents");
          final contentsJson = json.decode(contentsRes) as List;

          final contents = contentsJson
              .map<ContentItem>((x) =>
                  ContentItem.fromJson(Map<String, dynamic>.from(x)))
              .toList()
            ..sort((a, b) => a.order.compareTo(b.order));

          lesson = lesson.copyWith(contents: contents);

          // 5️⃣ Lấy exercises
          final exercisesRes = await _getWithRetry(
              "$baseUrl/lessons/${lesson.id}/exercises");
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
                .map<ExerciseSolution>((x) =>
                    ExerciseSolution.fromJson(Map<String, dynamic>.from(x)))
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
      print("❌ ERROR fetchTheory (DEPRECATED path): $e");
      // tiếp tục throw ở dưới
    }
    */

    // Nếu tới đây vẫn chưa return được:
    throw Exception("❌ Không tìm thấy môn học: $subjectCode - Khối $grade");
  }

  // ===== Helper chính thống hiện tại để lấy chapters/lessons/contents/exercises
  Future<List<Chapter>> _fetchChaptersLessons(int subjectId) async {
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
        // gán subjectId cho lesson để UI/Progress dùng khi post
        lessonJson['subjectId'] = subjectId;
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
              .map<ExerciseSolution>((x) =>
              ExerciseSolution.fromJson(Map<String, dynamic>.from(x)))
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