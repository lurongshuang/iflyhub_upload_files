class ScanLog {
  final DateTime timestamp;
  final String message;
  final LogType type;

  ScanLog({required this.timestamp, required this.message, required this.type});

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'message': message,
      'type': type.toString(),
    };
  }
}

enum LogType { info, success, error, warning }
