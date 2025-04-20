import 'dart:convert';

class ScanConfig {
  final int intervalMinutes;
  final List<String> scanDirectories;

  ScanConfig({required this.intervalMinutes, required this.scanDirectories});

  factory ScanConfig.fromJson(Map<String, dynamic> json) {
    return ScanConfig(
      intervalMinutes: json['intervalMinutes'] ?? 5,
      scanDirectories: List<String>.from(json['scanDirectories'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'intervalMinutes': intervalMinutes,
      'scanDirectories': scanDirectories,
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  ScanConfig copyWith({int? intervalMinutes, List<String>? scanDirectories}) {
    return ScanConfig(
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      scanDirectories: scanDirectories ?? this.scanDirectories,
    );
  }
}
