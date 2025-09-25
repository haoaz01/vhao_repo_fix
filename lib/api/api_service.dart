import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';

class APIService extends GetxService {
  final String baseUrl = "http://192.168.1.219:8080/api";

  Map<String, String> getHeaders({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Xử lý lỗi mạng chung
  Map<String, dynamic> handleError(dynamic e) {
    Get.snackbar(
      "Lỗi kết nối",
      "Không thể kết nối server. Kiểm tra mạng.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
    return {'success': false, 'message': 'Network error: ${e.toString()}'};
  }

  // ------------------------------
  // Generic GET
  Future<Map<String, dynamic>> get(String path, {String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$path'),
        headers: getHeaders(token: token),
      );
      final decoded = json.decode(response.body);
      return {'statusCode': response.statusCode, 'data': decoded};
    } catch (e) {
      return {'statusCode': 500, 'data': handleError(e)};
    }
  }

  // Generic POST
  Future<Map<String, dynamic>> post(String path,
      {Map<String, dynamic>? data, String? token}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: getHeaders(token: token),
        body: json.encode(data ?? {}),
      );
      final decoded = json.decode(response.body);
      return {'statusCode': response.statusCode, 'data': decoded};
    } catch (e) {
      return {'statusCode': 500, 'data': handleError(e)};
    }
  }

  // Generic PUT
  Future<Map<String, dynamic>> put(String path,
      {Map<String, dynamic>? data, String? token}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$path'),
        headers: getHeaders(token: token),
        body: json.encode(data ?? {}),
      );
      final decoded = json.decode(response.body);
      return {'statusCode': response.statusCode, 'data': decoded};
    } catch (e) {
      return {'statusCode': 500, 'data': handleError(e)};
    }
  }

  // ------------------------------
  // Auth APIs
  Future<Map<String, dynamic>> register({
    required String email,
    required String username,
    required String password,
  }) async {
    return post('/auth/register', data: {
      'email': email.trim(),
      'username': username.trim(),
      'password': password.trim(),
    });
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return post('/auth/login', data: {
      'email': email.trim(),
      'password': password.trim(),
    });
  }

  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    return post('/auth/forgot-password', data: {
      'email': email.trim(),
    });
  }

  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    return post('/auth/reset-password', data: {
      'token': token.trim(),
      'newPassword': newPassword.trim(),
    });
  }

  Future<Map<String, dynamic>> getUserProfile({required String token}) async {
    return get('/auth/user-profile', token: token);
  }

  Future<Map<String, dynamic>> updateUserProfile({
    required String token,
    required Map<String, dynamic> userData,
  }) async {
    return put('/auth/user-profile', data: userData, token: token);
  }

  Future<Map<String, dynamic>> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    return post('/auth/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    }, token: token);
  }

  Future<Map<String, dynamic>> validateToken({required String token}) async {
    return get('/auth/validate-token', token: token);
  }

  // ------------------------------
  // Dashboard APIs
  Future<Map<String, dynamic>> getDashboard({required int userId}) async {
    // Lấy progress theo user rồi tự tổng hợp cho dashboard
    final result = await get('/progress/user/$userId'); // ✅ đúng backend
    if (result['statusCode'] != 200) return result;

    final list = result['data'] as List<dynamic>? ?? [];
    final mapData = <String, dynamic>{};

    for (final sp in list) {
      final subjectName = sp['subject']?.toString() ?? '';
      final total = (sp['totalLessons'] as num?)?.toInt() ?? 0;
      final completed = (sp['completedLessons'] as num?)?.toInt() ?? 0;
      final progressPercent = (sp['progressPercent'] as num?)?.toDouble() ?? 0.0;

      mapData[subjectName] = {
        'totalLessons': total,
        'completedLessons': completed,
        'progress': progressPercent / 100.0, // UI dùng 0..1
      };
    }
    return {'statusCode': 200, 'data': mapData};
  }

  // ------------------------------
  // Progress APIs
  Future<Map<String, dynamic>> getProgress({required int userId}) async {
    // ❌ cũ: return get('/progress/$userId');
    return get('/progress/user/$userId'); // ✅ khớp backend
  }

  Future<Map<String, dynamic>> updateProgress({
    required int userId,
    required int grade,
  }) async {
    return post('/progress/update', data: {
      'userId': userId,
      'grade': grade,
    });
  }

  // Future<Map<String, dynamic>> updateSubjectProgress({
  //   required int userId,
  //   required String subjectCode,
  //   required int grade,
  //   required double progressPercent,
  // }) async {
  //   return post('/progress/update', data: {
  //     'userId': userId,
  //     'subjectCode': subjectCode,
  //     'grade': grade,
  //     'progress': progressPercent,
  //   });
  // }

  // ------------------------------
  // Subjects APIs
  Future<Map<String, dynamic>> getSubjectsList() async {
    return get('/subjects');
  }

  Future<Map<String, dynamic>> getSubjectsByGrade({required int grade}) async {
    // ❌ cũ: return get('/grades/$grade/subjects');
    return get('/subjects?grade=$grade'); // ✅ đúng backend
  }

  // ------------------------------
  // Quiz / PDF APIs
  // Future<Map<String, dynamic>> getQuiz({required int chapterId}) async {
  //   return get('/quiz/$chapterId');
  // }

  Future<Map<String, dynamic>> getPdfFiles({
    required int grade,
    String? subject,
    String? examType, // tuỳ chọn
  }) async {
    final queryParams = <String, String>{
      'grade': grade.toString(),
      if (subject != null && subject.isNotEmpty) 'subject': subject,
      if (examType != null && examType.isNotEmpty) 'examType': examType,
    };
    final uri = Uri.parse('$baseUrl/pdf/list').replace(queryParameters: queryParams); // ✅ đúng backend
    try {
      final response = await http.get(uri, headers: getHeaders());
      final decoded = json.decode(response.body);
      return {'statusCode': response.statusCode, 'data': decoded};
    } catch (e) {
      return {'statusCode': 500, 'data': handleError(e)};
    }
  }
}
