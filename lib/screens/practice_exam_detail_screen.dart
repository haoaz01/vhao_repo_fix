import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../controllers/pdf_controller.dart';

class PracticeExamDetailScreen extends StatelessWidget {
  final String fileName;
  final PdfController controller;

  PracticeExamDetailScreen({super.key, required this.fileName})
    : controller = Get.put(PdfController(fileName));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(fileName),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // Implement download functionality if needed
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.isNotEmpty) {
          return Center(
            child: Text(
              controller.errorMessage.value,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (controller.pdfBytes.value.isEmpty) {
          return const Center(child: Text("Không thể tải tệp PDF"));
        }

        return SfPdfViewer.memory(
          controller.pdfBytes.value,
          canShowScrollHead: true,
          canShowScrollStatus: true,
        );
      }),
    );
  }
}
