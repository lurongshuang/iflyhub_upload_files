import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import '../models/scan_config.dart';
import '../models/scan_log.dart';
import '../services/api_service.dart';
import '../services/file_service.dart';
import '../services/storage_service.dart';

class ScanController extends GetxController {
  final FileService _fileService = FileService();
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  // Reactive variables
  final Rx<ScanConfig> config =
      ScanConfig(intervalMinutes: 5, scanDirectories: []).obs;

  final RxList<ScanLog> logs = <ScanLog>[].obs;
  final RxBool isScanning = false.obs;
  final RxBool isServiceRunning = false.obs;

  Timer? _scanTimer;

  @override
  void onInit() {
    super.onInit();
    loadConfig();
    loadLogs();
  }

  @override
  void onClose() {
    _scanTimer?.cancel();
    super.onClose();
  }

  // Load saved configuration
  Future<void> loadConfig() async {
    final savedConfig = await _storageService.loadScanConfig();
    if (savedConfig != null) {
      config.value = savedConfig;
    }
  }

  // Load saved logs
  Future<void> loadLogs() async {
    final savedLogs = await _storageService.getAllLogs();
    if (savedLogs.isNotEmpty) {
      // Convert to ScanLog objects and add to logs list
      logs.value =
          savedLogs.map((logMap) {
            return ScanLog(
              timestamp: DateTime.parse(logMap['timestamp']),
              message: logMap['message'],
              type: _parseLogType(logMap['type']),
            );
          }).toList();
    }
  }

  // Parse log type from string
  LogType _parseLogType(String typeStr) {
    switch (typeStr) {
      case 'LogType.success':
        return LogType.success;
      case 'LogType.error':
        return LogType.error;
      case 'LogType.warning':
        return LogType.warning;
      default:
        return LogType.info;
    }
  }

  // Update scan interval
  Future<void> updateScanInterval(int minutes) async {
    if (minutes < 1) minutes = 1; // Minimum 1 minute

    final newConfig = config.value.copyWith(intervalMinutes: minutes);
    config.value = newConfig;
    await _storageService.saveScanConfig(newConfig);

    // Restart timer if running
    if (isServiceRunning.value) {
      _restartScanTimer();
    }

    _addLog('扫描间隔已更新为 $minutes 分钟', LogType.info);
  }

  // Add a directory to scan
  Future<void> addScanDirectory(String path) async {
    if (path.isEmpty) return;

    print('尝试添加扫描目录: $path');

    // 处理content URI
    if (path.startsWith('content://')) {
      // 内容URI处理逻辑
      _addLog('添加内容URI路径: $path', LogType.info);

      final List<String> updatedDirs = [...config.value.scanDirectories, path];
      final newConfig = config.value.copyWith(scanDirectories: updatedDirs);
      config.value = newConfig;
      await _storageService.saveScanConfig(newConfig);

      _addLog('已添加扫描目录(URI): $path', LogType.success);
      return;
    }

    // 检查目录是否存在
    final exists = await _fileService.directoryExists(path);
    if (!exists) {
      _addLog('目录不存在: $path', LogType.error);
      return;
    }

    // 检查是否可以访问该目录
    final canAccess = await _fileService.canAccessPath(path);
    if (!canAccess) {
      _addLog('无法访问目录: $path，请检查权限', LogType.error);
      return;
    }

    // 检查是否已添加
    if (config.value.scanDirectories.contains(path)) {
      _addLog('目录已存在: $path', LogType.warning);
      return;
    }

    // 添加到配置
    final List<String> updatedDirs = [...config.value.scanDirectories, path];
    final newConfig = config.value.copyWith(scanDirectories: updatedDirs);
    config.value = newConfig;
    await _storageService.saveScanConfig(newConfig);

    _addLog('已添加扫描目录: $path', LogType.success);

    // 尝试列出目录中的文件数量，检查是否能真正访问
    try {
      final files = await _fileService.getFilesFromDirectory(path);
      _addLog('目录 $path 中有 ${files.length} 个文件', LogType.info);
    } catch (e) {
      _addLog('列出目录 $path 中的文件时出错: $e', LogType.warning);
    }
  }

  // Remove a directory from scan list
  Future<void> removeScanDirectory(String path) async {
    final List<String> updatedDirs = [...config.value.scanDirectories];
    updatedDirs.remove(path);

    final newConfig = config.value.copyWith(scanDirectories: updatedDirs);
    config.value = newConfig;
    await _storageService.saveScanConfig(newConfig);

    _addLog('已删除扫描目录: $path', LogType.info);
  }

  // Start scanning service
  void startScanningService() {
    if (isServiceRunning.value) return;

    if (config.value.scanDirectories.isEmpty) {
      _addLog('请先添加扫描目录', LogType.warning);
      return;
    }

    isServiceRunning.value = true;
    _addLog('文件扫描服务已启动', LogType.info);

    // Run first scan immediately
    _scanFiles();

    // Set up timer for regular scans
    _restartScanTimer();
  }

