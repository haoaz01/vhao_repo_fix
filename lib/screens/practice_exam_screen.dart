import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/practice_exam_controller.dart';
import '../model/pdffile_model.dart';
import 'practice_exam_detail_screen.dart';

class PracticeExamScreen extends StatefulWidget {
  final String subject;
  final String grade;
  final PracticeExamController controller;

  const PracticeExamScreen({
    super.key,
    required this.subject,
    required this.grade,
    required this.controller,
  });

  @override
  State<PracticeExamScreen> createState() => _PracticeExamScreenState();
}

class _PracticeExamScreenState extends State<PracticeExamScreen> {
  @override
  void initState() {
    super.initState();
    // Load exams when the screen initializes
    widget.controller.loadExams(widget.subject, widget.grade);
  }

  @override
  void dispose() {
    // Clean up the controller when the screen is disposed
    Get.delete<PracticeExamController>(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bộ đề thi ${widget.subject} lớp ${widget.grade}"),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(() {
          if (widget.controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (widget.controller.errorMessage.isNotEmpty) {
            return Center(
              child: Text(
                widget.controller.errorMessage.value,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (widget.controller.exams.isEmpty) {
            return const Center(
              child: Text("Chưa có đề thi nào cho môn học này"),
            );
          }

          return ListView.builder(
            itemCount: widget.controller.exams.length,
            itemBuilder: (context, index) {
              final PdfFile exam = widget.controller.exams[index];
              return _buildExamItem(exam, context);
            },
          );
        }),
      ),
    );
  }

  Widget _buildExamItem(PdfFile exam, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      child: ListTile(
        leading: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 36),
        title: Text(
          exam.description,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "Loại: ${_getExamTypeName(exam.examType)} - Ngày tải: ${_formatDate(exam.uploadDate)}",
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Get.to(
            () => PracticeExamDetailScreen(fileName: exam.fileName),
            transition: Transition.rightToLeft,
          );
        },
      ),
    );
  }

  String _getExamTypeName(String examType) {
    switch (examType) {
      case 'giuaky':
        return 'Giữa kỳ';
      case 'cuoiky':
        return 'Cuối kỳ';
      default:
        return examType;
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}
