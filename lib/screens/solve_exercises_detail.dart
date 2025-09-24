import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/lesson_model.dart';
import '../model/exercise_model.dart';

class SolveExercisesDetailScreen extends StatelessWidget {
  final Lesson lesson;
  final Color primaryGreen = const Color(0xFF4CAF50);

  const SolveExercisesDetailScreen({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Giải bài tập - ${lesson.title}"),
        backgroundColor: primaryGreen,
      ),
      body: lesson.exercises.isEmpty
          ? Center(
              child: Text(
                "Không có bài tập nào cho bài học này.",
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: lesson.exercises.length,
              itemBuilder: (context, index) {
                final exercise = lesson.exercises[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question
                        Text(
                          "${index + 1}. ${exercise.question}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Solutions
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: exercise.solutions.map((solution) {
                            if (solution.type.toLowerCase() == 'text') {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Text(
                                  "- ${solution.value}",
                                  style: const TextStyle(fontSize: 15),
                                ),
                              );
                            } else if (solution.type.toLowerCase() == 'image') {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Image.network(
                                  solution.value,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      },
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image),
                                ),
                              );
                            } else {
                              return const SizedBox();
                            }
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
