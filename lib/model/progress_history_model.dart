class ProgressHistoryModel {
  final double progressPercent;
  final DateTime recordedAt;

  ProgressHistoryModel({
    required this.progressPercent,
    required this.recordedAt,
  });

  factory ProgressHistoryModel.fromJson(Map<String, dynamic> json) {
    return ProgressHistoryModel(
      progressPercent: (json['progressPercent'] as num?)?.toDouble() ?? 0.0,
      recordedAt: DateTime.parse(json['recordedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
