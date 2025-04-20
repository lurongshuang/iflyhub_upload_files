import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/scan_controller.dart';
import '../models/scan_log.dart';

class LogsTab extends StatelessWidget {
  const LogsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ScanController controller = Get.find<ScanController>();

    return Padding(
      padding: EdgeInsets.all(16.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(controller),
          SizedBox(height: 10.h),
          _buildLogsList(controller),
        ],
      ),
    );
  }

  // Build header with title and clear button
  Widget _buildHeader(ScanController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '运行日志',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        TextButton.icon(
          onPressed: () {
            controller.clearLogs();
          },
          icon: const Icon(Icons.delete_sweep),
          label: const Text('清空日志'),
        ),
      ],
    );
  }

  // Build the scrollable logs list
  Widget _buildLogsList(ScanController controller) {
    return Expanded(
      child: Obx(
        () =>
            controller.logs.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, size: 48.sp, color: Colors.grey),
                      SizedBox(height: 16.h),
                      Text(
                        '暂无日志',
                        style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                      ),
                    ],
                  ),
                )
                : ListView.builder(
                  itemCount: controller.logs.length,
                  reverse: true,
                  itemBuilder: (context, index) {
                    final log =
                        controller.logs[controller.logs.length - 1 - index];
                    return _buildLogItem(log);
                  },
                ),
      ),
    );
  }

  // Build a single log item
  Widget _buildLogItem(ScanLog log) {
    Color getLogColor() {
      switch (log.type) {
        case LogType.success:
          return Colors.green;
        case LogType.error:
          return Colors.red;
        case LogType.warning:
          return Colors.orange;
        default:
          return Colors.blue;
      }
    }

    IconData getLogIcon() {
      switch (log.type) {
        case LogType.success:
          return Icons.check_circle;
        case LogType.error:
          return Icons.error;
        case LogType.warning:
          return Icons.warning;
        default:
          return Icons.info;
      }
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4.h),
      child: ListTile(
        leading: Icon(getLogIcon(), color: getLogColor()),
        title: Text(log.message, style: TextStyle(fontSize: 14.sp)),
        subtitle: Text(
          '${log.timestamp.year}-${log.timestamp.month.toString().padLeft(2, '0')}-${log.timestamp.day.toString().padLeft(2, '0')} ${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
          style: TextStyle(fontSize: 12.sp),
        ),
      ),
    );
  }
}
