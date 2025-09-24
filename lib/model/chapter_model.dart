import 'lesson_model.dart';

class Chapter {
  final int id;
  final String title;
  final int orderNo;
  final List<Lesson> lessons;

  Chapter({
    required this.id,
    required this.title,
    required this.orderNo,
    List<Lesson>? lessons,
  }) : lessons = lessons ?? const [];

  factory Chapter.fromJson(Map<String, dynamic> json) {
    final lessonsJson = json['lessons'] as List<dynamic>? ?? [];

    return Chapter(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      orderNo: json['orderNo'] ?? 0, // ✅ mặc định 0 thay vì 1
      lessons: lessonsJson.map((e) => Lesson.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'orderNo': orderNo,
      'lessons': lessons.map((l) => l.toJson()).toList(),
    };
  }

  Chapter copyWith({
    int? id,
    String? title,
    int? orderNo,
    List<Lesson>? lessons,
  }) {
    return Chapter(
      id: id ?? this.id,
      title: title ?? this.title,
      orderNo: orderNo ?? this.orderNo,
      lessons: lessons ?? this.lessons,
    );
  }
}
