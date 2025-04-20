import 'dart:io';
import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio = Dio();
  final String uploadUrl = 'https://lurongshuang.com/upload_file';
  final String checkUrl = 'https://lurongshuang.com/check';

  ApiService() {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  // Check if a file needs to be uploaded
  Future<bool> checkFileNeedsUpload(String fileMd5) async {
    try {
      final response = await _dio.get(
        checkUrl,
        queryParameters: {'file_md5': fileMd5},
      );

      if (response.statusCode == 200) {
        // Assuming the API returns a boolean or a status indicating if the file needs to be uploaded
        // Adjust this logic based on your actual API response
        return response.data['needsUpload'] ?? true;
      }
      return true; // If check fails, assume we need to upload
    } catch (e) {
      // If there's an error with the check, assume we need to upload
      return true;
    }
  }

  // Upload a file to the server
  Future<Map<String, dynamic>> uploadFile(File file, String fileMd5) async {
    try {
      print('准备上传文件: ${file.path}');
      print('文件MD5: $fileMd5');

      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
        'file_md5': fileMd5,
      });

      print('开始上传文件到 $uploadUrl');

      final response = await _dio.post(
        uploadUrl,
        data: formData,
        onSendProgress: (sent, total) {
          // 添加进度日志
          final progress = (sent / total * 100).toStringAsFixed(2);
          print('上传进度: $progress% (${sent ~/ 1024}KB / ${total ~/ 1024}KB)');
        },
      );

      print('服务器响应: ${response.statusCode}, 数据: ${response.data}');

      return {
        'success': response.statusCode == 200,
        'message':
            response.statusCode == 200
                ? '上传成功'
                : '服务器返回错误: ${response.statusCode}',
        'data': response.data,
      };
    } catch (e) {
      print('上传文件出错: $e');
      String errorMessage = '未知错误';

      // 分析错误类型
      if (e is DioException) {
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
            errorMessage = '连接超时';
            break;
          case DioExceptionType.sendTimeout:
            errorMessage = '发送超时';
            break;
          case DioExceptionType.receiveTimeout:
            errorMessage = '接收超时';
            break;
          case DioExceptionType.badResponse:
            errorMessage = '服务器响应错误: ${e.response?.statusCode}';
            break;
          case DioExceptionType.cancel:
            errorMessage = '请求被取消';
            break;
          case DioExceptionType.connectionError:
            errorMessage = '连接错误，请检查网络';
            break;
          default:
            errorMessage = '请求出错: ${e.message}';
        }
      }

      return {'success': false, 'message': errorMessage, 'error': e.toString()};
    }
  }
}
