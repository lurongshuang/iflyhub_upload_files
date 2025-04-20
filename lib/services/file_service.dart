import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

class FileService {
  // Generate MD5 hash for a file
  Future<String> getFileMd5(File file) async {
    try {
      List<int> bytes = await file.readAsBytes();
      Digest digest = md5.convert(bytes);
      return digest.toString();
    } catch (e) {
      throw Exception('Failed to calculate MD5: $e');
    }
  }

  // Get all files from a directory
  Future<List<File>> getFilesFromDirectory(String directoryPath) async {
    try {
      print('开始扫描目录: $directoryPath');

      // 检查是否是内容URI
      if (directoryPath.startsWith('content://')) {
        // 对于内容URI，我们需要使用不同的方式处理
        // 暂时只能返回空列表，实际应用中可能需要使用DocumentFile或其他方式
        print('暂不支持扫描内容URI: $directoryPath');
        return [];
      }

      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        print('目录不存在: $directoryPath');
        return [];
      }

      List<File> files = [];
      try {
        await for (var entity in directory.list(recursive: false)) {
          if (entity is File) {
            files.add(entity);
            print('找到文件: ${entity.path}');
          }
        }
      } catch (e) {
        print('列举目录内容出错: $e');
      }

      print('在目录中找到 ${files.length} 个文件');
      return files;
    } catch (e) {
      print('扫描目录出错: $e');
      return [];
    }
  }

  // Check if a directory exists
  Future<bool> directoryExists(String path) async {
    try {
      // 检查路径是否以content://开头，这是Android内容URI的特征
      if (path.startsWith('content://')) {
        // 内容URI需要特殊处理
        return true; // 假设FilePicker返回的内容URI路径是有效的
      }

      // 正常的文件路径检查
      final dir = Directory(path);
      final exists = await dir.exists();

      if (!exists) {
        print('路径不存在: $path');
      }

      return exists;
    } catch (e) {
      print('检查目录存在时出错: $e');
      return false;
    }
  }

  // Get the Downloads directory path on Android
  Future<String?> getAndroidDownloadsPath() async {
    try {
      // This is a common path for Android Downloads folder
      if (Platform.isAndroid) {
        return '/storage/emulated/0/Download';
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get application document directory
  Future<String> getAppDocumentsPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // Get common storage directories on Android
  Future<List<String>> getAndroidStoragePaths() async {
    List<String> paths = [];

    // 内部存储
    try {
      paths.add('/storage/emulated/0/');
      paths.add('/storage/emulated/0/Download');
      paths.add('/storage/emulated/0/DCIM');
      paths.add('/storage/emulated/0/Pictures');
    } catch (e) {
      print('获取内部存储路径出错: $e');
    }

    // 外部存储（SD卡）- 如果有的话
    try {
      final directory = Directory('/storage/');
      if (await directory.exists()) {
        final entities = await directory.list().toList();
        for (var entity in entities) {
          if (entity.path != '/storage/emulated' &&
              entity.path != '/storage/self' &&
              await Directory(entity.path).exists()) {
            paths.add(entity.path);
            // 常见的子目录
            final downloadPath = '${entity.path}/Download';
            if (await Directory(downloadPath).exists()) {
              paths.add(downloadPath);
            }
          }
        }
      }
    } catch (e) {
      print('获取外部存储路径出错: $e');
    }

    return paths;
  }

  // Check if we can access and scan a path
  Future<bool> canAccessPath(String path) async {
    try {
      final dir = Directory(path);
      // 尝试列出目录中的文件，如果成功则可以访问
      final files = await dir.list().take(1).toList();
      return true;
    } catch (e) {
      print('无法访问路径: $path, 错误: $e');
      return false;
    }
  }
}
