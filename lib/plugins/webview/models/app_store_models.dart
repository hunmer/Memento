import 'package:flutter/foundation.dart';

/// 下载状态枚举
enum DownloadStatus {
  pending,      // 等待下载
  downloading,  // 下载中
  verifying,    // 校验中
  completed,    // 已完成
  failed,       // 失败
}

/// 安装任务状态枚举
enum InstallTaskStatus {
  downloading,  // 下载中
  installing,   // 安装中（创建卡片）
  completed,    // 完成
  failed,       // 失败
}

/// 应用商场源配置模型
class AppStoreSource {
  final String id;              // UUID
  final String name;            // 源名称
  final String url;             // JSON URL
  final String baseUrl;         // 文件下载基础URL
  final bool isDefault;         // 是否默认源
  final DateTime createdAt;
  final DateTime? lastFetchedAt;
  final int? appCount;          // 缓存的应用数量

  AppStoreSource({
    required this.id,
    required this.name,
    required this.url,
    required this.baseUrl,
    this.isDefault = false,
    required this.createdAt,
    this.lastFetchedAt,
    this.appCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'baseUrl': baseUrl,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'lastFetchedAt': lastFetchedAt?.toIso8601String(),
      'appCount': appCount,
    };
  }

  factory AppStoreSource.fromJson(Map<String, dynamic> json) {
    return AppStoreSource(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      baseUrl: json['baseUrl'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastFetchedAt: json['lastFetchedAt'] != null
          ? DateTime.parse(json['lastFetchedAt'] as String)
          : null,
      appCount: json['appCount'] as int?,
    );
  }

  AppStoreSource copyWith({
    String? id,
    String? name,
    String? url,
    String? baseUrl,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? lastFetchedAt,
    int? appCount,
  }) {
    return AppStoreSource(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      baseUrl: baseUrl ?? this.baseUrl,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
      appCount: appCount ?? this.appCount,
    );
  }
}

/// 小应用信息模型
class MiniApp {
  final String id;              // 应用唯一标识（从title生成或使用提供的ID）
  final String title;           // 应用名称
  final String? icon;           // 图标URL
  final String? desc;           // 描述
  final String? author;         // 作者
  final String? homepage;       // 应用主页URL
  final String filesUrl;        // 文件列表JSON URL
  final String version;         // 版本号
  final List<String> tags;      // 标签
  final List<String> permissions; // 权限列表
  final String sourceId;        // 所属源ID

  // 运行时状态（不持久化）
  bool isInstalled;             // 是否已安装
  String? installedVersion;     // 已安装版本

  MiniApp({
    required this.id,
    required this.title,
    this.icon,
    this.desc,
    this.author,
    this.homepage,
    required this.filesUrl,
    required this.version,
    this.tags = const [],
    this.permissions = const [],
    required this.sourceId,
    this.isInstalled = false,
    this.installedVersion,
  });

  /// 从JSON创建（不包含运行时状态）
  factory MiniApp.fromJson(Map<String, dynamic> json, String sourceId) {
    // 生成应用ID：优先使用提供的ID，否则从title生成
    String generateId(String title) {
      return title
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
          .replaceAll(RegExp(r'^_+|_+$'), '');
    }

    final id = json['id'] as String? ?? generateId(json['title'] as String);

    return MiniApp(
      id: id,
      title: json['title'] as String,
      icon: json['icon'] as String?,
      desc: json['desc'] as String?,
      author: json['author'] as String?,
      homepage: json['homepage'] as String?,
      filesUrl: json['files'] as String,
      version: json['version'] as String,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      permissions: (json['permissions'] as List<dynamic>?)?.cast<String>() ?? [],
      sourceId: sourceId,
    );
  }

  /// 是否有更新
  bool get hasUpdate => isInstalled && installedVersion != null && installedVersion != version;

  /// 显示用的版本号
  String get displayVersion => installedVersion ?? version;
}

/// 应用文件模型
class AppFile {
  final String path;            // 相对路径 a/b/c.js
  final String md5;             // MD5校验值
  final int size;               // 文件大小（字节）

  // 运行时状态
  DownloadStatus status;        // 下载状态
  int downloadedBytes;          // 已下载字节数
  String? error;                // 错误信息

  AppFile({
    required this.path,
    required this.md5,
    required this.size,
    this.status = DownloadStatus.pending,
    this.downloadedBytes = 0,
    this.error,
  });

  factory AppFile.fromJson(Map<String, dynamic> json) {
    return AppFile(
      path: json['path'] as String,
      md5: json['md5'] as String,
      size: json['size'] as int,
    );
  }

  /// 下载进度（0.0 - 1.0）
  double get progress => size > 0 ? downloadedBytes / size : 0.0;
}

/// 安装任务模型
class InstallTask {
  final String appId;
  final String appName;
  final List<AppFile> files;
  final DateTime startTime;

  InstallTaskStatus status;
  int completedFiles;
  String? error;

  InstallTask({
    required this.appId,
    required this.appName,
    required this.files,
    required this.startTime,
    this.status = InstallTaskStatus.downloading,
    this.completedFiles = 0,
    this.error,
  });

  /// 文件总数
  int get totalFiles => files.length;

  /// 总字节数
  int get totalBytes => files.fold(0, (sum, file) => sum + file.size);

  /// 已下载字节数
  int get downloadedBytes => files.fold(0, (sum, file) => sum + file.downloadedBytes);

  /// 总体下载进度（0.0 - 1.0）
  double get progress => totalBytes > 0 ? downloadedBytes / totalBytes : 0.0;
}

/// 已安装应用记录（用于持久化）
class InstalledApp {
  final String appId;
  final String version;
  final DateTime installedAt;
  final String sourceId;
  final String cardId;          // 关联的WebViewCard ID

  InstalledApp({
    required this.appId,
    required this.version,
    required this.installedAt,
    required this.sourceId,
    required this.cardId,
  });

  Map<String, dynamic> toJson() {
    return {
      'appId': appId,
      'version': version,
      'installedAt': installedAt.toIso8601String(),
      'sourceId': sourceId,
      'cardId': cardId,
    };
  }

  factory InstalledApp.fromJson(Map<String, dynamic> json) {
    return InstalledApp(
      appId: json['appId'] as String,
      version: json['version'] as String,
      installedAt: DateTime.parse(json['installedAt'] as String),
      sourceId: json['sourceId'] as String,
      cardId: json['cardId'] as String,
    );
  }
}