  // Stop scanning service
  void stopScanningService() {
    if (!isServiceRunning.value) return;

    _scanTimer?.cancel();
    isServiceRunning.value = false;
    _addLog('文件扫描服务已停止', LogType.info);
  }

  // Restart scan timer with current interval
  void _restartScanTimer() {
    _scanTimer?.cancel();
    final intervalMs = config.value.intervalMinutes * 60 * 1000;
    _scanTimer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      _scanFiles();
    });
  }

  // Perform file scanning
  Future<void> _scanFiles() async {
    if (isScanning.value) return; // Prevent concurrent scans

    isScanning.value = true;
    _addLog('开始扫描文件', LogType.info);

    try {
      // Scan each directory
      for (String directory in config.value.scanDirectories) {
        await _scanDirectory(directory);
      }

      _addLog('扫描完成', LogType.success);
    } catch (e) {
      _addLog('扫描出错: $e', LogType.error);
    } finally {
      isScanning.value = false;
    }
  }

  // Scan a specific directory
  Future<void> _scanDirectory(String directoryPath) async {
    try {
      _addLog('正在扫描目录: $directoryPath', LogType.info);
      print('扫描目录中: $directoryPath');

      // 检查目录权限
      if (Platform.isAndroid) {
        try {
          // 尝试创建一个临时文件来测试写入权限
          final testFile = File('$directoryPath/test_permission.txt');
          try {
            await testFile.writeAsString('test');
            print('写入文件测试成功: ${testFile.path}');
            await testFile.delete();
            print('删除测试文件成功');
          } catch (e) {
            print('无法写入测试文件: $e');
            _addLog('无法写入目录: $e', LogType.error);
          }
        } catch (e) {
          print('测试目录权限时出错: $e');
        }
      }

      // Check if directory exists
      final exists = await _fileService.directoryExists(directoryPath);
      if (!exists) {
        _addLog('目录不存在: $directoryPath', LogType.error);
        print('目录不存在: $directoryPath');
        return;
      }

      // 列出目录内容
      try {
        final dir = Directory(directoryPath);
        print('尝试列出目录内容...');

        // 尝试单独使用dart:io来列出文件
        final files = await dir.list().toList();
        print('使用dart:io直接列出: 发现 ${files.length} 个条目');

        for (var entity in files) {
          print('发现: ${entity.path} (${entity is File ? "文件" : "目录"})');
        }
      } catch (e) {
        print('使用dart:io列出目录内容时出错: $e');
      }

      // Get all files
      final files = await _fileService.getFilesFromDirectory(directoryPath);
      _addLog('发现 ${files.length} 个文件', LogType.info);
      print('通过FileService发现 ${files.length} 个文件');

      // Process each file
      for (File file in files) {
        await _processFile(file);
      }
    } catch (e) {
      _addLog('扫描目录出错: $directoryPath - $e', LogType.error);
      print('扫描目录时发生异常: $e');
    }
  }

  // Process and upload a single file
  Future<void> _processFile(File file) async {
    try {
      final fileName = file.path.split('/').last;
      _addLog('处理文件: $fileName', LogType.info);

      // Generate MD5
      final md5 = await _fileService.getFileMd5(file);

      // Check if file needs to be uploaded
      final needsUpload = await _apiService.checkFileNeedsUpload(md5);

      if (needsUpload) {
        _addLog('文件需要上传: $fileName', LogType.info);

        // Upload file
        final result = await _apiService.uploadFile(file, md5);

        if (result['success'] == true) {
          _addLog('文件上传成功: $fileName', LogType.success);
        } else {
          // 详细记录上传失败原因
          final errorMessage = result['message'] ?? '未知错误';
          _addLog('文件上传失败: $fileName - $errorMessage', LogType.error);

          // 如果有详细错误，也记录下来
          if (result.containsKey('error')) {
            _addLog('错误详情: ${result['error']}', LogType.error);
          }
        }
      } else {
        _addLog('文件已存在，跳过上传: $fileName', LogType.info);
      }
    } catch (e) {
      _addLog('处理文件出错: ${file.path} - $e', LogType.error);
    }
  }

  // Add a log entry
  void _addLog(String message, LogType type) {
    final log = ScanLog(
      timestamp: DateTime.now(),
      message: message,
      type: type,
    );

    logs.add(log);

    // Save log to storage
    _storageService.saveLogEntry(log.toJson());
  }

  // Clear all logs
  Future<void> clearLogs() async {
    logs.clear();
    await _storageService.clearLogs();
    _addLog('日志已清空', LogType.info);
  }

  // Run a manual scan now
  Future<void> runManualScan() async {
    if (isScanning.value) {
      _addLog('扫描已在进行中', LogType.warning);
      return;
    }

    if (config.value.scanDirectories.isEmpty) {
      _addLog('请先添加扫描目录', LogType.warning);
      return;
    }

    _addLog('开始手动扫描', LogType.info);
    await _scanFiles();
  }
}
