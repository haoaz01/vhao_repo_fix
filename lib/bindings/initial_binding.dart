import 'package:get/get.dart';
import 'auth_binding.dart';
import 'main_binding.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    AuthBinding().dependencies();
    MainBinding().dependencies();
  }
}