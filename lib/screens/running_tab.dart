import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/scan_controller.dart';

class RunningTab extends StatelessWidget {
  const RunningTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ScanController controller = Get.find<ScanController>();

    return Padding(
      padding: EdgeInsets.all(16.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildStatusIndicator(controller),
          SizedBox(height: 30.h),
          _buildServiceControls(controller),
          SizedBox(height: 30.h),
          _buildStatusSummary(controller),
        ],
      ),
    );
  }

  // Build status indicator circle
  Widget _buildStatusIndicator(ScanController controller) {
    return Obx(() {
      final bool isRunning = controller.isServiceRunning.value;
      final bool isScanning = controller.isScanning.value;

      Color statusColor = Colors.grey;
      String statusText = '未运行';

      if (isRunning) {
        if (isScanning) {
          statusColor = Colors.blue;
          statusText = '正在扫描';
        } else {
          statusColor = Colors.green;
          statusText = '运行中';
        }
      }

      return Center(
        child: Column(
          children: [
            Container(
              width: 150.w,
              height: 150.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor.withOpacity(0.2),
                border: Border.all(color: statusColor, width: 4),
              ),
              child: Center(
                child: Icon(
                  isRunning ? Icons.play_arrow : Icons.pause,
                  size: 80.sp,
                  color: statusColor,
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ],
        ),
      );
    });
  }

  // Build service control buttons
  Widget _buildServiceControls(ScanController controller) {
    return Obx(() {
      final bool isRunning = controller.isServiceRunning.value;
      final bool isScanning = controller.isScanning.value;

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed:
                isRunning
                    ? controller.stopScanningService
                    : controller.startScanningService,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 15.h),
              backgroundColor: isRunning ? Colors.red : Colors.green,
            ),
            icon: Icon(isRunning ? Icons.stop : Icons.play_arrow, size: 24.sp),
            label: Text(
              isRunning ? '停止服务' : '启动服务',
              style: TextStyle(fontSize: 16.sp),
            ),
          ),
          SizedBox(width: 20.w),
          ElevatedButton.icon(
            onPressed: isScanning ? null : controller.runManualScan,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 15.h),
            ),
            icon: Icon(Icons.refresh, size: 24.sp),
            label: Text('手动扫描', style: TextStyle(fontSize: 16.sp)),
          ),
        ],
      );
    });
  }

  // Build status summary info
  Widget _buildStatusSummary(ScanController controller) {
    return Obx(
      () => Card(
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(16.sp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '状态概览',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10.h),
              _buildInfoRow(
                Icons.timer,
                '扫描间隔',
                '${controller.config.value.intervalMinutes} 分钟',
              ),
              Divider(),
              _buildInfoRow(
                Icons.folder,
                '扫描目录数',
                '${controller.config.value.scanDirectories.length} 个目录',
              ),
              Divider(),
              _buildInfoRow(
                Icons.info_outline,
                '运行状态',
                controller.isServiceRunning.value
                    ? (controller.isScanning.value ? '正在扫描' : '等待下次扫描')
                    : '未运行',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build info row with icon and text
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Icon(icon, size: 24.sp),
          SizedBox(width: 16.w),
          Expanded(child: Text(label, style: TextStyle(fontSize: 16.sp))),
          Text(
            value,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
