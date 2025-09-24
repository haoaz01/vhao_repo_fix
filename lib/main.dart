import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'controllers/auth_controller.dart';
import 'controllers/main_controller.dart';
import 'app/routes/app_page.dart';
import 'app/routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final bool isFirstOpen = prefs.getBool('isFirstOpen') ?? true;
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  // Khởi tạo các controller
  Get.put(AuthController());
  Get.put(MainController());

  // Quyết định initialRoute dựa trên isFirstOpen trước
  String initialRoute;
  if (isFirstOpen) {
    initialRoute = AppRoutes.welcome; // lần đầu mở app
  } else {
    initialRoute = isLoggedIn ? AppRoutes.main : AppRoutes.login;
  }

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
