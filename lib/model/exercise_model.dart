class ExerciseSolution {
  final String type; // "text" hoặc "image"
  final String value;

  const ExerciseSolution({
    required this.type,
    required this.value,
  });

  factory ExerciseSolution.fromJson(Map<String, dynamic> json) {
    return ExerciseSolution(
      type: (json['type'] as String?)?.toLowerCase() ?? 'text',
      value: json['value'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'value': value,
    };
  }

  ExerciseSolution copyWith({
    String? type,
    String? value,
  }) {
    return ExerciseSolution(
      type: type ?? this.type,
      value: value ?? this.value,
    );
  }
}

class Exercise {
  final int id;
  final String question;
  final List<ExerciseSolution> solutions;

  const Exercise({
    required this.id,
    required this.question,
    this.solutions = const [],
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    final solutionsData = json['solutions'] as List<dynamic>? ?? [];
    final solutions = solutionsData
        .map((s) => ExerciseSolution.fromJson(s as Map<String, dynamic>))
        .toList();

    return Exercise(
      id: json['id'] as int? ?? 0,
      question: json['question'] as String? ?? '',
      solutions: solutions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'solutions': solutions.map((s) => s.toJson()).toList(),
    };
  }

  Exercise copyWith({
    int? id,
    String? question,
    List<ExerciseSolution>? solutions,
  }) {
    return Exercise(
      id: id ?? this.id,
      question: question ?? this.question,
      solutions: solutions ?? this.solutions,
    );
  }
}
