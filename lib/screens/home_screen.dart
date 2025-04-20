import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/scan_controller.dart';
import '../controllers/permission_controller.dart';
import 'settings_tab.dart';
import 'logs_tab.dart';
import 'running_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScanController _scanController = Get.find<ScanController>();
  final PermissionController _permissionController =
      Get.find<PermissionController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Check permissions when app starts
    _checkPermissions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Check if we have the required permissions
  Future<void> _checkPermissions() async {
    await _permissionController.checkPermissions();

    if (!_permissionController.hasStoragePermission.value) {
      // Show dialog to request permission
      _showPermissionDialog();
    }
  }

  // Show permission request dialog
  void _showPermissionDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('需要权限'),
        content: const Text('此应用需要存储权限以扫描文件。请授予权限以继续。'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              Get.back();
              final granted =
                  await _permissionController.requestStoragePermission();
              if (!granted) {
                // If permission is still not granted, show settings option
                _showSettingsDialog();
              }
            },
            child: const Text('授权'),
          ),
        ],
      ),
    );
  }

  // Show settings dialog if permission denied
  void _showSettingsDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('权限被拒绝'),
        content: const Text('没有存储权限，应用将无法正常运行。请在设置中手动授予权限。'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              Get.back();
              await _permissionController.openSettings();
            },
            child: const Text('前往设置'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('文件自动上传工具'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.settings), text: '设置'),
            Tab(icon: Icon(Icons.list), text: '日志'),
            Tab(icon: Icon(Icons.play_circle), text: '运行'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [SettingsTab(), LogsTab(), RunningTab()],
      ),
    );
  }
}
