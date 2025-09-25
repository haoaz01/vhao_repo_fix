import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'streak_screen.dart';
import '../controllers/progress_controller.dart';
import '../controllers/theory_controller.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';


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
    final progressController = Get.find<ProgressController>();



    return GestureDetector(
      onTap: () {
        Get.to(() => StreakScreen());
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<
              ({int currentStreak, int bestStreak, int totalDays, int weekCount})>(
            // mỗi lần statsVersion đổi (khi hoàn thành bài), rebuild dữ liệu
            key: ValueKey(progressController.statsVersion.value),
            future: progressController.computeStreak(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(
                  height: 90,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final data = snapshot.data!;
              return Column(
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
                      _buildStreakStat('${data.currentStreak}', 'Ngày liên tiếp'),
                      _buildStreakStat('${data.totalDays}', 'Tổng ngày học'),
                      _buildStreakStat('${data.weekCount}', 'Tuần này'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.emoji_events, size: 18, color: Colors.amber),
                      const SizedBox(width: 6),
                      Text('Kỷ lục: ${data.bestStreak} ngày',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              );
            },
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
  // mặc định xem theo tuần
  StatsRange range = StatsRange.week;

  final ProgressController progressController = Get.find<ProgressController>();
  // Không cần TheoryController cho chart => nếu bạn đã put ở trên vẫn OK, nhưng ở đây không dùng

  // ✅ subjectId khớp backend
  final Map<int, String> subjectNames = const {
    1: "Toán",
    2: "Ngữ văn",
    3: "Tiếng Anh",
    4: "Khoa học Tự nhiên",
  };

  // màu cho từng môn
  final Map<int, Color> subjectColors = const {
    1: Colors.blue,
    2: Colors.orange,
    3: Colors.purple,
    4: Colors.green,
  };

  int selectedSubjectId = 1; // mặc định Toán
  int selectedGrade = 7;     // tuỳ bạn bind theo lớp chọn

  @override
  void initState() {
    super.initState();
    // Đảm bảo có % progress để đồng bộ UI (không ảnh hưởng chart local)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (progressController.progressMap.isEmpty &&
          !progressController.isLoading.value) {
        await progressController.loadProgress(userId: 15);
      }
      setState(() {}); // refresh lần đầu
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final subjectName = subjectNames[selectedSubjectId]!;
      final subjectCode = progressController.mapSubjectToCode(subjectName);
      final color = subjectColors[selectedSubjectId] ?? Colors.teal;

      final _ = progressController.statsVersion.value;

      // % tổng từ server (để show thanh progress tổng nếu muốn)
      final overall = progressController.getProgress(subjectCode, selectedGrade);

      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "📚 Lịch sử & tiến độ theo môn",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Dropdown chọn môn
              DropdownButtonFormField<int>(
                value: selectedSubjectId,
                decoration: InputDecoration(
                  labelText: "Chọn môn học",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
                items: subjectNames.entries
                    .map((e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value),
                ))
                    .toList(),
                onChanged: (val) async {
                  if (val == null) return;
                  setState(() => selectedSubjectId = val);

                  // Optional: đồng bộ % từ server nếu trống
                  if (progressController.progressMap.isEmpty &&
                      !progressController.isLoading.value) {
                    await progressController.loadProgress(userId: 15);
                  }
                  setState(() {});
                },
              ),

              const SizedBox(height: 16),

              // Thanh % tổng của môn (có thể giữ hoặc bỏ)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: overall.clamp(0.0, 1.0),
                  minHeight: 12,
                  backgroundColor: color.withOpacity(0.18),
                  color: color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Hoàn thành: ${(overall * 100).toStringAsFixed(0)}%",
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 16),

              // Chọn range (ngày/tuần/tháng)
              Row(
                children: [
                  const Text(
                    "Khoảng thời gian:",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<StatsRange>(
                    value: range,
                    items: const [
                      DropdownMenuItem(
                          value: StatsRange.day, child: Text("7 ngày")),
                      DropdownMenuItem(
                          value: StatsRange.week, child: Text("8 tuần")),
                      DropdownMenuItem(
                          value: StatsRange.month, child: Text("6 tháng")),
                    ],
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() => range = val);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Biểu đồ cột: số bài hoàn thành theo ngày/tuần/tháng
              FutureBuilder<Map<DateTime, int>>(
                key: ValueKey('$subjectCode-$selectedGrade-$range-${progressController.statsVersion.value}'), // ⬅️ thêm key
                future: progressController.getCompletionStats(
                  subjectCode: subjectCode,
                  grade: selectedGrade,
                  range: range,
                ),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final data = snap.data ?? {};
                  if (data.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text("Chưa có lịch sử học để hiển thị."),
                    );
                  }

                  final keys = data.keys.toList()..sort();
                  final values =
                  keys.map((k) => (data[k] ?? 0).toDouble()).toList();
                  final maxY = values.isEmpty
                      ? 1.0
                      : values.reduce((a, b) => a > b ? a : b);

                  String fmtLabel(DateTime d) {
                    switch (range) {
                      case StatsRange.day:
                        return DateFormat('dd/MM').format(d);
                      case StatsRange.week:
                      // hiển thị ngày đầu tuần
                        return DateFormat('dd/MM').format(d);
                      case StatsRange.month:
                        return DateFormat('MM/yy').format(d);
                    }
                  }

                  return SizedBox(
                    height: 220,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (maxY < 3 ? 3 : maxY + 1),
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx < 0 || idx >= keys.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    fmtLabel(keys[idx]),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(show: true, drawVerticalLine: false),
                        barGroups: List.generate(keys.length, (i) {
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: values[i],
                                width: 14,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
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
