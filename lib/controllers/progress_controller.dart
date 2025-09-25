import 'package:get/get.dart';
import '../api/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ enum ở top-level
enum StatsRange { day, week, month }

class ProgressController extends GetxController {
  final APIService api = APIService();
  // ⬅️ trigger cho Dashboard/Chart/Streak UI
  final RxInt statsVersion = 0.obs;

  // Cho phép màn khác đọc nhanh danh sách ngày đã học (wrap public)
  Future<Set<DateTime>> readStudyDays() => loadAllStudyDays();

  // ===== Key helpers =====
  String _key(String subjectCode, int grade) => '${subjectCode}_$grade';
  String _logKey(String subjectCode, int grade) =>
      'completionLog_${subjectCode}_$grade';

  String _encodeLog(DateTime when, int lessonId) =>
      '${when.millisecondsSinceEpoch}|$lessonId';

  final RxMap<String, double> progressMap = <String, double>{}.obs;
  final RxMap<String, RxSet<int>> completedLessons = <String, RxSet<int>>{}.obs;
  final RxBool isLoading = false.obs;

  ({DateTime when, int lessonId})? _decodeLog(String raw) {
    final parts = raw.split('|');
    if (parts.length != 2) return null;
    final ts = int.tryParse(parts[0]) ?? 0;
    final id = int.tryParse(parts[1]) ?? 0;
    if (ts <= 0 || id <= 0) return null;
    return (when: DateTime.fromMillisecondsSinceEpoch(ts), lessonId: id);
  }

