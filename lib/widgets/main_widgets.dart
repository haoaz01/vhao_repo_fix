import 'package:flutter/material.dart';
import 'package:flutter_elearning_application/controllers/auth_controller.dart';
import 'package:get/get.dart';
import '../controllers/main_controller.dart';
import '../screens/dashboard_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';

class MainScreen extends StatelessWidget {
  final MainController mainController = Get.find<MainController>();
  final AuthController userController = Get.find<AuthController>();

  MainScreen({super.key});

  final List<Widget> screens = [
    HomeScreen(),
    DashBoardScreen(),
    ProfileScreen(),
  ];

  final List<String> titles = [
    "Trang chủ",
    "Thống kê"
    "Thông tin cá nhân",
  ];

  final Color primaryGreen = const Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: screens[mainController.currentIndex.value],

      /// BOTTOM NAVIGATION FLOATING ROUNDED STYLE
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              currentIndex: mainController.currentIndex.value,
              onTap: (index) => mainController.changeTab(index),
              selectedItemColor: primaryGreen,
              unselectedItemColor: Colors.grey,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
              ),
              iconSize: 28,
              elevation: 0,
              items: [
                _buildAnimatedItem(
                  icon: Icons.home,
                  label: "Home",
                  isSelected: mainController.currentIndex.value == 0,
                ),
                _buildAnimatedItem(
                  icon: Icons.dashboard,
                  label: "DashBoard",
                  isSelected: mainController.currentIndex.value == 1,
                ),
                _buildAnimatedItem(
                  icon: Icons.person,
                  label: "Profile",
                  isSelected: mainController.currentIndex.value == 2,
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  /// CUSTOM BOTTOM NAVIGATION ITEM WITH ANIMATION
  BottomNavigationBarItem _buildAnimatedItem({
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.only(
          top: isSelected ? 0 : 4,
          bottom: isSelected ? 4 : 0,
        ),
        child: Icon(
          icon,
          size: isSelected ? 32 : 26,
        ),
      ),
      label: label,
    );
  }
}