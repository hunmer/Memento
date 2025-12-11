import 'dart:convert';

/// 同步响应状态
enum SyncStatus {
  /// 同步成功
  success,

  /// 发生冲突 (MD5 不匹配)
  conflict,

  /// 文件未找到 (拉取时)
  notFound,

  /// 服务器错误
  error,

  /// 未授权
  unauthorized,
}

/// 同步响应模型 - 服务器返回给客户端
class SyncResponse {
  /// 响应状态
  final SyncStatus status;

  /// 文件路径
  final String filePath;

  /// 消息说明
  final String? message;

  /// 新的 MD5 (成功时返回)
  final String? newMd5;

  /// 服务器时间戳
  final DateTime timestamp;

  /// 冲突时返回的服务器数据 (加密后)
  final String? serverData;

  /// 冲突时返回的服务器 MD5
  final String? serverMd5;

  /// 服务器数据的更新时间 (冲突时)
  final DateTime? serverUpdatedAt;

  SyncResponse({
    required this.status,
    required this.filePath,
    this.message,
    this.newMd5,
    required this.timestamp,
    this.serverData,
    this.serverMd5,
    this.serverUpdatedAt,
  });

  /// 是否成功
  bool get isSuccess => status == SyncStatus.success;

  /// 是否冲突
  bool get isConflict => status == SyncStatus.conflict;

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'file_path': filePath,
        'message': message,
        'new_md5': newMd5,
        'timestamp': timestamp.toIso8601String(),
        'server_data': serverData,
        'server_md5': serverMd5,
        'server_updated_at': serverUpdatedAt?.toIso8601String(),
      };

  factory SyncResponse.fromJson(Map<String, dynamic> json) => SyncResponse(
        status: SyncStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => SyncStatus.error,
        ),
        filePath: json['file_path'] as String,
        message: json['message'] as String?,
        newMd5: json['new_md5'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
        serverData: json['server_data'] as String?,
        serverMd5: json['server_md5'] as String?,
        serverUpdatedAt: json['server_updated_at'] != null
            ? DateTime.parse(json['server_updated_at'] as String)
            : null,
      );

  String toJsonString() => jsonEncode(toJson());

  factory SyncResponse.fromJsonString(String jsonString) =>
      SyncResponse.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

  /// 创建成功响应
  factory SyncResponse.success({
    required String filePath,
    required String newMd5,
  }) =>
      SyncResponse(
        status: SyncStatus.success,
        filePath: filePath,
        newMd5: newMd5,
        timestamp: DateTime.now(),
        message: 'Sync successful',
      );

  /// 创建冲突响应
  factory SyncResponse.conflict({
    required String filePath,
    required String serverData,
    required String serverMd5,
    required DateTime serverUpdatedAt,
  }) =>
      SyncResponse(
        status: SyncStatus.conflict,
        filePath: filePath,
        timestamp: DateTime.now(),
        message: 'MD5 mismatch - server data has changed',
        serverData: serverData,
        serverMd5: serverMd5,
        serverUpdatedAt: serverUpdatedAt,
      );

  /// 创建错误响应
  factory SyncResponse.error({
    required String filePath,
    required String message,
  }) =>
      SyncResponse(
        status: SyncStatus.error,
        filePath: filePath,
        timestamp: DateTime.now(),
        message: message,
      );
}


/// 文件列表响应
class FileListResponse {
  /// 文件列表
  final List<FileInfo> files;

  /// 服务器时间戳
  final DateTime timestamp;

  FileListResponse({
    required this.files,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'files': files.map((f) => f.toJson()).toList(),
        'timestamp': timestamp.toIso8601String(),
      };

  factory FileListResponse.fromJson(Map<String, dynamic> json) =>
      FileListResponse(
        files: (json['files'] as List)
            .map((f) => FileInfo.fromJson(f as Map<String, dynamic>))
            .toList(),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

/// 拉取响应
class PullResponse {
  /// 加密后的数据
  final String encryptedData;

  /// 数据 MD5
  final String md5;

  /// 更新时间
  final DateTime updatedAt;

  PullResponse({
    required this.encryptedData,
    required this.md5,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'encrypted_data': encryptedData,
        'md5': md5,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory PullResponse.fromJson(Map<String, dynamic> json) => PullResponse(
        encryptedData: json['encrypted_data'] as String,
        md5: json['md5'] as String,
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}
/// 文件信息 - 用于列表同步
class FileInfo {
  /// 文件路径 (相对路径)
  final String path;

  /// 文件大小 (字节)
  final int size;

  /// 文件 MD5
  final String md5;

  /// 最后更新时间
  final DateTime updatedAt;

  FileInfo({
    required this.path,
    required this.size,
    required this.md5,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'path': path,
        'size': size,
        'md5': md5,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory FileInfo.fromJson(Map<String, dynamic> json) => FileInfo(
        path: json['path'] as String,
        size: json['size'] as int,
        md5: json['md5'] as String,
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}
