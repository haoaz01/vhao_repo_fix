import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/chapter_model.dart';
import '../repositories/subject_repository.dart';
import './progress_controller.dart';

class TheoryController extends GetxController {
  final SubjectRepository repository = SubjectRepository();
  final ProgressController progressController = Get.find<ProgressController>();

  final RxBool isLoading = false.obs;
  final RxList<Chapter> chapters = <Chapter>[].obs;
  final RxMap<String, Set<String>> completedLessonsBySubject = <String, Set<String>>{}.obs;

  late String subject;
  late int grade;
  late int userId;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments ?? {};
    subject = args['subject'] ?? 'Toán';
    grade   = args['grade'] ?? 7;
    userId  = args['userId'] ?? 15;

    _loadAllCompletedLessons();
    // loadTheory(subject, grade);
    progressController.loadProgress(userId: userId);

    ever(completedLessonsBySubject, (_) => _updateProgress(subject, grade));
  }

  /// Kiểm tra lesson đã hoàn thành
  bool isCompleted(String lessonTitle) {
    final key = _getStorageKey(subject, grade);
    return completedLessonsBySubject[key]?.contains(lessonTitle) ?? false;
  }

  /// Load chapters từ backend
  Future<void> loadTheory(String subject, int grade) async {
    try {
      isLoading.value = true;
      final code = _mapSubjectToCode(subject);
      final data = await repository.fetchTheory(code, grade);
      chapters.value = data;

      _updateProgress(subject, grade); // update progress ngay khi load xong
    } catch (e) {
      Get.snackbar('Lỗi tải dữ liệu', 'Không thể tải môn $subject: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load tất cả completed lessons từ SharedPreferences
  Future<void> _loadAllCompletedLessons() async {
    final prefs = await SharedPreferences.getInstance();
    for (var key in prefs.getKeys()) {
      if (key.startsWith('completedLessons_')) {
        completedLessonsBySubject[key] = (prefs.getStringList(key) ?? []).toSet();
      }
    }
  }

  /// Toggle hoàn thành lesson
  Future<void> toggleComplete({
    required String lessonTitle,
    required int lessonId,
    required int subjectId,
  }) async {
    final key = _getStorageKey(subject, grade);
    completedLessonsBySubject[key] ??= <String>{};

    final wasCompleted = completedLessonsBySubject[key]!.contains(lessonTitle);
    if (wasCompleted) {
      completedLessonsBySubject[key]!.remove(lessonTitle);
    } else {
      completedLessonsBySubject[key]!.add(lessonTitle);

      final totalLessons = chapters.fold(0, (sum, c) => sum + c.lessons.length);

      // Gọi API backend để đánh dấu lesson hoàn thành
      final ok = await progressController.markLessonCompleted(
        userId: userId,
        subjectName: subject,   // tên hiển thị: Toán / Ngữ văn...
        grade: grade,
        lessonId: lessonId,
        totalLessons: totalLessons,
        subjectId: subjectId,
      );if (!ok) {
        // rollback UI local nếu bạn muốn
      }
    }

    await _saveCompletedLessons(subject, grade);
    completedLessonsBySubject.refresh();
    _updateProgress(subject, grade);
  }

  /// Update progress
  void _updateProgress(String subject, int grade) {
    final key = _getStorageKey(subject, grade);
    final completed = completedLessonsBySubject[key] ?? {};
    final total = chapters.fold(0, (sum, c) => sum + c.lessons.length);
    final done = chapters.fold(
      0,
          (sum, c) => sum + c.lessons.where((l) => completed.contains(l.title)).length,
    );

    final progress = total > 0 ? done / total : 0.0;
    progressController.setProgressLocal(_mapSubjectToCode(subject), grade, progress);
  }

  /// Save completed lessons vào SharedPreferences
  Future<void> _saveCompletedLessons(String subject, int grade) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getStorageKey(subject, grade);
    await prefs.setStringList(key, completedLessonsBySubject[key]?.toList() ?? []);
  }

  /// Map tên môn sang code chuẩn
  String _mapSubjectToCode(String subject) {
    switch (subject.toLowerCase().trim()) {
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

  /// Key cho SharedPreferences
  String _getStorageKey(String subject, int grade) =>
      'completedLessons_${_mapSubjectToCode(subject)}_$grade';
}
