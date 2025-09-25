import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'controllers/auth_controller.dart';
import 'controllers/main_controller.dart';
import 'controllers/progress_controller.dart'; // ✅ THÊM IMPORT NÀY

import 'app/routes/app_page.dart';
import 'app/routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final bool isFirstOpen = prefs.getBool('isFirstOpen') ?? true;
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  // ✅ Khởi tạo controller theo đúng thứ tự:
  // 1) ProgressController phải có trước để các nơi khác Get.find được
  Get.put<ProgressController>(ProgressController(), permanent: true);

  // 2) Các controller khác
  Get.put<AuthController>(AuthController(), permanent: true);
  Get.put<MainController>(MainController(), permanent: true);

  // Tính initialRoute
  final String initialRoute = isFirstOpen
      ? AppRoutes.welcome
      : (isLoggedIn ? AppRoutes.main : AppRoutes.login);

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({required this.initialRoute, super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'E-Learning App',
      initialRoute: initialRoute,
      getPages: AppPages.routes,
    );
  }
}
