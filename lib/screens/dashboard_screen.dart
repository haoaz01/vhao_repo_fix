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
        decoration: const BoxDecoration(
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
                        // 1) Lịch sử & tiến độ theo môn (chart)
                        ProgressHistorySection(),
                        const SizedBox(height: 16),

                        // 2) Các môn học (4 card giống ảnh mẫu)
                        SubjectsOverviewWidget(grade: 7),
                        const SizedBox(height: 16),

                        // 3) Streak card
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
      onTap: () => Get.to(() => const StreakScreen()),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<
              ({int currentStreak, int bestStreak, int totalDays, int weekCount})>(
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
                        style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      Text(
                        'Kỷ lục: ${data.bestStreak} ngày',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
      mainAxisSize: MainAxisSize.min,
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

/// =======================
/// Các môn học (4 thẻ %)
/// =======================
class SubjectsOverviewWidget extends StatelessWidget {
  final int grade;
  SubjectsOverviewWidget({super.key, required this.grade});

  final ProgressController progressController = Get.find<ProgressController>();

  // Ảnh asset bạn cung cấp
  final Map<String, String> subjectIcons = const {
    'Toán': 'assets/icon/toan.png',
    'Khoa Học Tự Nhiên': 'assets/icon/khoahoctunhien.png',
    'Ngữ Văn': 'assets/icon/nguvan.png',
    'Tiếng Anh': 'assets/icon/tienganh.png',
  };

  // Màu theo môn
  final Map<String, Color> subjectColors = const {
    'Toán': Colors.blue,
    'Khoa Học Tự Nhiên': Colors.green,
    'Ngữ Văn': Colors.orange,
    'Tiếng Anh': Colors.purple,
  };

  // Thứ tự hiển thị như ảnh mẫu
  final List<String> subjectsOrder = const [
    'Toán',
    'Khoa Học Tự Nhiên',
    'Tiếng Anh',
    'Ngữ Văn',
  ];

  @override
  Widget build(BuildContext context) {
    // Load % lần đầu nếu cần
    if (progressController.progressMap.isEmpty &&
        !progressController.isLoading.value) {
      progressController.loadProgress(userId: 15);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Các môn học',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,color: Colors.white),
        ),
        const SizedBox(height: 10),

        // Grid 2 cột, chiều cao gọn như ảnh
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: subjectsOrder.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.9, // ngang giống ảnh
          ),
          itemBuilder: (_, i) {
            final name = subjectsOrder[i];
            final icon = subjectIcons[name]!;
            final color = subjectColors[name]!;

            // chỉ wrap progress bằng Obx để tránh GetX error
            return Obx(() {
              final code = progressController.mapSubjectToCode(name);
              final p = progressController.getProgressAnyGrade(code);
              return _SubjectCard(
                title: name,
                iconPath: icon,
                color: color,
                progress: p,
              );
            });
          },
        ),
      ],
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final String title;
  final String iconPath;
  final Color color;
  final double progress;

  const _SubjectCard({
    Key? key,
    required this.title,
    required this.iconPath,
    required this.color,
    required this.progress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color border = color.withOpacity(0.35); // viền nhạt
    final Color track  = color.withOpacity(0.15); // track progress nhạt

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // nền trắng hoàn toàn
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1), // viền màu theo môn
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // icon + tên môn
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: border, width: 1),
                ),
                alignment: Alignment.center,
                child: Image.asset(
                  iconPath,
                  width: 22,
                  height: 22,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          // progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: track,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(progress * 100).toStringAsFixed(0)}% Hoàn thành',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


/// ======================================
/// Lịch sử & tiến độ theo môn (có chart)
/// ======================================
class ProgressHistorySection extends StatefulWidget {
  @override
  State<ProgressHistorySection> createState() => _ProgressHistorySectionState();
}

class _ProgressHistorySectionState extends State<ProgressHistorySection> {
  StatsRange range = StatsRange.week;

  final ProgressController progressController = Get.find<ProgressController>();

  final Map<int, String> subjectNames = const {
    1: 'Toán',
    2: 'Ngữ văn',
    3: 'Tiếng Anh',
    4: 'Khoa học Tự nhiên',
  };

  final Map<int, Color> subjectColors = const {
    1: Colors.blue,
    2: Colors.orange,
    3: Colors.purple,
    4: Colors.green,
  };

  int selectedSubjectId = 1;
  int selectedGrade = 7;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (progressController.progressMap.isEmpty &&
          !progressController.isLoading.value) {
        await progressController.loadProgress(userId: 15);
      }
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final subjectName = subjectNames[selectedSubjectId]!;
      final subjectCode = progressController.mapSubjectToCode(subjectName);
      final color = subjectColors[selectedSubjectId] ?? Colors.teal;

      // trigger rebuild khi log thay đổi
      final _ = progressController.statsVersion.value;

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
                '📚 Lịch sử & tiến độ theo môn',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<int>(
                value: selectedSubjectId,
                decoration: InputDecoration(
                  labelText: 'Chọn môn học',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
                items: subjectNames.entries
                    .map((e) =>
                    DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (val) async {
                  if (val == null) return;
                  setState(() => selectedSubjectId = val);
                  final subjectName = subjectNames[val]!;
                  final subjectCode = progressController.mapSubjectToCode(subjectNames[val]!);
                  final best = progressController.getBestGradeFor(subjectCode);
                  if (best != null) {
                    selectedGrade = best; // chuyển về grade có data
                  }
                  if (progressController.progressMap.isEmpty &&
                      !progressController.isLoading.value) {
                    await progressController.loadProgress(userId: 15);
                  }
                  setState(() {});
                },
              ),

              const SizedBox(height: 16),

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
                'Hoàn thành: ${(overall * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  const Text(
                    'Khoảng thời gian:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<StatsRange>(
                    value: range,
                    items: const [
                      DropdownMenuItem(value: StatsRange.day, child: Text('7 ngày')),
                      DropdownMenuItem(value: StatsRange.week, child: Text('8 tuần')),
                      DropdownMenuItem(value: StatsRange.month, child: Text('6 tháng')),
                    ],
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() => range = val);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),

              FutureBuilder<Map<DateTime, int>>(
                key: ValueKey(
                    '$subjectCode-$selectedGrade-$range-${progressController.statsVersion.value}'),
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
                      child: Text('Chưa có lịch sử học để hiển thị.'),
                    );
                  }

                  final keys = data.keys.toList()..sort();
                  final values =
                  keys.map((k) => (data[k] ?? 0).toDouble()).toList();
                  final maxY =
                  values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);

                  String fmtLabel(DateTime d) {
                    switch (range) {
                      case StatsRange.day:
                        return DateFormat('dd/MM').format(d);
                      case StatsRange.week:
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
                          leftTitles: const AxisTitles(
                            sideTitles:
                            SideTitles(showTitles: true, reservedSize: 30),
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
                        gridData:
                        FlGridData(show: true, drawVerticalLine: false),
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
