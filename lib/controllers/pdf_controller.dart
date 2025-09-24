import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:dio/dio.dart';

class PdfController extends GetxController {
  final Dio _dio = Dio();
  final String fileName;

  PdfController(this.fileName);

  Rx<Uint8List> pdfBytes = Rx<Uint8List>(Uint8List(0));
  RxBool isLoading = true.obs;
  RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPdf(fileName);
  }

  Future<void> fetchPdf(String fileName) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await _dio.get(
        'http://192.168.15.192:8080/api/pdf/$fileName',
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        pdfBytes.value = Uint8List.fromList(response.data);
      } else {
        errorMessage.value = 'Không thể tải PDF: ${response.statusCode}';
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage.value = 'Kết nối quá hạn. Vui lòng thử lại.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage.value = 'Mất kết nối đến máy chủ.';
      } else {
        errorMessage.value = 'Lỗi khi tải PDF: ${e.message}';
      }
    } catch (e) {
      errorMessage.value = 'Lỗi không xác định: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void retry() {
    fetchPdf(fileName);
  }
}