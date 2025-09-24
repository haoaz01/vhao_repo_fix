import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/routes/app_routes.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  Future<GetNavConfig?> redirectDelegate(GetNavConfig route) async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final bool isFirstOpen = prefs.getBool('isFirstOpen') ?? true;

    // Nếu là lần đầu mở app, cho phép vào WelcomeScreen
    if (isFirstOpen) {
      return await super.redirectDelegate(route);
    }

    // Nếu chưa đăng nhập và cố truy cập route được bảo vệ
    if (!isLoggedIn && _isProtectedRoute(route.currentPage?.name)) {
      return GetNavConfig.fromRoute(AppRoutes.login);
    }

    // Nếu đã đăng nhập và cố truy cập auth routes (login/signup)
    if (isLoggedIn && _isAuthRoute(route.currentPage?.name)) {
      return GetNavConfig.fromRoute(AppRoutes.main);
    }

    return await super.redirectDelegate(route);
  }

  bool _isProtectedRoute(String? routeName) {
    return [
      AppRoutes.main,
      AppRoutes.home,
      AppRoutes.subjectDetail,
      AppRoutes.course,
      AppRoutes.theory,
      AppRoutes.lessonDetail,
      AppRoutes.quizDetail,
      AppRoutes.quiz,
    ].contains(routeName);
  }

  bool _isAuthRoute(String? routeName) {
    return [
      AppRoutes.login,
      AppRoutes.signup,
      AppRoutes.welcome,
    ].contains(routeName);
  }
}