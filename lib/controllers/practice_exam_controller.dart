import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../model/pdffile_model.dart';

class PracticeExamController extends GetxController {
  final Dio _dio = Dio();
  final RxList<PdfFile> exams = <PdfFile>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  Future<void> loadExams(String subject, String grade, {String? examType}) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Convert subject name to API format
      String formattedSubject = _convertSubjectToApiFormat(subject);

      String url = 'http://192.168.15.192:8080/api/pdf/list?subject=$formattedSubject&grade=$grade';
      if (examType != null) {
        url += '&examType=$examType';
      }

      print('Loading exams from: $url');

      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        // Make sure the response data is a List
        if (response.data is List) {
          exams.value = (response.data as List)
              .map((item) => PdfFile.fromJson(item))
              .toList();
          print('Loaded ${exams.length} exams');
        } else {
          errorMessage.value = 'Định dạng dữ liệu không hợp lệ';
        }
      } else {
        errorMessage.value = 'Không thể tải danh sách đề thi: ${response.statusCode}';
      }
    } catch (e) {
      errorMessage.value = 'Lỗi khi tải danh sách đề thi: $e';
      // Print the error for debugging
      print('Error loading exams: $e');
    } finally {
      isLoading.value = false;
    }
  }

  String _convertSubjectToApiFormat(String subject) {
    switch (subject.toLowerCase()) {
      case 'toán': return 'toan';
      case 'khoa học tự nhiên': return 'khoahoctunhien';
      case 'ngữ văn': return 'nguvan';
      case 'tiếng anh': return 'tienganh';
      default: return subject.toLowerCase();
    }
  }
}