import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iflyhub_upload_files/services/file_service.dart';
import 'controllers/scan_controller.dart';
import 'controllers/permission_controller.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize screen util for responsive design (4K resolution)
    return ScreenUtilInit(
      designSize: const Size(3840/2, 2160/2), // 4K resolution
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: '文件自动上传工具',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
          ),
          home: child,
          initialBinding: AppBindings(),
        );
      },
      child: const HomeScreen(),
    );
  }
}

// Dependency injection binding
class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Initialize controllers
    Get.put(ScanController());
    Get.put(PermissionController());
    Get.put(FileService());
  }
}