  Future<void> _appendCompletionLog({
    required String subjectCode,
    required int grade,
    required int lessonId,
    required DateTime when,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _logKey(subjectCode, grade);
    final list = prefs.getStringList(key) ?? <String>[];
    list.add(_encodeLog(when, lessonId));
    await prefs.setStringList(key, list);
  }

  // =================== CHART STATS (local log) ===================
  Future<Map<DateTime, int>> getCompletionStats({
    required String subjectCode,
    required int grade,
    required StatsRange range,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _logKey(subjectCode, grade);
    final list = prefs.getStringList(key) ?? <String>[];

    final now = DateTime.now();
    int bucketCount;
    Duration step;
    DateTime Function(DateTime) bucketStart;

    switch (range) {
      case StatsRange.day:
        bucketCount = 7;
        step = const Duration(days: 1);
        bucketStart = (d) => DateTime(d.year, d.month, d.day);
        break;
      case StatsRange.week:
        bucketCount = 8;
        step = const Duration(days: 7);
        bucketStart = (d) {
          final dayOfWeek = d.weekday; // 1..7 (Mon..Sun)
          final monday = d.subtract(Duration(days: dayOfWeek - 1));
          return DateTime(monday.year, monday.month, monday.day);
        };
        break;
      case StatsRange.month:
        bucketCount = 6;
        step = const Duration(days: 30); // xấp xỉ
        bucketStart = (d) => DateTime(d.year, d.month, 1);
        break;
    }

    // tạo bucket lùi về quá khứ
    final Map<DateTime, int> buckets = {};
    var cursor = bucketStart(now);
    for (int i = 0; i < bucketCount; i++) {
      buckets[cursor] = 0;
      cursor = bucketStart(cursor.subtract(step));
    }

    // đổ log vào bucket
    for (final raw in list) {
      final entry = _decodeLog(raw);
      if (entry == null) continue;
      final b = bucketStart(entry.when);
      if (buckets.containsKey(b)) {
        buckets[b] = (buckets[b] ?? 0) + 1;
      }
    }

    final sortedKeys = buckets.keys.toList()..sort();
    return {for (final k in sortedKeys) k: buckets[k] ?? 0};
  }

  // =================== PROGRESS APIs ===================
  double getProgress(String subjectCode, int grade) =>
      progressMap[_key(subjectCode, grade)] ?? 0.0;

  void setProgressLocal(String subjectCode, int grade, double value) {
    progressMap[_key(subjectCode, grade)] = value.clamp(0.0, 1.0);
    progressMap.refresh();
  }

  Future<void> loadProgress({required int userId}) async {
    try {
      isLoading.value = true;

      final response = await api.get('/progress/user/$userId');

      if (response['statusCode'] == 200) {
        final data = response['data'];
        if (data is List) {
          for (var sp in data) {
            final subjectName = sp['subject']?.toString() ?? '';
            final grade = (sp['grade'] as num?)?.toInt() ?? 0;
            final progressPercent =
                (sp['progressPercent'] as num?)?.toDouble() ?? 0.0;

            final subjectCode = mapSubjectToCode(subjectName);

            // Backend trả % (0..100), UI dùng 0..1
            setProgressLocal(subjectCode, grade, progressPercent / 100.0);

            final k = _key(subjectCode, grade);
            if (!completedLessons.containsKey(k)) {
              completedLessons[k] = <int>{}.obs;
            }
          }
        }
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải tiến độ từ server');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> markLessonCompleted({
    required int userId,
    required String subjectName,
    required int grade,
    required int lessonId,
    required int totalLessons,
    required int subjectId,
  }) async {
    try {
      final subjectCode = mapSubjectToCode(subjectName);
      final k = _key(subjectCode, grade);

      if (!completedLessons.containsKey(k)) {
        completedLessons[k] = <int>{}.obs;
      }

      // update local trước để UI mượt
      completedLessons[k]!.add(lessonId);
      final completedCount = completedLessons[k]!.length;
      final progress = totalLessons > 0 ? completedCount / totalLessons : 0.0;
      setProgressLocal(subjectCode, grade, progress);

      final updateData = {
        'userId': userId,
        'grade': grade,
        'subjectId': subjectId,
        'completedLessons': completedCount,
        'totalLessons': totalLessons,
        'lessonId': lessonId,
      };

      final response = await api.post('/progress/update', data: updateData);
      if (response['statusCode'] == 200) {
        // đồng bộ lại % từ server
        await loadProgress(userId: 15);

        // lưu log local để vẽ chart/streak
        await _appendCompletionLog(
          subjectCode: subjectCode,
          grade: grade,
          lessonId: lessonId,
          when: DateTime.now(),
        );

        // báo UI refresh chart/streak
        statsVersion.value++;
        return true;
      }

      // Rollback nếu server lỗi
      completedLessons[k]!.remove(lessonId);
      setProgressLocal(
        subjectCode,
        grade,
        totalLessons > 0 ? (completedCount - 1) / totalLessons : 0.0,
      );
      return false;
    } catch (e) {
      return false;
    }
  }

  String mapSubjectToCode(String subject) {
    switch (subject.trim().toLowerCase()) {
      case 'toán':
        return 'toan';
      case 'ngữ văn':
      case 'văn':
        return 'nguvan';
      case 'tiếng anh':
      case 'anh':
        return 'tienganh';
      case 'khoa học tự nhiên':
      case 'khoahoctunhien':
        return 'khoahoctunhien';
      default:
        return subject.toLowerCase();
    }
  }

  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  // =================== STREAK APIs ===================
  /// Đọc toàn bộ ngày đã học (gom mọi completionLog_* trong SharedPreferences)
  Future<Set<DateTime>> loadAllStudyDays() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('completionLog_'));
    final Set<DateTime> days = {};

    for (final key in keys) {
      final list = prefs.getStringList(key) ?? <String>[];
      for (final raw in list) {
        final parts = raw.split('|');
        if (parts.length != 2) continue;
        final ts = int.tryParse(parts[0]) ?? 0;
        if (ts <= 0) continue;
        final d = DateTime.fromMillisecondsSinceEpoch(ts);
        days.add(_dayKey(d));
      }
    }
    return days;
  }

  /// Dùng để TEST: thêm log “đã học” ở một ngày bất kỳ
  Future<void> addFakeStudyLog({
    required String subjectCode,
    required int grade,
    required DateTime day,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _logKey(subjectCode, grade);
    final list = prefs.getStringList(key) ?? <String>[];

    // đặt timestamp giữa trưa để rõ ràng
    final ts =
        DateTime(day.year, day.month, day.day, 12).millisecondsSinceEpoch;
    const fakeLessonId = 999999; // chỉ cần unique
    list.add('$ts|$fakeLessonId');

    await prefs.setStringList(key, list);
    refreshStats(); // ép Dashboard/Streak cập nhật
  }

  /// Ép các widget (FutureBuilder/Obx) refresh lại chart/streak
  void refreshStats() {
    statsVersion.value++;
  }

  /// Tính streak toàn cục
  /// - currentStreak: số ngày liên tiếp tính từ hôm nay lùi lại
  /// - bestStreak: streak dài nhất từng đạt
  /// - totalDays: tổng số ngày từng học
  /// - weekCount: số ngày học trong tuần hiện tại (Mon..Sun)
  Future<({int currentStreak, int bestStreak, int totalDays, int weekCount})>
  computeStreak() async {
    final days = await loadAllStudyDays();
    if (days.isEmpty) {
      return (currentStreak: 0, bestStreak: 0, totalDays: 0, weekCount: 0);
    }

    // Tổng số ngày học
    final totalDays = days.length;

    // ❗ TEST: cố định "today" = 19/09/2025 để kiểm thử.
    // Khi đưa vào production, đổi lại dòng dưới thành:
    // final today = _dayKey(DateTime.now());
    final today = _dayKey(DateTime(2025, 9, 19));

    // Current streak (liên tiếp từ today lùi lại)
    int current = 0;
    var cursor = today;
    while (days.contains(cursor)) {
      current++;
      cursor = _dayKey(cursor.subtract(const Duration(days: 1)));
    }

    // Best streak
    final sorted = days.toList()..sort();
    int best = 1;
    int chain = 1;
    for (int i = 1; i < sorted.length; i++) {
      final prev = sorted[i - 1];
      final cur = sorted[i];
      if (_dayKey(prev.add(const Duration(days: 1))) == cur) {
        chain++;
        if (chain > best) best = chain;
      } else {
        chain = 1;
      }
    }

    // Số ngày trong tuần hiện tại (Mon..Sun)
    final dow = today.weekday; // 1..7
    final monday = _dayKey(today.subtract(Duration(days: dow - 1)));
    final sunday = _dayKey(monday.add(const Duration(days: 6)));
    int weekCount = 0;
    for (final d in days) {
      if (!d.isBefore(monday) && !d.isAfter(sunday)) {
        weekCount++;
      }
    }

    return (
    currentStreak: current,
    bestStreak: best,
    totalDays: totalDays,
    weekCount: weekCount
    );
  }
}
