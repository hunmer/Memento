
class PointsLog {
  final String id;
  final String type; // '获得' 或 '消耗'
  final int value;
  final String reason;
  final DateTime timestamp;

  PointsLog({
    required this.id,
    required this.type,
    required this.value,
    required this.reason,
    required this.timestamp,
  });

  // 从JSON创建PointsLog
  factory PointsLog.fromJson(Map<String, dynamic> json) {
    return PointsLog(
      id: json['id'],
      type: json['type'],
      value: json['value'],
      reason: json['reason'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'value': value,
      'reason': reason,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
