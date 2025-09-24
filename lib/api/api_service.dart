import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';

class APIService extends GetxService {
  final String baseUrl = "http://10.0.2.2:8080/api";

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
    final result = await get('/dashboard/$userId');
    if (result['statusCode'] != 200) return result;

    final data = result['data'] as Map<String, dynamic>;
    Map<String, dynamic> mapData = {};
    if (data['subjects'] != null) {
      for (var subject in data['subjects']) {
        final lessons =
        subject['chapters'].expand((c) => c['lessons'] as List).toList();
        final completed =
            lessons.where((l) => l['status'] == 'completed').length;
        final progress = lessons.isNotEmpty ? completed / lessons.length : 0.0;
        mapData[subject['name']] = {
          "lessons": lessons,
          "progress": progress,
        };
      }
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

  Future<Map<String, dynamic>> updateSubjectProgress({
    required int userId,
    required String subjectCode,
    required int grade,
    required double progressPercent,
  }) async {
    return post('/progress/update', data: {
      'userId': userId,
      'subjectCode': subjectCode,
      'grade': grade,
      'progress': progressPercent,
    });
  }

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
  Future<Map<String, dynamic>> getQuiz({required int chapterId}) async {
    return get('/quiz/$chapterId');
  }

  Future<Map<String, dynamic>> getPdfFiles({
    required int grade,
    String? subject,
  }) async {
    final queryParams = {
      'grade': grade.toString(),
      if (subject != null) 'subject': subject,
    };
    final uri =
    Uri.parse('$baseUrl/pdfs').replace(queryParameters: queryParams);
    try {
      final response = await http.get(uri, headers: getHeaders());
      final decoded = json.decode(response.body);
      return {'statusCode': response.statusCode, 'data': decoded};
    } catch (e) {
      return {'statusCode': 500, 'data': handleError(e)};
    }
  }
}
