class QuizQuestion {
  final String question;
  final List<String> options;
  final int answer;
  final String explanation;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.answer,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'],
      options: List<String>.from(json['options']),
      answer: json['answer'],
      explanation: json['explanation'],
    );
  }

  Map<String, dynamic> toJson() => {
    "question": question,
    "options": options,
    "answer": answer,
    "explanation": explanation,
  };
}

class QuizSet {
  final String title;
  final List<QuizQuestion> questions;

  QuizSet({
    required this.title,
    required this.questions,
  });

  factory QuizSet.fromJson(Map<String, dynamic> json) {
    return QuizSet(
      title: json['title'],
      questions: List<QuizQuestion>.from(
        json['questions'].map((x) => QuizQuestion.fromJson(x)),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    "title": title,
    "questions": questions.map((q) => q.toJson()).toList(),
  };
}

class QuizChapter {
  final String chapter;
  final List<QuizSet> sets;

  QuizChapter({
    required this.chapter,
    required this.sets,
  });

  factory QuizChapter.fromJson(Map<String, dynamic> json) {
    return QuizChapter(
      chapter: json['chapter'],
      sets: List<QuizSet>.from(
        json['sets'].map((x) => QuizSet.fromJson(x)),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    "chapter": chapter,
    "sets": sets.map((s) => s.toJson()).toList(),
  };
}
