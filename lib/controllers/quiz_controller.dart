import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class QuizController extends GetxController {
  /// Danh sách chương & bộ đề
  var chapters = <Map<String, dynamic>>[].obs;

  /// Lưu điểm từng quiz: {chapter_setTitle: score}
  var scores = <String, int>{}.obs;

  /// Lưu số câu trả lời đúng từng quiz
  var correctAnswers = <String, int>{}.obs;

  /// Đánh dấu quiz đã hoàn thành
  var completedQuizzes = <String, bool>{}.obs;

  /// Trạng thái loading
  var isLoading = false.obs;

  /// Load dữ liệu quiz từ JSON
  Future<void> loadQuiz(String subject, int grade) async {
    try {
      isLoading.value = true;

      final String response = await rootBundle.loadString('assets/quiz.json');
      final data = json.decode(response) as Map<String, dynamic>;

      /// Lọc quiz theo subject + grade nếu cần
      chapters.value = List<Map<String, dynamic>>.from(data["quiz"])
          .where((chapter) =>
      (chapter["grade"] == grade || chapter["grade"] == null) &&
          (chapter["subject"] == subject || chapter["subject"] == null))
          .toList();

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      print("Lỗi load quiz: $e");
    }
  }

  /// Helper tạo key duy nhất cho mỗi quiz
  String _key(String chapterName, String setTitle) => "${chapterName}_$setTitle";

  /// Lấy điểm của quiz
  int getScore(String chapterName, String setTitle) {
    return scores[_key(chapterName, setTitle)] ?? 0;
  }

  /// Lấy số câu trả lời đúng
  int getCorrectAnswers(String chapterName, String setTitle) {
    return correctAnswers[_key(chapterName, setTitle)] ?? 0;
  }

  /// Kiểm tra quiz đã làm xong chưa
  bool isCompleted(String chapterName, String setTitle) {
    return completedQuizzes[_key(chapterName, setTitle)] ?? false;
  }

  /// Cập nhật kết quả sau khi nộp bài
  void updateResult(
      String chapterName, String setTitle, int score, int correct) {
    final key = _key(chapterName, setTitle);

    scores[key] = score;
    correctAnswers[key] = correct;
    completedQuizzes[key] = true;

    /// Gọi refresh để UI ở quiz_detail_screen tự động cập nhật
    scores.refresh();
    correctAnswers.refresh();
    completedQuizzes.refresh();
    update();
  }

  /// Lấy quiz data theo môn học + lớp
  List<Map<String, dynamic>> getQuizData(int grade, String subject) {
    return chapters
        .where((chapter) =>
    (chapter['grade'] == grade || chapter["grade"] == null) &&
        (chapter['subject'] == subject || chapter["subject"] == null))
        .toList();
  }

  /// Reset kết quả 1 quiz
  void resetQuiz(String chapterName, String setTitle) {
    final key = _key(chapterName, setTitle);
    scores.remove(key);
    correctAnswers.remove(key);
    completedQuizzes.remove(key);

    scores.refresh();
    correctAnswers.refresh();
    completedQuizzes.refresh();
    update();
  }

  /// Reset toàn bộ kết quả quiz
  void resetAll() {
    scores.clear();
    correctAnswers.clear();
    completedQuizzes.clear();

    scores.refresh();
    correctAnswers.refresh();
    completedQuizzes.refresh();
    update();
  }
}
