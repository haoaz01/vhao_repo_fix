import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'streak_screen.dart';
import '../controllers/progress_controller.dart';
import '../controllers/theory_controller.dart';

void main() {
  runApp(DashboardApp());
}

class DashboardApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Dashboard Screen',
      theme: ThemeData.light(),
      home: DashBoardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DashBoardScreen extends StatelessWidget {
  final ProgressController progressController = Get.put(ProgressController());
  final TheoryController theoryController = Get.put(TheoryController());

  DashBoardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Center(
                  child: Column(
                    children: [
                      const Text(
                        '📊 Dashboard',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tổng quan tiến độ học tập của bạn',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        ProgressHistorySection(),
                        const SizedBox(height: 16),
                        _buildStreakCard(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStreakCard() {
    return GestureDetector(
      onTap: () {
        Get.to(() => StreakScreen());
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.local_fire_department, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    '🔥 Chuỗi Ngày Học Liên Tiếp',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStreakStat('5', 'Ngày liên tiếp'),
                  _buildStreakStat('30', 'Tổng ngày học'),
                  _buildStreakStat('5', 'Tuần này'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }




  Widget _buildStreakStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF667EEA),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class ProgressHistorySection extends StatefulWidget {
  @override
  State<ProgressHistorySection> createState() => _ProgressHistorySectionState();
}

class _ProgressHistorySectionState extends State<ProgressHistorySection> {
  final ProgressController progressController = Get.find<ProgressController>();
  final TheoryController theoryController = Get.find<TheoryController>();

  late int selectedSubjectId;

  // ✅ Fix tên môn đồng bộ với controller + API
  final Map<int, String> subjectNames = {
    1: "Toán",
    2: "Ngữ văn",
    3: "Tiếng Anh",
    4: "Khoa học Tự nhiên",
  };

  @override
  void initState() {
    super.initState();
    selectedSubjectId = 1; // Mặc định chọn môn Toán
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final subjectName = subjectNames[selectedSubjectId]!;
      final subjectCode = progressController.mapSubjectToCode(subjectName);

      // Lọc chapters có lesson thuộc subjectId
      final chapters = theoryController.chapters
          .where((c) => c.lessons.any((l) => l.subjectId == selectedSubjectId))
          .toList();

      // Lấy toàn bộ lessons theo subjectId
      final allLessons = chapters
          .expand((c) => c.lessons.where((l) => l.subjectId == selectedSubjectId))
          .toList();

      // Lấy danh sách bài học đã hoàn thành
      final key = 'completedLessons_${subjectCode}_6'; // grade mặc định = 6
      final completedLessons = theoryController.completedLessonsBySubject[key] ?? <String>{};

      // ✅ Lấy tiến độ % từ ProgressController (đã sync khi toggleComplete)
      double progress = progressController.getProgress(subjectCode, 6);

      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                "📚 Lịch Sử Bài Học",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  labelText: "Chọn môn học",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                value: selectedSubjectId,
                items: subjectNames.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      selectedSubjectId = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: Colors.grey[200],
                color: Colors.green,
                borderRadius: BorderRadius.circular(6),
              ),
              const SizedBox(height: 8),
              Text(
                "Hoàn thành: ${(progress * 100).toStringAsFixed(0)}%",
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: allLessons.length,
                itemBuilder: (_, i) {
                  final lesson = allLessons[i];
                  final isCompleted = completedLessons.contains(lesson.title);
                  return ListTile(
                    leading: Icon(
                      Icons.circle,
                      size: 12,
                      color: isCompleted ? Colors.green : Colors.orange,
                    ),
                    title: Text(
                      lesson.title,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    trailing: isCompleted
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                  );
                },
              ),
            ],
          ),
        ),
      );
    });
  }
}
