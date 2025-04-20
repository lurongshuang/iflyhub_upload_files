import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import '../controllers/scan_controller.dart';
import '../services/file_service.dart';
import 'dart:io';

class SettingsTab extends StatefulWidget {
  const SettingsTab({Key? key}) : super(key: key);

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  late ScanController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ScanController>();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIntervalSection(),
          SizedBox(height: 20.h),
          Expanded(child: _buildDirectoriesSection(context)),
        ],
      ),
    );
  }

  // Build scan interval configuration section
  Widget _buildIntervalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '扫描间隔设置',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10.h),
        Obx(
          () => Slider(
            value: controller.config.value.intervalMinutes.toDouble(),
            min: 1,
            max: 60,
            divisions: 59,
            label: '${controller.config.value.intervalMinutes} 分钟',
            onChanged: (value) {
              controller.updateScanInterval(value.toInt());
            },
          ),
        ),
        Obx(
          () => Text(
            '当前设置: ${controller.config.value.intervalMinutes} 分钟',
            style: TextStyle(fontSize: 16.sp),
          ),
        ),
      ],
    );
  }

  // Build scan directories configuration section
  Widget _buildDirectoriesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '扫描目录设置',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: () => _showDirectorySelectionOptions(context),
              icon: const Icon(Icons.add),
              label: const Text('添加目录'),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Expanded(
          child: Obx(
            () =>
                controller.config.value.scanDirectories.isEmpty
                    ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.sp),
                        child: Text(
                          '没有配置扫描目录',
                          style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                        ),
                      ),
                    )
                    : _buildDirectoriesList(),
          ),
        ),
      ],
    );
  }

  // 显示目录选择选项
  Future<void> _showDirectorySelectionOptions(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder:
          (BuildContext dialogContext) => AlertDialog(
            title: const Text('选择目录方式'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.folder),
                    title: const Text('使用文件选择器'),
                    onTap: () => Navigator.pop(dialogContext, 'picker'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.download),
                    title: const Text('Download目录'),
                    onTap: () => Navigator.pop(dialogContext, 'download'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.perm_media),
                    title: const Text('DCIM目录'),
                    onTap: () => Navigator.pop(dialogContext, 'dcim'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo),
                    title: const Text('Pictures目录'),
                    onTap: () => Navigator.pop(dialogContext, 'pictures'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.input),
                    title: const Text('手动输入路径'),
                    onTap: () => Navigator.pop(dialogContext, 'manual'),
                  ),
                  // ListTile(
                  //   leading: const Icon(Icons.android),
                  //   title: const Text('扫描所有常用目录'),
                  //   subtitle: const Text('添加多个存储位置'),
                  //   onTap: () => Navigator.pop(dialogContext, 'scan_all'),
                  // ),
                ],
              ),
            ),
          ),
    );

    if (result == null) return;

    String? selectedDirectory;

    if (result == 'picker') {
      // 使用文件选择器
      selectedDirectory = await FilePicker.platform.getDirectoryPath();
      print('选择器返回路径: $selectedDirectory');
    } else if (result == 'download') {
      // 使用Download目录
      if (Platform.isAndroid) {
        selectedDirectory = '/storage/emulated/0/Download';
        print('使用Download目录: $selectedDirectory');
      } else {
        Get.snackbar('提示', '此功能仅支持Android设备');
        return;
      }
    } else if (result == 'dcim') {
      // 使用DCIM目录
      if (Platform.isAndroid) {
        selectedDirectory = '/storage/emulated/0/DCIM';
        print('使用DCIM目录: $selectedDirectory');
      } else {
        Get.snackbar('提示', '此功能仅支持Android设备');
        return;
      }
    } else if (result == 'pictures') {
      // 使用Pictures目录
      if (Platform.isAndroid) {
        selectedDirectory = '/storage/emulated/0/Pictures';
        print('使用Pictures目录: $selectedDirectory');
      } else {
        Get.snackbar('提示', '此功能仅支持Android设备');
        return;
      }
    } else if (result == 'manual') {
      // 手动输入路径
      selectedDirectory = await _showPathInputDialog(context);
      print('手动输入路径: $selectedDirectory');
    } else if (result == 'scan_all') {
      // 添加多个常用目录
      if (Platform.isAndroid) {
        // 使用FileService获取所有常用目录
        final fileService = Get.find<FileService>();
        final paths = await fileService.getAndroidStoragePaths();

        // 添加所有路径
        for (final path in paths) {
          print('添加常用路径: $path');
          controller.addScanDirectory(path);
        }
        return;
      } else {
        Get.snackbar('提示', '此功能仅支持Android设备');
        return;
      }
    }

    if (selectedDirectory != null && selectedDirectory.isNotEmpty) {
      controller.addScanDirectory(selectedDirectory);
    }
  }

  // Build the list of configured directories
  Widget _buildDirectoriesList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: controller.config.value.scanDirectories.length,
      itemBuilder: (context, index) {
        final directory = controller.config.value.scanDirectories[index];
        return Card(
          margin: EdgeInsets.symmetric(vertical: 5.h),
          child: ListTile(
            title: Text(directory, style: TextStyle(fontSize: 14.sp)),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                controller.removeScanDirectory(directory);
              },
            ),
          ),
        );
      },
    );
  }

  // 显示路径输入对话框
  Future<String?> _showPathInputDialog(BuildContext context) async {
    final TextEditingController textController = TextEditingController();
    if (Platform.isAndroid) {
      textController.text = '/storage/emulated/0/Download';
    }

    return showDialog<String>(
      context: context,
      builder:
          (BuildContext dialogContext) => AlertDialog(
            title: const Text('输入目录路径'),
            content: TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: '例如：/storage/emulated/0/Download',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed:
                    () => Navigator.pop(dialogContext, textController.text),
                child: const Text('确定'),
              ),
            ],
          ),
    );
  }
}
