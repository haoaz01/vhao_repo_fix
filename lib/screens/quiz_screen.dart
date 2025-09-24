import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:get/get.dart';
import '../controllers/quiz_controller.dart';
import '../widgets/inline_latex_text.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final QuizController quizController = Get.find<QuizController>();

  late String chapterName;
  late String setTitle;
  late List<dynamic> questions;

  int currentQuestion = 0;
  Map<int, int> selectedAnswers = {}; // questionIndex -> selectedOptionIndex
  bool isSubmitted = false;

  late int remainingSeconds;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>;
    chapterName = args['chapterName'];
    setTitle = args['setTitle'];
    questions = args['questions'];

    // ⏳ Xác định thời gian dựa theo tiêu đề bộ đề
    if (setTitle.toLowerCase().contains("15p")) {
      remainingSeconds = 15 * 60;
    } else if (setTitle.toLowerCase().contains("30p")) {
      remainingSeconds = 30 * 60;
    } else {
      remainingSeconds = 20 * 60; // mặc định 20 phút nếu không có thông tin
    }

    startTimer();
  }

  /// Bộ đếm thời gian
  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds <= 0) {
        timer.cancel();
        if (!isSubmitted) {
          _submitQuiz(autoSubmit: true);
        }
      } else {
        setState(() {
          remainingSeconds--;
        });
      }
    });
  }

  /// Định dạng thời gian mm:ss
  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int sec = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  /// Tính điểm & cập nhật QuizController
  void _submitQuiz({bool autoSubmit = false}) {
    int correct = 0;
    for (int i = 0; i < questions.length; i++) {
      if (selectedAnswers[i] == questions[i]['answer']) {
        correct++;
      }
    }
    int score = ((correct / questions.length) * 10).round();

    quizController.updateResult(chapterName, setTitle, score, correct);

    setState(() {
      isSubmitted = true;
      timer?.cancel();
    });

    // Hiển thị thông báo
    Get.snackbar(
      autoSubmit ? "Hết giờ!" : "Hoàn thành",
      "Bạn đúng $correct / ${questions.length} câu. Điểm: $score",
      snackPosition: SnackPosition.TOP,
      backgroundColor: autoSubmit ? Colors.red.shade600 : Colors.green.shade600,
      colorText: Colors.white,
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentQ = questions[currentQuestion];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          setTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade600,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                formatTime(remainingSeconds),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: remainingSeconds <= 30 ? Colors.red : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Câu hỏi số
            Text(
              "Câu ${currentQuestion + 1}/${questions.length}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            // Nội dung câu hỏi (dùng InlineLatexText để giữ font tiếng Việt cho phần plain)
            InlineLatexText(
              text: currentQ['question'] as String,
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
            const SizedBox(height: 20),

            // Danh sách đáp án
            Expanded(
              child: ListView.builder(
                itemCount: (currentQ['options'] as List).length,
                itemBuilder: (context, index) {
                  final option = (currentQ['options'] as List)[index] as String;
                  final selected = selectedAnswers[currentQuestion] == index;
                  final isCorrect = (currentQ['answer'] as int) == index;

                  Color borderColor = Colors.grey.shade400;
                  Color textColor = Colors.black;

                  if (isSubmitted) {
                    if (isCorrect) {
                      borderColor = Colors.green;
                      textColor = Colors.green;
                    } else if (selected) {
                      borderColor = Colors.red;
                      textColor = Colors.red;
                    }
                  } else if (selected) {
                    borderColor = Colors.blue.shade400;
                    textColor = Colors.blue.shade600;
                  }

                  return GestureDetector(
                    onTap: isSubmitted
                        ? null
                        : () {
                            setState(() {
                              selectedAnswers[currentQuestion] = index;
                            });
                          },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: 2),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: isSubmitted
                                ? (isCorrect
                                      ? Colors.green
                                      : selected
                                      ? Colors.red
                                      : Colors.grey)
                                : selected
                                ? Colors.blue
                                : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          // Dùng InlineLatexText để render option (có hoặc không có LaTeX)
                          Expanded(
                            child: InlineLatexText(
                              text: option,
                              fontSize: 16,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // Điều hướng + Nộp bài
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: currentQuestion > 0
                      ? () {
                          setState(() {
                            currentQuestion--;
                          });
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade400,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text("Trước"),
                ),
                ElevatedButton(
                  onPressed: currentQuestion < questions.length - 1
                      ? () {
                          setState(() {
                            currentQuestion++;
                          });
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade400,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text("Tiếp"),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Nút nộp bài
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSubmitted
                    ? null
                    : () {
                        if (selectedAnswers.length < questions.length) {
                          Get.snackbar(
                            "Thông báo",
                            "Vui lòng trả lời tất cả các câu hỏi!",
                            snackPosition: SnackPosition.TOP,
                            backgroundColor: Colors.orange,
                            colorText: Colors.white,
                          );
                          return;
                        }
                        _submitQuiz();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSubmitted
                      ? Colors.grey.shade400
                      : Colors.green.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  isSubmitted ? "Đã nộp bài" : "Nộp bài",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
