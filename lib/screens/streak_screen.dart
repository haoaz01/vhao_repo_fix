import 'package:flutter/material.dart';

class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  DateTime now = DateTime(2025, 9, 19); // Ngày giới hạn học
  late int currentMonth;
  late int currentYear;

  @override
  void initState() {
    super.initState();
    currentMonth = now.month;
    currentYear = now.year;
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
    int daysInMonth = DateTime(currentYear, currentMonth + 1, 0).day;

    // Đếm số ngày đã học trong tháng này
    int learnedDays = 0;
    for (int d = 1; d <= daysInMonth; d++) {
      DateTime date = DateTime(currentYear, currentMonth, d);
      if (date.isBefore(now) || date.isAtSameMomentAs(now)) {
        learnedDays++;
      }
    }

    return Scaffold(
      backgroundColor: Colors.purple[50],
      appBar: AppBar(
        backgroundColor: Colors.purple,
        title: const Text("🔥 Chuỗi Ngày Học",
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          // --- CHUỖI NGÀY TRONG TUẦN ---
          Card(
            color: Colors.purple[100],
            margin: const EdgeInsets.all(12),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    "📅 Chuỗi ngày tuần này",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[900]),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStreakDay("T2", true),
                      _buildStreakDay("T3", true),
                      _buildStreakDay("T4", true),
                      _buildStreakDay("T5", true),
                      _buildStreakDay("T6", true),
                      _buildStreakDay("T7", false),
                      _buildStreakDay("CN", true, isToday: true),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // --- LỊCH THEO THÁNG (1 tháng + điều hướng) ---
          Card(
            color: Colors.purple[100],
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                        icon: const Icon(Icons.arrow_back_ios,
                            color: Colors.purple),
                        onPressed: () => _changeMonth(-1),
                      ),
                      Text(
                        "Tháng ${currentMonth.toString().padLeft(2, '0')} - $currentYear",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple[900]),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios,
                            color: Colors.purple),
                        onPressed: () => _changeMonth(1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "✅ Đã học: $learnedDays / $daysInMonth ngày",
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.purple[800],
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),

                  // Lịch dạng lưới
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7, // 7 ngày/tuần
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: daysInMonth,
                    itemBuilder: (context, dayIndex) {
                      int day = dayIndex + 1;
                      DateTime currentDate =
                      DateTime(currentYear, currentMonth, day);

                      bool isLearned = currentDate.isBefore(now) ||
                          currentDate.isAtSameMomentAs(now);

                      return Container(
                        decoration: BoxDecoration(
                          color: isLearned ? Colors.orange : Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isLearned
                              ? const Icon(Icons.local_fire_department,
                              color: Colors.white, size: 18)
                              : Text(
                            "$day",
                            style: const TextStyle(
                                color: Colors.black, fontSize: 12),
                          ),
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
            border:
            isToday ? Border.all(color: Colors.purple, width: 3) : null,
          ),
          child: learned
              ? const Icon(Icons.local_fire_department,
              color: Colors.white, size: 20)
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              color: isToday ? Colors.purple[900] : Colors.black),
        ),
      ],
    );
  }
}
