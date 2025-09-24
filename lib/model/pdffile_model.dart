class PdfFile {
  final int id;
  final String fileName;
  final String description;
  final String subject;
  final String grade;
  final String examType;
  final DateTime uploadDate;

  PdfFile({
    required this.id,
    required this.fileName,
    required this.description,
    required this.subject,
    required this.grade,
    required this.examType,
    required this.uploadDate,
  });

  factory PdfFile.fromJson(Map<String, dynamic> json) {
    return PdfFile(
      id: json['id'],
      fileName: json['fileName'],
      description: json['description'],
      subject: json['subject'],
      grade: json['grade'],
      examType: json['examType'],
      uploadDate: DateTime.parse(json['uploadDate']),
    );
  }
}