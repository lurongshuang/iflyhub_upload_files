import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_config.dart';

class StorageService {
  static const String configKey = 'scan_config';
  static const String logsKey = 'scan_logs';

  // Save scan configuration
  Future<bool> saveScanConfig(ScanConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(configKey, config.toJsonString());
    } catch (e) {
      return false;
    }
  }

  // Load scan configuration
  Future<ScanConfig?> loadScanConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(configKey);

      if (configJson == null) {
        return null;
      }

      final Map<String, dynamic> decoded = jsonDecode(configJson);
      return ScanConfig.fromJson(decoded);
    } catch (e) {
      return null;
    }
  }

  // Save logs history (limited to last 100 logs)
  Future<bool> saveLogEntry(Map<String, dynamic> logEntry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> logs = prefs.getStringList(logsKey) ?? [];

      // Add new log
      logs.add(jsonEncode(logEntry));

      // Keep only the latest 100 logs
      if (logs.length > 100) {
        logs = logs.sublist(logs.length - 100);
      }

      return await prefs.setStringList(logsKey, logs);
    } catch (e) {
      print('保存日志出错: $e');
      return false;
    }
  }

  // Get all logs
  Future<List<Map<String, dynamic>>> getAllLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> logs = prefs.getStringList(logsKey) ?? [];

      // 解码日志
      List<Map<String, dynamic>> decodedLogs =
          logs
              .map((logJson) => Map<String, dynamic>.from(jsonDecode(logJson)))
              .toList();

      // 返回原始顺序的日志（最新的在最后）
      return decodedLogs;
    } catch (e) {
      print('读取日志出错: $e');
      return [];
    }
  }

  // Clear all logs
  Future<bool> clearLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(logsKey);
    } catch (e) {
      return false;
    }
  }
}
