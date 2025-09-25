import 'package:get/get.dart';
import '../api/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum StatsRange { day, week, month }

class ProgressController extends GetxController {
  final APIService api = APIService();

  // ===== User & Grade =====
  // set khi user login
  final RxInt currentUserId = 0.obs;

  static const _selectedGradeKey = 'selected_grade';
  // grade mặc định; sẽ được load từ SharedPreferences trong onInit()
  final RxInt selectedGrade = 7.obs;

  // Trigger cho Dashboard/Chart/Streak UI
  final RxInt statsVersion = 0.obs;

  // % theo môn/lớp cho user đang dùng (key: subjectCode_grade)
  final RxMap<String, double> progressMap = <String, double>{}.obs;

  // Số lesson hoàn thành (key: subjectCode_grade)
  final RxMap<String, RxSet<int>> completedLessons = <String, RxSet<int>>{}.obs;

  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // nạp grade đã lưu (fire-and-forget)
    loadSelectedGrade();
  }

  // ---- User / Grade ----
  void setCurrentUser(int userId) {
    if (currentUserId.value != userId) {
      currentUserId.value = userId;
      // Khi đổi user, nên clear cache in-memory để không hiển thị nhầm:
      progressMap.clear();
      completedLessons.clear();
      // Tuỳ app flow, bạn có thể gọi loadProgress(userId: userId) ngay sau khi set
    }
  }

  Future<void> loadSelectedGrade() async {
    final prefs = await SharedPreferences.getInstance();
    final g = prefs.getInt(_selectedGradeKey);
    if (g != null && g > 0) {
      selectedGrade.value = g;
    }
  }

  Future<void> setSelectedGrade(int grade) async {
    selectedGrade.value = grade;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_selectedGradeKey, grade);
  }

  // ===== Key helpers =====
  String _key(String subjectCode, int grade) => '${subjectCode}_$grade';

  // !!! ĐÃ THÊM userId vào log key để tách theo user !!!
  String _userLogKey(int userId, String subjectCode, int grade) =>
      'completionLog_u${userId}_${subjectCode}_$grade';

  // log cũ (không có user) vẫn đọc được như fallback nếu cần
  String _legacyLogKey(String subjectCode, int grade) =>
      'completionLog_${subjectCode}_$grade';

  String _encodeLog(DateTime when, int lessonId) =>
      '${when.millisecondsSinceEpoch}|$lessonId';

  ({DateTime when, int lessonId})? _decodeLog(String raw) {
    final parts = raw.split('|');
    if (parts.length != 2) return null;
    final ts = int.tryParse(parts[0]) ?? 0;
    final id = int.tryParse(parts[1]) ?? 0;
    if (ts <= 0 || id == 0) return null;
    return (when: DateTime.fromMillisecondsSinceEpoch(ts), lessonId: id);
  }

  // =================== CHART STATS (logs per user) ===================
  Future<Map<DateTime, int>> getCompletionStats({
    required String subjectCode,
    required int grade,
    required StatsRange range,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = currentUserId.value;

    // Ưu tiên đọc log theo user
    final key = _userLogKey(userId, subjectCode, grade);
    var list = prefs.getStringList(key) ?? <String>[];

    // Fallback 1: nếu chưa có log đúng grade, gom toàn bộ log của môn (mọi grade) nhưng vẫn theo user
    if (list.isEmpty) {
      final prefix = 'completionLog_u${userId}_${subjectCode}_';
      final allKeys = prefs.getKeys().where((k) => k.startsWith(prefix));
      final merged = <String>[];
      for (final k in allKeys) {
        merged.addAll(prefs.getStringList(k) ?? const <String>[]);
      }
      list = merged;
    }

    // Fallback 2: nếu vẫn trống (user mới), thử legacy keys (không có user)
    if (list.isEmpty) {
      final legacy = _legacyLogKey(subjectCode, grade);
      list = prefs.getStringList(legacy) ?? <String>[];
    }

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

    // Tạo buckets lùi về quá khứ
    final Map<DateTime, int> buckets = {};
    var cursor = bucketStart(now);
    for (int i = 0; i < bucketCount; i++) {
      buckets[cursor] = 0;
      cursor = bucketStart(cursor.subtract(step));
    }

    // Đổ log vào bucket
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

  // =================== PROGRESS (in-memory per current user) ===================
  double getProgress(String subjectCode, int grade) =>
      progressMap[_key(subjectCode, grade)] ?? 0.0;

  void setProgressLocal(String subjectCode, int grade, double value) {
    progressMap[_key(subjectCode, grade)] = value.clamp(0.0, 1.0);
    progressMap.refresh();
  }

  // Lấy % cao nhất của môn (mọi grade) cho UI tổng quan
  double getProgressAnyGrade(String subjectCode) {
    final prefix = '${subjectCode}_';
    final vals = progressMap.entries
        .where((e) => e.key.startsWith(prefix))
        .map((e) => e.value)
        .toList();
    if (vals.isEmpty) return 0.0;
    vals.sort((a, b) => b.compareTo(a));
    return vals.first;
  }

  // Tìm grade có % cao nhất cho 1 môn
  int? getBestGradeFor(String subjectCode) {
    final prefix = '${subjectCode}_';
    int? bestGrade;
    double bestVal = -1;
    for (final e in progressMap.entries) {
      if (!e.key.startsWith(prefix)) continue;
      final parts = e.key.split('_'); // [subjectCode, grade]
      if (parts.length != 2) continue;
      final g = int.tryParse(parts[1]) ?? -1;
      if (e.value > bestVal) {
        bestVal = e.value;
        bestGrade = g;
      }
    }
    return bestGrade;
  }

  // =================== LOAD PROGRESS (API) ===================
  // - Merge % server + local (max) để không bị hụt
  // - Gieo 1 log theo updatedAt để biểu đồ có cột ngay sau đăng nhập
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
            final key = _key(subjectCode, grade);

            final serverVal = (progressPercent / 100.0).clamp(0.0, 1.0);
            final localVal  = progressMap[key] ?? 0.0;
            final mergedVal = serverVal > localVal ? serverVal : localVal;
            setProgressLocal(subjectCode, grade, mergedVal);

            // gieo log từ updatedAt (để chart có cột)
            final updatedAtRaw = sp['updatedAt']?.toString();
            if (updatedAtRaw != null && updatedAtRaw.isNotEmpty && mergedVal > 0) {
              DateTime? updatedAt;
              try { updatedAt = DateTime.tryParse(updatedAtRaw); } catch (_) {}
              if (updatedAt != null) {
                await _ensureLogForUpdatedAt(
                  subjectCode: subjectCode,
                  grade: grade,
                  updatedAt: updatedAt,
                );
              }
            }

            // init completed set nếu chưa có
            if (!completedLessons.containsKey(key)) {
              completedLessons[key] = <int>{}.obs;
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

  // =================== UPDATE PROGRESS (API) ===================
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

      // Update local trước để UI mượt
      completedLessons[k]!.add(lessonId);
      final completedCount = completedLessons[k]!.length;
      final progress = totalLessons > 0 ? completedCount / totalLessons : 0.0;
      final currentLocal = getProgress(subjectCode, grade);
      setProgressLocal(
        subjectCode,
        grade,
        progress > currentLocal ? progress : currentLocal,
      );

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
        // đồng bộ lại % từ server nhưng không cho tụt
        final before = getProgress(subjectCode, grade);
        await loadProgress(userId: userId);
        final afterServer = getProgress(subjectCode, grade);
        if (afterServer < before) {
          setProgressLocal(subjectCode, grade, before);
        }

        // lưu log local (per user) để vẽ chart/streak
        await _appendCompletionLogForUser(
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
      final newCount = completedLessons[k]!.length;
      setProgressLocal(
        subjectCode,
        grade,
        totalLessons > 0 ? newCount / totalLessons : 0.0,
      );
      return false;
    } catch (e) {
      return false;
    }
  }

  // =================== SUBJECT NAME -> CODE ===================
  String mapSubjectToCode(String subject) {
    final raw = subject.trim().toLowerCase();

    // các biến thể thường gặp từ backend
    if (raw.contains('toán') || raw.contains('toan')) return 'toan';
    if (raw.contains('ngữ văn') || raw.contains('ngu van') || raw == 'văn' || raw == 'van') {
      return 'nguvan';
    }
    if (raw.contains('tiếng anh') || raw.contains('tieng anh') || raw == 'anh') {
      return 'tienganh';
    }
    if (raw.contains('khoa học tự nhiên') ||
        raw.contains('khoa hoc tu nhien') ||
        raw.contains('khtn')) {
      return 'khoahoctunhien';
    }
    // fallback: bỏ khoảng trắng
    return raw.replaceAll(' ', '');
  }

  // =================== STREAK / DATES ===================
  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _appendCompletionLogForUser({
    required String subjectCode,
    required int grade,
    required int lessonId,
    required DateTime when,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = currentUserId.value;
    final key = _userLogKey(userId, subjectCode, grade);
    final list = prefs.getStringList(key) ?? <String>[];
    list.add(_encodeLog(when, lessonId));
    await prefs.setStringList(key, list);
  }

  Future<void> _ensureLogForUpdatedAt({
    required String subjectCode,
    required int grade,
    required DateTime updatedAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = currentUserId.value;
    final key = _userLogKey(userId, subjectCode, grade);
    final list = prefs.getStringList(key) ?? <String>[];

    // kiểm tra đã có log cùng ngày chưa
    final day = _dayKey(updatedAt);
    bool exists = false;
    for (final raw in list) {
      final parts = raw.split('|');
      if (parts.length != 2) continue;
      final ts = int.tryParse(parts[0]) ?? 0;
      if (ts <= 0) continue;
      final d = _dayKey(DateTime.fromMillisecondsSinceEpoch(ts));
      if (d == day) { exists = true; break; }
    }
    if (exists) return;

    // gieo 1 log “giả” vào giữa trưa ngày updatedAt
    final ts = DateTime(day.year, day.month, day.day, 12).millisecondsSinceEpoch;
    const pseudoLessonId = -1; // đánh dấu là từ server
    list.add('$ts|$pseudoLessonId');
    await prefs.setStringList(key, list);

    // báo UI refresh
    statsVersion.value++;
  }

  /// Đọc toàn bộ ngày đã học (chỉ của user hiện tại)
  Future<Set<DateTime>> loadAllStudyDays() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = currentUserId.value;
    final prefix = 'completionLog_u${userId}_'; // chỉ quét log của user này
    final keys = prefs.getKeys().where((k) => k.startsWith(prefix));

    final Set<DateTime> days = {};
    for (final key in keys) {
      final list = prefs.getStringList(key) ?? <String>[];
      for (final raw in list) {
        final entry = _decodeLog(raw);
        if (entry == null) continue;
        days.add(_dayKey(entry.when));
      }
    }
    return days;
  }

  void refreshStats() {
    statsVersion.value++;
  }

  //  COMPUTE STREAK
  Future<({int currentStreak, int bestStreak, int totalDays, int weekCount})>
  computeStreak() async {
    final days = await loadAllStudyDays();
    if (days.isEmpty) {
      return (currentStreak: 0, bestStreak: 0, totalDays: 0, weekCount: 0);
    }

    final totalDays = days.length;
    final today = _dayKey(DateTime.now()); // Production

    // Current streak
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

    // Tuần hiện tại (Mon..Sun)
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

  // public alias (giữ tương thích)
  Future<Set<DateTime>> readStudyDays() => loadAllStudyDays();
}
