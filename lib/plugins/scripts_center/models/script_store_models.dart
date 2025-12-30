/// 下载状态枚举
enum ScriptDownloadStatus {
  pending,      // 等待下载
  downloading,  // 下载中
  verifying,    // 校验中
  completed,    // 已完成
  failed,       // 失败
}

/// 安装任务状态枚举
enum ScriptInstallTaskStatus {
  downloading,  // 下载中
  installing,   // 安装中
  completed,    // 完成
  failed,       // 失败
}

/// 脚本商场源配置模型
class ScriptStoreSource {
  final String id;              // UUID
  final String name;            // 源名称
  final String url;             // JSON URL
  final String baseUrl;         // 文件下载基础URL
  final bool isDefault;         // 是否默认源
  final DateTime createdAt;
  final DateTime? lastFetchedAt;
  final int? scriptCount;       // 缓存的脚本数量

  ScriptStoreSource({
    required this.id,
    required this.name,
    required this.url,
    required this.baseUrl,
    this.isDefault = false,
    required this.createdAt,
    this.lastFetchedAt,
    this.scriptCount,
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
      'scriptCount': scriptCount,
    };
  }

  factory ScriptStoreSource.fromJson(Map<String, dynamic> json) {
    return ScriptStoreSource(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      baseUrl: json['baseUrl'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastFetchedAt: json['lastFetchedAt'] != null
          ? DateTime.parse(json['lastFetchedAt'] as String)
          : null,
      scriptCount: json['scriptCount'] as int?,
    );
  }

  ScriptStoreSource copyWith({
    String? id,
    String? name,
    String? url,
    String? baseUrl,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? lastFetchedAt,
    int? scriptCount,
  }) {
    return ScriptStoreSource(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      baseUrl: baseUrl ?? this.baseUrl,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
      scriptCount: scriptCount ?? this.scriptCount,
    );
  }
}

/// 脚本商店信息模型
class ScriptStoreItem {
  final String id;              // 脚本唯一标识
  final String name;            // 脚本名称
  final String? icon;           // 图标（emoji或MaterialIcons代码）
  final String? description;    // 描述
  final String? author;         // 作者
  final String? homepage;       // 主页URL
  final String filesUrl;        // 文件列表JSON URL
  final String version;         // 版本号
  final List<String> tags;      // 标签
  final List<String> permissions; // 权限列表
  final String sourceId;        // 所属源ID

  // 运行时状态（不持久化）
  bool isInstalled;             // 是否已安装
  String? installedVersion;     // 已安装版本

  ScriptStoreItem({
    required this.id,
    required this.name,
    this.icon,
    this.description,
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
  factory ScriptStoreItem.fromJson(Map<String, dynamic> json, String sourceId) {
    return ScriptStoreItem(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      description: json['description'] as String?,
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

/// 脚本文件模型
class ScriptFile {
  final String path;            // 相对路径 metadata.json 或 script.js
  final String md5;             // MD5校验值
  final int size;               // 文件大小（字节）

  // 运行时状态
  ScriptDownloadStatus status;  // 下载状态
  int downloadedBytes;          // 已下载字节数
  String? error;                // 错误信息

  ScriptFile({
    required this.path,
    required this.md5,
    required this.size,
    this.status = ScriptDownloadStatus.pending,
    this.downloadedBytes = 0,
    this.error,
  });

  factory ScriptFile.fromJson(Map<String, dynamic> json) {
    return ScriptFile(
      path: json['path'] as String,
      md5: json['md5'] as String,
      size: json['size'] as int,
    );
  }

  /// 下载进度（0.0 - 1.0）
  double get progress => size > 0 ? downloadedBytes / size : 0.0;
}

/// 脚本安装任务模型
class ScriptInstallTask {
  final String scriptId;
  final String scriptName;
  final List<ScriptFile> files;
  final DateTime startTime;

  ScriptInstallTaskStatus status;
  int completedFiles;
  String? error;

  ScriptInstallTask({
    required this.scriptId,
    required this.scriptName,
    required this.files,
    required this.startTime,
    this.status = ScriptInstallTaskStatus.downloading,
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

/// 已安装脚本记录（用于持久化）
class InstalledScript {
  final String scriptId;
  final String version;
  final DateTime installedAt;
  final String sourceId;

  InstalledScript({
    required this.scriptId,
    required this.version,
    required this.installedAt,
    required this.sourceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'scriptId': scriptId,
      'version': version,
      'installedAt': installedAt.toIso8601String(),
      'sourceId': sourceId,
    };
  }

  factory InstalledScript.fromJson(Map<String, dynamic> json) {
    return InstalledScript(
      scriptId: json['scriptId'] as String,
      version: json['version'] as String,
      installedAt: DateTime.parse(json['installedAt'] as String),
      sourceId: json['sourceId'] as String,
    );
  }
}
