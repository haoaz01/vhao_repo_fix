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

  // =========================
  // FIX: Khử dấu an toàn (không out-of-range)
  // =========================
  String _normalizeVn(String input) {
    // 1) thay riêng đ/Đ để chắc ăn
    var out = input.replaceAll('đ', 'd').replaceAll('Đ', 'D');

    // 2) gom nhóm nguyên âm có dấu (lower + upper) -> chữ thường cơ bản
    final Map<RegExp, String> groups = {
      RegExp(r'[àáạảãâầấậẩẫăằắặẳẵÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴ]'): 'a',
      RegExp(r'[èéẹẻẽêềếệểễÈÉẸẺẼÊỀẾỆỂỄ]'): 'e',
      RegExp(r'[ìíịỉĩÌÍỊỈĨ]'): 'i',
      RegExp(r'[òóọỏõôồốộổỗơờớợởỡÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠ]'): 'o',
      RegExp(r'[ùúụủũưừứựửữÙÚỤỦŨƯỪỨỰỬỮ]'): 'u',
      RegExp(r'[ỳýỵỷỹỲÝỴỶỸ]'): 'y',
    };
    groups.forEach((re, rep) => out = out.replaceAll(re, rep));

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

  // Map ngược code -> tên “ước lượng” để match theo name khi code không khớp
  String _mapCodeToNameFallback(String code) {
    switch (code.toLowerCase()) {
      case 'toan':
        return 'toan';
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
    final subjectCode = _normalizeSubjectCode(subjectName);
    print("🔎 Fetching subject=$subjectName (code=$subjectCode), grade=$grade");

    // 1) Thử tìm subject theo grade+code
    try {
      final res1 = await api.get('/subjects?grade=$grade&code=$subjectCode');
      if (res1['statusCode'] == 200) {
        final data = res1['data'];
        int? subjectId;
        if (data is List && data.isNotEmpty) {
          final first = data.first;
          if (first is Map && first['id'] != null) {
            subjectId = first['id'] as int?;
          }
        } else if (data is Map && data['id'] != null) {
          subjectId = data['id'] as int?;
        }
        if (subjectId != null) {
          return await _fetchChaptersLessons(subjectId);
        }
      }
    } catch (_) {
      // ignore để thử fallback
    }

    // 2) Fallback: lấy list theo grade, match theo code hoặc name (khử dấu)
    try {
      final res2 = await api.get('/subjects?grade=$grade');
      if (res2['statusCode'] == 200) {
        final list = (res2['data'] is List) ? (res2['data'] as List) : <dynamic>[];
        Map<String, dynamic>? found;

        // match theo code
        for (final s in list) {
          if (s is Map) {
            final code = (s['code']?.toString().toLowerCase() ?? '');
            if (code == subjectCode.toLowerCase()) {
              found = Map<String, dynamic>.from(s);
              break;
            }
          }
        }

        // nếu chưa thấy, match theo name (khử dấu)
        if (found == null) {
          final target = _mapCodeToNameFallback(subjectCode); // đã lowercase
          for (final s in list) {
            if (s is Map) {
              final nameNorm = _normalizeVn(s['name']?.toString() ?? '');
              if (nameNorm.contains(target)) {
                found = Map<String, dynamic>.from(s);
                break;
              }
            }
          }
        }

        if (found != null) {
          final subjectId = found['id'] as int?;
          if (subjectId != null) {
            return await _fetchChaptersLessons(subjectId);
          }
        }
      }
    } catch (_) {
      // ignore để throw cuối
    }

    // DEPRECATED path — giữ lại để tham khảo (đã comment ở bản trước)

    // Nếu tới đây vẫn chưa return được:
    throw Exception("❌ Không tìm thấy môn học: $subjectCode - Khối $grade");
  }

  // ===== Helper chính thống để lấy chapters/lessons/contents/exercises (có check an toàn)
  Future<List<Chapter>> _fetchChaptersLessons(int subjectId) async {
    // 2) chapters
    print("📦 _fetchChaptersLessons => subjectId=$subjectId");
    final chaptersRes =
    await _getWithRetry("$baseUrl/subjects/$subjectId/chapters");
    final chaptersDecoded = json.decode(chaptersRes);
    final chaptersJson = (chaptersDecoded is List) ? chaptersDecoded : <dynamic>[];

    final List<Chapter> chapters = [];

    for (final ch in chaptersJson) {
      if (ch is! Map) continue;
      final chapterId = ch['id'];
      if (chapterId == null) continue;

      // 3) lessons
      final lessonsRes =
      await _getWithRetry("$baseUrl/chapters/$chapterId/lessons");
      final lessonsDecoded = json.decode(lessonsRes);
      final lessonsJson = (lessonsDecoded is List) ? lessonsDecoded : <dynamic>[];

      final List<Lesson> lessons = [];

      for (final lj in lessonsJson) {
        if (lj is! Map) continue;

        // gán subjectId cho lesson để UI/Progress dùng khi post
        lj['subjectId'] = subjectId;

        Lesson lesson = Lesson.fromJson(Map<String, dynamic>.from(lj));

        // 4) contents
        final contentsRes =
        await _getWithRetry("$baseUrl/lessons/${lesson.id}/contents");
        final contentsDecoded = json.decode(contentsRes);
        final contentsJson =
        (contentsDecoded is List) ? contentsDecoded : <dynamic>[];

        final contents = contentsJson
            .whereType<Map>()
            .map<ContentItem>(
                (x) => ContentItem.fromJson(Map<String, dynamic>.from(x)))
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

        lesson = lesson.copyWith(contents: contents);

        // 5) exercises
        final exercisesRes =
        await _getWithRetry("$baseUrl/lessons/${lesson.id}/exercises");
        final exercisesDecoded = json.decode(exercisesRes);
        final exercisesJson =
        (exercisesDecoded is List) ? exercisesDecoded : <dynamic>[];

        final List<Exercise> exercises = [];

        for (final ex in exercisesJson) {
          if (ex is! Map) continue;

          Exercise exercise =
          Exercise.fromJson(Map<String, dynamic>.from(ex));

          // 6) solutions
          final solutionsRes = await _getWithRetry(
              "$baseUrl/exercises/${exercise.id}/solutions");
          final solutionsDecoded = json.decode(solutionsRes);
          final solutionsJson =
          (solutionsDecoded is List) ? solutionsDecoded : <dynamic>[];

          final solutions = solutionsJson
              .whereType<Map>()
              .map<ExerciseSolution>((x) =>
              ExerciseSolution.fromJson(Map<String, dynamic>.from(x)))
              .toList();

          exercise = exercise.copyWith(solutions: solutions);
          exercises.add(exercise);
        }

        lesson = lesson.copyWith(exercises: exercises);
        lessons.add(lesson);
      }

      final chapter =
      Chapter.fromJson(Map<String, dynamic>.from(ch)).copyWith(lessons: lessons);
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
