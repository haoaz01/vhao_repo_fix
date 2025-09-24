import 'exercise_model.dart';

class ContentItem {
  final int id;
  final String type;   // "text" hoặc "image"
  final String value;  // nội dung text hoặc link image
  final int order;     // thứ tự hiển thị

  ContentItem({
    required this.id,
    required this.type,
    required this.value,
    required this.order,
  });

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    return ContentItem(
      id: json['id'] ?? 0,
      type: json['contentType'] ?? 'text',
      value: json['contentValue'] ?? '',
      order: json['contentOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contentType': type,
      'contentValue': value,
      'contentOrder': order,
    };
  }

  ContentItem copyWith({
    int? id,
    String? type,
    String? value,
    int? order,
  }) {
    return ContentItem(
      id: id ?? this.id,
      type: type ?? this.type,
      value: value ?? this.value,
      order: order ?? this.order,
    );
  }
}

class Lesson {
  final int id;
  final int? subjectId; // ✅ để nullable cho khớp backend
  final String title;
  final String videoUrl;
  final List<ContentItem> contents;
  final List<Exercise> exercises;

  Lesson({
    required this.id,
    this.subjectId, // ✅ nullable
    required this.title,
    required this.videoUrl,
    List<ContentItem>? contents,
    List<Exercise>? exercises,
  })  : contents = contents ?? const [],
        exercises = exercises ?? const [];

  factory Lesson.fromJson(Map<String, dynamic> json) {
    final contentsData = json['contents'] as List<dynamic>? ?? [];
    final exercisesData = json['exercises'] as List<dynamic>? ?? [];

    return Lesson(
      id: json['id'] ?? 0,
      subjectId: json['subjectId'], // ✅ có thì lấy, không có thì null
      title: json['title'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      contents: contentsData.map((c) => ContentItem.fromJson(c)).toList(),
      exercises: exercisesData.map((e) => Exercise.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (subjectId != null) 'subjectId': subjectId, // ✅ chỉ thêm khi có
      'title': title,
      'videoUrl': videoUrl,
      'contents': contents.map((c) => c.toJson()).toList(),
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }

  Lesson copyWith({
    int? id,
    int? subjectId,
    String? title,
    String? videoUrl,
    List<ContentItem>? contents,
    List<Exercise>? exercises,
  }) {
    return Lesson(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      videoUrl: videoUrl ?? this.videoUrl,
      contents: contents ?? this.contents,
      exercises: exercises ?? this.exercises,
    );
  }
}
