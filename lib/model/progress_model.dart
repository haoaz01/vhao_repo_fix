class ProgressModel {
  final int subjectId;
  final String subject; // ✅ trùng với backend
  final int grade;
  final int completedLessons;
  final int totalLessons;
  final double progressPercent;
  final DateTime? updatedAt;

  ProgressModel({
    required this.subjectId,
    required this.subject,
    required this.grade,
    required this.completedLessons,
    required this.totalLessons,
    required this.progressPercent,
    this.updatedAt,
  });

  factory ProgressModel.fromJson(Map<String, dynamic> json) {
    return ProgressModel(
      subjectId: json['subjectId'] ?? 0,
      subject: json['subject'] ?? '', // ✅ đổi từ subjectName -> subject
      grade: json['grade'] ?? 0,
      completedLessons: json['completedLessons'] ?? 0,
      totalLessons: json['totalLessons'] ?? 0,
      progressPercent: (json['progressPercent'] as num?)?.toDouble() ?? 0.0,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subjectId': subjectId,
      'subject': subject, // ✅ đồng bộ với backend
      'grade': grade,
      'completedLessons': completedLessons,
      'totalLessons': totalLessons,
      'progressPercent': progressPercent,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
