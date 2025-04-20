import 'dart:io';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionController extends GetxController {
  final RxBool hasStoragePermission = false.obs;
  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

  @override
  void onInit() {
    super.onInit();
    checkPermissions();
  }

  // 检查存储权限状态
  Future<void> checkPermissions() async {
    if (Platform.isAndroid) {
      // 检查 Android 版本和权限情况
      final androidInfo = await deviceInfoPlugin.androidInfo;
      final sdkVersion = androidInfo.version.sdkInt;

      if (sdkVersion >= 30) {
        // Android 11或更高版本
        // 对于Android 11+，检查MANAGE_EXTERNAL_STORAGE权限
        final manageStatus = await Permission.manageExternalStorage.status;
        hasStoragePermission.value = manageStatus.isGranted;
      } else {
        // 低于Android 11的版本，使用传统存储权限
        final storageStatus = await Permission.storage.status;
        hasStoragePermission.value = storageStatus.isGranted;
      }
    } else {
      // 其他平台（如iOS）的处理
      final storageStatus = await Permission.storage.status;
      hasStoragePermission.value = storageStatus.isGranted;
    }
  }

  // 请求存储权限
  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // 检查 Android 版本
      final androidInfo = await deviceInfoPlugin.androidInfo;
      final sdkVersion = androidInfo.version.sdkInt;

      if (sdkVersion >= 30) {
        // Android 11或更高版本
        // 使用MANAGE_EXTERNAL_STORAGE权限
        await Permission.manageExternalStorage.request();
        // 重新检查权限状态
        final manageStatus = await Permission.manageExternalStorage.status;
        hasStoragePermission.value = manageStatus.isGranted;
      } else {
        // 使用传统存储权限
        await Permission.storage.request();
        final storageStatus = await Permission.storage.status;
        hasStoragePermission.value = storageStatus.isGranted;
      }
    } else {
      // 其他平台
      await Permission.storage.request();
      final storageStatus = await Permission.storage.status;
      hasStoragePermission.value = storageStatus.isGranted;
    }

    return hasStoragePermission.value;
  }

  // 打开应用设置
  Future<bool> openSettings() async {
    return await openAppSettings();
  }
}
