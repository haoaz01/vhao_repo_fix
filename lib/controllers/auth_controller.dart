import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';
import '../app/routes/app_routes.dart';

class AuthController extends GetxController {
  final APIService api = APIService();

  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final resetPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  var isPasswordVisible = true.obs;
  var isLoggedIn = false.obs;
  var isLoading = false.obs;

  var email = ''.obs;
  var username = ''.obs;
  var authToken = ''.obs;

  var classes = ["6", "7", "8", "9"].obs;
  var selectedClass = "".obs;
  var isClassSelected = false.obs;

  var subjects = <String>[].obs;

  var resetToken = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    isLoggedIn.value = prefs.getBool('isLoggedIn') ?? false;
    authToken.value = prefs.getString('authToken') ?? '';
    email.value = prefs.getString('email') ?? '';
    username.value = prefs.getString('username') ?? 'Người dùng';
    selectedClass.value = prefs.getString('selectedClass') ?? '';
    isClassSelected.value = selectedClass.value.isNotEmpty;

    if (isLoggedIn.value) {
      updateSubjects();
    }
  }

  // -------------------------
  // Validation
  // -------------------------
  String? validateName(String? value) {
    if (value == null || value.isEmpty) return "Tên không được để trống";
    if (value.length < 3) return "Tên phải có ít nhất 3 ký tự";
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return "Email không được để trống";
    if (!GetUtils.isEmail(value)) return "Email không hợp lệ";
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Mật khẩu không được để trống";
    if (value.length < 6) return "Mật khẩu phải có ít nhất 6 ký tự";
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return "Xác nhận mật khẩu không được để trống";
    if (value != passwordController.text) return "Mật khẩu xác nhận không khớp";
    return null;
  }

  // -------------------------
  // Register
  // -------------------------
  Future<void> registerUser(GlobalKey<FormState> formKey) async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;

    // ✅ Nếu username trống → gán bằng email
    String finalUsername = usernameController.text.trim().isEmpty
        ? emailController.text.trim()
        : usernameController.text.trim();

    final response = await api.register(
      email: emailController.text.trim(),
      username: finalUsername,
      password: passwordController.text.trim(),
    );

    isLoading.value = false;

    if (response['statusCode'] == 200) {
      Get.snackbar(
        "Thành công",
        "Đăng ký thành công!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      Get.offAllNamed(AppRoutes.login, arguments: {
        'email': emailController.text.trim(),
        'password': passwordController.text.trim()
      });
    } else {
      final message = response['data']?['message'] ?? "Đăng ký thất bại";
      Get.snackbar(
        "Lỗi",
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // -------------------------
  // Login
  // -------------------------
  Future<void> loginUser(GlobalKey<FormState> formKey, {String? emailArg, String? passwordArg}) async {
    final loginEmail = emailArg ?? emailController.text.trim();
    final loginPassword = passwordArg ?? passwordController.text.trim();

    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    final response = await api.login(email: loginEmail, password: loginPassword);
    isLoading.value = false;

    if (response['statusCode'] == 200) {
      final data = response['data'] ?? {};
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', data['email'] ?? loginEmail);
      await prefs.setString('username', data['username'] ?? loginEmail); // ✅ fallback email
      await prefs.setString('authToken', data['token'] ?? '');
      await prefs.setBool('isLoggedIn', true);

      isLoggedIn.value = true;
      email.value = data['email'] ?? loginEmail;
      username.value = data['username'] ?? loginEmail;
      authToken.value = data['token'] ?? '';

      Get.snackbar(
        "Thành công",
        "Đăng nhập thành công!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      emailController.clear();
      passwordController.clear();
      Get.offAllNamed(AppRoutes.main);
    } else {
      final message = response['data']?['message'] ?? "Đăng nhập thất bại";
      Get.snackbar(
        "Lỗi",
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // -------------------------
  // Forgot Password
  // -------------------------
  Future<void> forgotPassword(String emailInput) async {
    if (emailInput.isEmpty || !GetUtils.isEmail(emailInput)) {
      Get.snackbar(
        "Lỗi",
        emailInput.isEmpty ? "Email không được để trống" : "Email không hợp lệ",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    final response = await api.forgotPassword(email: emailInput);
    isLoading.value = false;

    if (response['statusCode'] == 200) {
      resetToken.value = response['data']?['token'] ?? '';
      Get.snackbar(
        "Thành công",
        "Liên kết đặt lại mật khẩu đã được gửi",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      Get.toNamed(AppRoutes.resetPassword, arguments: {
        'token': response['data']?['token'],
        'email': emailInput,
      });
    } else {
      final message = response['data']?['message'] ?? "Không thể gửi yêu cầu";
      Get.snackbar(
        "Lỗi",
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // -------------------------
  // Reset Password
  // -------------------------
  Future<void> resetPassword(String token, String email, String newPassword) async {
    if (newPassword.isEmpty) {
      Get.snackbar(
        "Lỗi",
        "Mật khẩu mới không được để trống",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    final response = await api.resetPassword(token: token, newPassword: newPassword.trim());
    isLoading.value = false;

    if (response['statusCode'] == 200) {
      Get.snackbar(
        "Thành công",
        "Mật khẩu đã được đặt lại thành công. Vui lòng đăng nhập lại bằng mật khẩu mới.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      resetPasswordController.clear();
      confirmPasswordController.clear();
      Get.offAllNamed(AppRoutes.login, arguments: {'email': email.trim()});
    } else {
      final message = response['data']?['message'] ?? "Không thể đặt lại mật khẩu";
      Get.snackbar(
        "Lỗi",
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // -------------------------
  // Logout
  // -------------------------
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('email') ?? '';

    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('authToken');
    await prefs.remove('username');

    isLoggedIn.value = false;
    email.value = '';
    username.value = '';
    selectedClass.value = '';
    isClassSelected.value = false;
    authToken.value = '';
    subjects.clear();

    emailController.clear();
    passwordController.clear();
    usernameController.clear();
    resetPasswordController.clear();
    confirmPasswordController.clear();

    Get.offAllNamed(AppRoutes.login, arguments: {'email': savedEmail});
  }

  // -------------------------
  // Set Class
  // -------------------------
  Future<void> setSelectedClass(String value) async {
    selectedClass.value = value;
    isClassSelected.value = true;
    updateSubjects();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedClass', value);
    subjects.refresh();
  }

  void updateSubjects() {
    subjects.value = ["Toán", "Khoa Học Tự Nhiên", "Tiếng Anh", "Ngữ Văn"];
  }

  @override
  void onClose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    resetPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
