import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/routes/app_routes.dart';
import '../controllers/theory_controller.dart';

class TheoryScreen extends StatelessWidget {
  final String subject;
  final int grade;
  final String mode; // 'theory' hoặc 'exercise'
  final Color primaryGreen = const Color(0xFF4CAF50);

  TheoryScreen({super.key, required this.subject, required this.grade})
    : mode = Get.arguments?['mode'] ?? 'theory';

  @override
  Widget build(BuildContext context) {
    // Chỉ khởi tạo 1 lần controller
    final TheoryController controller = Get.put(
      TheoryController(),
      permanent: true,
    );

    // Load theory 1 lần sau init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadTheory(subject, grade);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          mode == 'theory'
              ? "Lý thuyết $subject - Khối $grade"
              : "Giải bài tập $subject - Khối $grade",
        ),
        backgroundColor: primaryGreen,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.chapters.isEmpty) {
          return const Center(child: Text("Không có dữ liệu"));
        }

        return ListView.builder(
          itemCount: controller.chapters.length,
          itemBuilder: (context, index) {
            final chapter = controller.chapters[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: primaryGreen,
                  child: Text(
                    "${index + 1}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                title: Text(
                  chapter.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                children: chapter.lessons.map((lesson) {
                  final isDone = controller.isCompleted(lesson.title);

                  return ListTile(
                    leading: Hero(
                      tag: lesson.title,
                      child: Icon(
                        Icons.menu_book,
                        color: isDone ? primaryGreen : Colors.blue,
                      ),
                    ),
                    title: Text(
                      lesson.title,
                      style: TextStyle(
                        color: isDone ? primaryGreen : Colors.black87,
                        fontWeight: isDone ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    trailing: Icon(
                      isDone ? Icons.check_circle : Icons.arrow_forward_ios,
                      color: isDone ? Colors.green : Colors.grey,
                    ),
                    onTap: () {
                      final route = mode == 'theory'
                          ? AppRoutes.lessonDetail
                          : AppRoutes.solveExercisesDetail;

                      Get.toNamed(route, arguments: {'lesson': lesson});
                    },
                  );
                }).toList(),
              ),
            );
          },
        );
      }),
    );
  }
}
