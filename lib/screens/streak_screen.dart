import 'package:get/get.dart';
import '../controllers/progress_controller.dart';
import 'package:flutter/material.dart';

class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  final ProgressController progressController = Get.find<ProgressController>();

  late DateTime now;
  Set<DateTime> studyDays = {};
  late int currentMonth;
  late int currentYear;

  // Helper: chuẩn hoá về 00:00 để so sánh ngày
  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();

    now = DateTime(2025, 9, 19);





    // thêm log giả: học vào các ngày trước hôm nay
    final pc = Get.find<ProgressController>();
    pc.addFakeStudyLog(subjectCode: 'toan', grade: 7, day: now.subtract(const Duration(days: 1)));
    pc.addFakeStudyLog(subjectCode: 'toan', grade: 7, day: now.subtract(const Duration(days: 2)));
    pc.addFakeStudyLog(subjectCode: 'toan', grade: 7, day: now.subtract(const Duration(days: 5)));





    // 1) "Hôm nay" — nếu muốn test ngày 19/09/2025 thì bỏ comment dòng dưới:
    // now = DateTime(2025, 9, 19);
    now = DateTime.now();

    // 2) PHẢI gán 2 biến late trước khi build
    currentMonth = now.month;
    currentYear  = now.year;

    // 3) Tải log các ngày đã học (toàn cục)
    _loadData();
  }

  Future<void> _loadData() async {
    // ❗ Dùng hàm public đã thêm trong ProgressController:
    // Future<Set<DateTime>> readStudyDays() => _loadAllStudyDays();
    final days = await progressController.readStudyDays();
    // Chuẩn hoá về 00:00
    final normalized = days.map(_dayKey).toSet();

    if (mounted) {
      setState(() {
        studyDays = normalized;
      });
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      currentMonth += offset;
      if (currentMonth < 1) {
        currentMonth = 12;
        currentYear--;
      } else if (currentMonth > 12) {
        currentMonth = 1;
        currentYear++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(currentYear, currentMonth + 1, 0).day;

    // ✅ Đếm đúng số NGÀY đã học trong tháng đang xem (không phải tất cả ngày ≤ hôm nay)
    final learnedDaysThisMonth = studyDays.where(
          (d) => d.year == currentYear && d.month == currentMonth,
    ).length;

    // Dải tuần hiện tại (Mon..Sun) theo biến now
    final todayKey = _dayKey(now);
    final monday = _dayKey(todayKey.subtract(Duration(days: todayKey.weekday - 1)));
    final weekDays = List<DateTime>.generate(7, (i) => _dayKey(monday.add(Duration(days: i))));
    final labels = const ["T2", "T3", "T4", "T5", "T6", "T7", "CN"];

    return Scaffold(
      backgroundColor: Colors.purple[50],
      appBar: AppBar(
        backgroundColor: Colors.purple,
        title: const Text("🔥 Chuỗi Ngày Học", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          // --- CHUỖI NGÀY TRONG TUẦN ---
          Card(
            color: Colors.purple[100],
            margin: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    "📅 Chuỗi ngày tuần này",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple[900]),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(7, (i) {
                      final day = weekDays[i];
                      final learned = studyDays.contains(day);
                      final isToday = day == todayKey;
                      return _buildStreakDay(labels[i], learned, isToday: isToday);
                    }),
                  ),
                ],
              ),
            ),
          ),

          // --- LỊCH THEO THÁNG ---
          Card(
            color: Colors.purple[100],
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thanh tiêu đề có nút chuyển tháng
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.purple),
                        onPressed: () => _changeMonth(-1),
                      ),
                      Text(
                        "Tháng ${currentMonth.toString().padLeft(2, '0')} - $currentYear",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple[900]),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, color: Colors.purple),
                        onPressed: () => _changeMonth(1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "✅ Đã học: $learnedDaysThisMonth / $daysInMonth ngày",
                    style: TextStyle(fontSize: 14, color: Colors.purple[800], fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7, // 7 ngày/tuần
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: daysInMonth,
                    itemBuilder: (context, dayIndex) {
                      final day = dayIndex + 1;
                      final currentDate = _dayKey(DateTime(currentYear, currentMonth, day));

                      // ✅ Đã học nếu currentDate nằm trong set studyDays
                      final isLearned = studyDays.contains(currentDate);
                      final isToday = currentDate == todayKey;

                      return Container(
                        decoration: BoxDecoration(
                          color: isLearned ? Colors.orange : Colors.grey[300],
                          shape: BoxShape.circle,
                          border: isToday ? Border.all(color: Colors.purple, width: 2.5) : null,
                        ),
                        child: Center(
                          child: isLearned
                              ? const Icon(Icons.local_fire_department, color: Colors.white, size: 18)
                              : Text("$day", style: const TextStyle(color: Colors.black, fontSize: 12)),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakDay(String label, bool learned, {bool isToday = false}) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: learned ? Colors.orange : Colors.grey[300],
            shape: BoxShape.circle,
            border: isToday ? Border.all(color: Colors.purple, width: 3) : null,
          ),
          child: learned
              ? const Icon(Icons.local_fire_department, color: Colors.white, size: 20)
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            color: isToday ? Colors.purple[900] : Colors.black,
          ),
        ),
      ],
    );
  }
}
