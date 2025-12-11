import 'dart:convert';

/// 同步请求模型 - 用于推送加密文件到服务器
class SyncRequest {
  /// 文件路径 (相对于用户数据目录)
  /// 例如: 'diary/2024-01-01.json', 'chat/channels.json'
  final String filePath;

  /// 加密后的数据 (格式: base64(iv).base64(ciphertext))
  final String encryptedData;

  /// 客户端上次同步时的 MD5 (首次上传时为 null)
  /// 用于乐观并发控制，检测冲突
  final String? oldMd5;

  /// 当前数据的 MD5 (加密前的原始数据)
  final String newMd5;

  /// 客户端时间戳
  final DateTime timestamp;

  /// 设备标识
  final String deviceId;

  SyncRequest({
    required this.filePath,
    required this.encryptedData,
    this.oldMd5,
    required this.newMd5,
    required this.timestamp,
    required this.deviceId,
  });

  Map<String, dynamic> toJson() => {
        'file_path': filePath,
        'encrypted_data': encryptedData,
        'old_md5': oldMd5,
        'new_md5': newMd5,
        'timestamp': timestamp.toIso8601String(),
        'device_id': deviceId,
      };

  factory SyncRequest.fromJson(Map<String, dynamic> json) => SyncRequest(
        filePath: json['file_path'] as String,
        encryptedData: json['encrypted_data'] as String,
        oldMd5: json['old_md5'] as String?,
        newMd5: json['new_md5'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        deviceId: json['device_id'] as String,
      );

  String toJsonString() => jsonEncode(toJson());

  factory SyncRequest.fromJsonString(String jsonString) =>
      SyncRequest.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
}

/// 批量同步请求 - 一次推送多个文件
class BatchSyncRequest {
  /// 要同步的文件列表
  final List<SyncRequest> files;

  /// 设备标识
  final String deviceId;

  /// 请求时间戳
  final DateTime timestamp;

  BatchSyncRequest({
    required this.files,
    required this.deviceId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'files': files.map((f) => f.toJson()).toList(),
        'device_id': deviceId,
        'timestamp': timestamp.toIso8601String(),
      };

  factory BatchSyncRequest.fromJson(Map<String, dynamic> json) =>
      BatchSyncRequest(
        files: (json['files'] as List)
            .map((f) => SyncRequest.fromJson(f as Map<String, dynamic>))
            .toList(),
        deviceId: json['device_id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
