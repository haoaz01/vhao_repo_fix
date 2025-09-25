import 'package:get/get.dart';
import '../api/api_service.dart';

class ProgressController extends GetxController {
  final APIService api = APIService();
  final RxMap<String, double> progressMap = <String, double>{}.obs;
  final RxMap<String, RxSet<int>> completedLessons = <String, RxSet<int>>{}.obs;
  final RxBool isLoading = false.obs;

  String _key(String subjectCode, int grade) => '${subjectCode}_$grade';

  double getProgress(String subjectCode, int grade) =>
      progressMap[_key(subjectCode, grade)] ?? 0.0;

  void setProgressLocal(String subjectCode, int grade, double value) {
    progressMap[_key(subjectCode, grade)] = value.clamp(0.0, 1.0);
    progressMap.refresh();
  }

  // =================== LOAD PROGRESS ===================
  Future<void> loadProgress({required int userId}) async {
    try {
      isLoading.value = true;

      // ✅ đúng endpoint backend
      final response = await api.get('/progress/user/$userId');

      if (response['statusCode'] == 200) {
        final data = response['data'];
        if (data is List) {
          for (var sp in data) {
            final subjectName = sp['subject']?.toString() ?? '';
            final grade = (sp['grade'] as num?)?.toInt() ?? 0;
            final progressPercent =
                (sp['progressPercent'] as num?)?.toDouble() ?? 0.0;

            // map tên môn -> code (vd: "Toán" -> "toan")
            final subjectCode = mapSubjectToCode(subjectName);

            // Backend trả % (0..100), UI dùng 0..1
            setProgressLocal(subjectCode, grade, progressPercent / 100.0);

            final key = _key(subjectCode, grade);
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

  // =================== MARK LESSON COMPLETED ===================
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
      final key = _key(subjectCode, grade);
      if (!completedLessons.containsKey(key)) {
        completedLessons[key] = <int>{}.obs;
      }

      // update local trước để UI mượt
      completedLessons[key]!.add(lessonId);
      final completedCount = completedLessons[key]!.length;
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

      // FIX: bỏ post trùng, chỉ gọi 1 lần và kiểm tra status
      final response = await api.post('/progress/update', data: updateData);
      if (response['statusCode'] == 200) return true;

      // Rollback nếu server lỗi
      completedLessons[key]!.remove(lessonId);
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
}
