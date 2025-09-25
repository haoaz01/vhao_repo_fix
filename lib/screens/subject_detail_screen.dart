import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/routes/app_routes.dart';
import '../controllers/practice_exam_controller.dart';
import '../controllers/theory_controller.dart';
import '../controllers/quiz_controller.dart';
import '../controllers/progress_controller.dart';
import '../screens/practice_exam_screen.dart';

class SubjectDetailScreen extends StatelessWidget {
  final Color primaryGreen = const Color(0xFF4CAF50);
  final int grade;
  final String subject;

  // ❌ (single instance dễ “kẹt” dữ liệu môn cũ)
  // final TheoryController controller =
  //   Get.isRegistered<TheoryController>() ? Get.find<TheoryController>() : Get.put(TheoryController());

  // ✅ Quiz & Progress vẫn giữ như cũ
  final QuizController quizController =
  Get.isRegistered<QuizController>() ? Get.find<QuizController>() : Get.put(QuizController());
  final ProgressController progressController =
  Get.isRegistered<ProgressController>() ? Get.find<ProgressController>() : Get.put(ProgressController());

  SubjectDetailScreen({super.key, int? grade, String? subject})
      : grade = grade ?? (Get.arguments?['grade']),
        subject = subject ?? (Get.arguments?['subject']) {
    // ✅ HƯỚNG B: tạo/lấy TheoryController theo TAG cho combo (subject, grade)
    final tag = 'theory_${this.subject}_${this.grade}';
    if (Get.isRegistered<TheoryController>() && !Get.isRegistered<TheoryController>(tag: tag)) {
      Get.delete<TheoryController>();
    }
    if (!Get.isRegistered<TheoryController>(tag: tag)) {
      Get.put(TheoryController(), tag: tag);
    }
    final TheoryController c = Get.find<TheoryController>(tag: tag);
    // ✅ Load đúng môn/lớp (clear dữ liệu cũ đã làm trong controller)
    c.loadTheory(this.subject, this.grade);
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Lấy lại controller theo tag để dùng trong onTap
    final theoryTag = 'theory_${subject}_$grade';
    final TheoryController controller = Get.find<TheoryController>(tag: theoryTag);

    final List<Map<String, dynamic>> featureCards = [
      {
        "title": "Lý thuyết",
        "icon": Icons.menu_book_rounded,
        "color": Colors.blue,
        "onTap": () async {
          await controller.loadTheory(subject, grade);
          Get.toNamed(
            AppRoutes.theory,
            arguments: {
              'subject': subject,
              'grade': grade,
              // ✅ TRUYỀN TAG để các màn con (LessonDetailScreen) lấy đúng controller
              'theoryTag': theoryTag,
              // 'userId': 15, // nếu cần
            },
          );
        },
      },
      {
        "title": "Giải bài tập",
        "icon": Icons.edit_document,
        "color": Colors.green,
        "onTap": () {
          Get.toNamed(AppRoutes.theory, arguments: {
            'subject': subject,
            'grade': grade,
            'mode': 'exercise',
            // ✅ vẫn truyền tag để màn con đọc đúng instance nếu cần
            'theoryTag': theoryTag,
          });
        },
      },
      {
        "title": "Quiz",
        "icon": Icons.quiz_rounded,
        "color": Colors.orange,
        "onTap": () async {
          await quizController.loadQuiz(subject, grade);
          Get.toNamed(AppRoutes.quizDetail, arguments: {
            'subject': subject,
            'grade': grade,
          });
        },
      },
      {
        "title": "Bộ đề thi",
        "icon": Icons.article_rounded,
        "color": Colors.purple,
        "onTap": () {
          final tag = '${subject}_$grade';
          Get.create<PracticeExamController>(() => PracticeExamController(), tag: tag);
          final controller = Get.find<PracticeExamController>(tag: tag);

          Get.to(() => PracticeExamScreen(
            subject: subject,
            grade: grade.toString(),
            controller: controller,
          ));
        },
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text("Khối $grade - $subject"),
        backgroundColor: primaryGreen,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$subject cho Khối $grade",
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text("Chọn nội dung bạn muốn học bên dưới:", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 24),

            Expanded(
              child: GridView.builder(
                itemCount: featureCards.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (context, index) {
                  final card = featureCards[index];
                  final color = card["color"] as MaterialColor;
                  return InkWell(
                    onTap: card["onTap"] as void Function()?,
                    borderRadius: BorderRadius.circular(18),
                    splashColor: color.withOpacity(0.2),
                    highlightColor: Colors.white.withOpacity(0.1),
                    child: Card(
                      elevation: 6,
                      shadowColor: color.withOpacity(0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color.withOpacity(0.15),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Icon(card["icon"] as IconData, size: 38, color: color),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              card["title"] as String,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color.shade700),
                            ),

                            // Progress chỉ cho "Lý thuyết"
                            if (card["title"] == "Lý thuyết") ...[
                              const SizedBox(height: 12),
                              Obx(() {
                                final progress = progressController.getProgress(
                                  progressController.mapSubjectToCode(subject),
                                  grade,
                                );
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 8,
                                      backgroundColor: color.withOpacity(0.2),
                                      color: color,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${(progress * 100).toStringAsFixed(0)}% Hoàn thành",
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
