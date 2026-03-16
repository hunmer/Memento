import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../storage/storage_manager.dart';
import '../event/event_manager.dart';
import 'encryption_service.dart';
import 'sync_record_service.dart';

/// 同步结果类型
enum SyncResultType {
  /// 同步成功
  success,

  /// 没有变化
  noChanges,

  /// 冲突已解决 (服务器优先)
  conflictResolved,

  /// 错误
  error,
}

/// 同步结果
class SyncResult {
  final SyncResultType type;
  final String? message;
  final String? filePath;

  SyncResult({required this.type, this.message, this.filePath});

  bool get isSuccess =>
      type == SyncResultType.success || type == SyncResultType.noChanges;

  factory SyncResult.success({String? filePath}) =>
      SyncResult(type: SyncResultType.success, filePath: filePath);

  factory SyncResult.noChanges({String? filePath}) =>
      SyncResult(type: SyncResultType.noChanges, filePath: filePath);

  factory SyncResult.conflictResolved({String? filePath}) => SyncResult(
    type: SyncResultType.conflictResolved,
    filePath: filePath,
    message: '冲突已解决 (使用服务器版本)',
  );

  factory SyncResult.error(String message, {String? filePath}) => SyncResult(
    type: SyncResultType.error,
    message: message,
    filePath: filePath,
  );
}

/// 同步客户端服务
///
/// 负责:
/// - 文件级别的同步
/// - 端到端加密/解密
/// - 冲突处理 (服务器优先策略)
/// - 全量同步
/// - 双向同步（基于时间戳）
class SyncClientService {
  final String _serverUrl;
  final StorageManager _storage;
  final EncryptionService _encryption;
  final SyncRecordService _recordService;

  String? _token;
  String? _userId;
  String? _deviceId;

  static const String _tag = 'SyncClientService';

  /// 是否已登录
  bool get isLoggedIn => _token != null && _userId != null;

  /// 获取加密服务（用于访问加密密钥等）
  EncryptionService get encryption => _encryption;

  /// 获取同步记录服务
  SyncRecordService get recordService => _recordService;

  SyncClientService({
    required String serverUrl,
    required StorageManager storage,
    required EncryptionService encryption,
    SyncRecordService? recordService,
  }) : _serverUrl =
           serverUrl.endsWith('/')
               ? serverUrl.substring(0, serverUrl.length - 1)
               : serverUrl,
       _storage = storage,
       _encryption = encryption,
       _recordService = recordService ?? SyncRecordService();

  /// 初始化 (设置认证信息)
  Future<void> initialize({
    required String token,
    required String userId,
    required String deviceId,
  }) async {
    _token = token;
    _userId = userId;
    _deviceId = deviceId;

    // 初始化同步记录服务
    await _recordService.initialize(_storage);
    _log('初始化完成');
  }

  /// 登出
  void logout() {
    _token = null;
    _userId = null;
    _encryption.reset();
  }

  /// 同步单个文件
  ///
  /// [filePath] 相对于用户数据目录的文件路径
  Future<SyncResult> syncFile(String filePath) async {
    if (!isLoggedIn) {
      return SyncResult.error('未登录');
    }

    if (!_encryption.isInitialized) {
      return SyncResult.error('加密服务未初始化');
    }

    try {
      // 1. 读取本地文件内容
      final localContent = await _storage.readString(filePath);
      if (localContent == null) {
        return SyncResult.noChanges(filePath: filePath);
      }

      // 2. 判断文件类型并计算 MD5
      final isJsonFile = filePath.toLowerCase().endsWith('.json');
      String currentMd5;

      if (isJsonFile) {
        // JSON 文件：规范化后计算 MD5
        try {
          final localJson = jsonDecode(localContent) as Map<String, dynamic>;
          currentMd5 = _encryption.computeMd5(localJson);
        } catch (e) {
          // JSON 解析失败，按普通文本处理
          currentMd5 = _encryption.computeStringMd5(localContent);
        }
      } else {
        // 非 JSON 文件：直接计算字符串 MD5
        currentMd5 = _encryption.computeStringMd5(localContent);
      }

      // 3. 读取上次同步的 MD5 快照
      final snapshotMd5 = await _getSyncMd5(filePath);

      // 4. 如果没有变化，跳过
      if (snapshotMd5 == currentMd5) {
        return SyncResult.noChanges(filePath: filePath);
      }

      // 5. 加密数据（统一使用字符串加密）
      final encryptedData = _encryption.encryptString(localContent);

      // 6. 发送到服务器
      final response = await http.post(
        Uri.parse('$_serverUrl/api/v1/sync/push'),
        headers: _authHeaders(),
        body: jsonEncode({
          'file_path': filePath,
          'encrypted_data': encryptedData,
          'old_md5': snapshotMd5,
          'new_md5': currentMd5,
        }),
      );

      // 7. 处理响应
      if (response.statusCode == 200) {
        // 成功: 更新 MD5 快照
        await _saveSyncMd5(filePath, currentMd5);

        // 记录推送成功
        final responseData = jsonDecode(response.body);
        final serverTime =
            responseData['timestamp'] != null
                ? DateTime.parse(responseData['timestamp'] as String)
                : DateTime.now();
        await _recordService.recordUpload(filePath, serverTime);

        // 标记为最近上传（防循环）
        _recordService.markRecentUpload(filePath);

        _log('推送成功: $filePath');
        return SyncResult.success(filePath: filePath);
      } else if (response.statusCode == 409) {
        // 冲突: 服务器优先 - 自动使用服务器版本覆盖本地
        final conflict = jsonDecode(response.body);
        final serverTime =
            conflict['server_updated_at'] != null
                ? DateTime.parse(conflict['server_updated_at'] as String)
                : DateTime.now();
        await _applyServerData(
          filePath,
          conflict['server_data'] as String,
          conflict['server_md5'] as String,
          serverTime,
        );
        return SyncResult.conflictResolved(filePath: filePath);
      } else {
        final error = jsonDecode(response.body);
        return SyncResult.error(
          error['error'] ?? '同步失败: ${response.statusCode}',
          filePath: filePath,
        );
      }
    } catch (e) {
      return SyncResult.error('同步错误: $e', filePath: filePath);
    }
  }

  /// 从服务器拉取文件
  Future<SyncResult> pullFile(String filePath) async {
    if (!isLoggedIn) {
      return SyncResult.error('未登录');
    }

    if (!_encryption.isInitialized) {
      return SyncResult.error('加密服务未初始化');
    }

    try {
      final response = await http.get(
        Uri.parse('$_serverUrl/api/v1/sync/pull/$filePath'),
        headers: _authHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final serverTime =
            data['updated_at'] != null
                ? DateTime.parse(data['updated_at'] as String)
                : DateTime.now();
        await _applyServerData(
          filePath,
          data['encrypted_data'] as String,
          data['md5'] as String,
          serverTime,
        );
        return SyncResult.success(filePath: filePath);
      } else if (response.statusCode == 404) {
        // 服务器没有此文件，跳过
        return SyncResult.noChanges(filePath: filePath);
      } else {
        final error = jsonDecode(response.body);
        return SyncResult.error(
          error['error'] ?? '拉取失败: ${response.statusCode}',
          filePath: filePath,
        );
      }
    } catch (e) {
      return SyncResult.error('拉取错误: $e', filePath: filePath);
    }
  }

  /// 获取服务器文件信息（不含内容）
  Future<ServerFileInfo?> getServerFileInfo(String filePath) async {
    if (!isLoggedIn) return null;

    try {
      final response = await http.get(
        Uri.parse('$_serverUrl/api/v1/sync/info/$filePath'),
        headers: _authHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['exists'] != true) return null;

        return ServerFileInfo(
          filePath: filePath,
          exists: true,
          md5: data['md5'] as String?,
          modifiedAt:
              data['modified_at'] != null
                  ? DateTime.parse(data['modified_at'] as String)
                  : null,
          size: data['size'] as int?,
        );
      }
      return null;
    } catch (e) {
      _log('获取服务器文件信息失败: $e');
      return null;
    }
  }

  /// 双向同步单个文件
  ///
  /// 比较服务端修改时间和本地最后上传时间，决定同步方向
  Future<SyncResult> bidirectionalSync(String filePath) async {
    if (!isLoggedIn) {
      return SyncResult.error('未登录');
    }

    if (!_encryption.isInitialized) {
      return SyncResult.error('加密服务未初始化');
    }

    try {
      // 1. 获取服务端文件信息
      final serverInfo = await getServerFileInfo(filePath);

      if (serverInfo == null || !serverInfo.exists) {
        // 服务端没有此文件，推送
        _log('服务端无文件，推送: $filePath');
        return await syncFile(filePath);
      }

      // 2. 检查是否需要拉取（基于时间戳比较）
      if (_recordService.needsPull(
        filePath,
        serverInfo.modifiedAt ?? DateTime.now(),
      )) {
        // 服务端更新，拉取
        _log('服务端更新，拉取: $filePath');
        return await pullFile(filePath);
      } else {
        // 客户端更新，推送
        _log('客户端更新，推送: $filePath');
        return await syncFile(filePath);
      }
    } catch (e) {
      return SyncResult.error('双向同步错误: $e', filePath: filePath);
    }
  }

  /// 全量同步 - 使用双向同步逻辑
  Future<List<SyncResult>> fullSync() async {
    if (!isLoggedIn) {
      return [SyncResult.error('未登录')];
    }

    if (!_encryption.isInitialized) {
      return [SyncResult.error('加密服务未初始化')];
    }

    final results = <SyncResult>[];

    try {
      // 1. 获取服务器文件列表
      final listResponse = await http.get(
        Uri.parse('$_serverUrl/api/v1/sync/list'),
        headers: _authHeaders(),
      );

      if (listResponse.statusCode != 200) {
        return [SyncResult.error('获取服务器文件列表失败')];
      }

      final serverData = jsonDecode(listResponse.body);
      final serverFilePaths =
          (serverData['files'] as List).map((f) => f['path'] as String).toSet();

      // 2. 获取本地文件列表
      final localFiles = await _listLocalDataFiles();
      final localFilePaths = localFiles.map((f) => f['path']!).toSet();

      // 3. 合并所有文件路径
      final allFilePaths = <String>{...serverFilePaths, ...localFilePaths};

      // 4. 对每个文件执行双向同步
      for (final filePath in allFilePaths) {
        final result = await bidirectionalSync(filePath);
        results.add(result);
      }

      return results;
    } catch (e) {
      return [SyncResult.error('全量同步错误: $e')];
    }
  }

  /// 应用服务器数据 (冲突时或拉取时调用)
  Future<void> _applyServerData(
    String filePath,
    String encryptedData,
    String serverMd5, [
    DateTime? serverTime,
  ]) async {
    // 1. 解密服务器数据（使用字符串解密，支持任意文件类型）
    final serverContent = _encryption.decryptString(encryptedData);

    // 2. 覆盖本地文件
    await _storage.writeString(filePath, serverContent);

    // 3. 更新 MD5 快照
    await _saveSyncMd5(filePath, serverMd5);

    // 4. 记录拉取时间
    await _recordService.recordPull(filePath, serverTime ?? DateTime.now());

    // 5. 通知 UI 数据已更新
    EventManager.instance.broadcast(
      'sync_data_updated',
      SyncDataUpdatedArgs(filePath: filePath, source: 'server'),
    );

    _log('应用服务器数据: $filePath');
  }

  /// 获取文件的同步 MD5 快照
  Future<String?> _getSyncMd5(String filePath) async {
    final snapshotPath = _getSyncSnapshotPath(filePath);
    return await _storage.readString(snapshotPath);
  }

  /// 保存文件的同步 MD5 快照
  Future<void> _saveSyncMd5(String filePath, String md5) async {
    final snapshotPath = _getSyncSnapshotPath(filePath);
    await _storage.writeString(snapshotPath, md5);
  }

  /// 获取同步快照文件路径
  String _getSyncSnapshotPath(String filePath) {
    return '.sync_snapshots/$filePath.md5';
  }

  /// 列出本地数据文件
  Future<List<Map<String, String>>> _listLocalDataFiles() async {
    final files = <Map<String, String>>[];

    // 需要同步的插件目录
    final syncDirs = [
      'diary',
      'agent_chat',
      'app_images',
      'calendar',
      'calendar_album',
      'chat',
      'configs',
      'data',
      'database',
      'day',
      'nodes',
      'openai',
      'plugins',
      'reminder',
      'scripts',
      'store',
      'timer',
      'tts',
      'webview',
      'notes',
      'todo',
      'activity',
      'bill',
      'tracker',
      'goods',
      'contact',
      'habits',
      'checkin',
    ];

    for (final dir in syncDirs) {
      try {
        // 使用 StorageManager 的 getKeysWithPrefix 获取文件列表
        final keys = await _storage.getKeysWithPrefix(dir);

        for (final key in keys) {
          // 忽略临时文件和隐藏文件
          if (key.endsWith('.tmp') ||
              key.endsWith('.temp') ||
              key.endsWith('.bak') ||
              key.split('/').last.startsWith('.')) {
            continue;
          }

          try {
            // 尝试读取文件内容
            final content = await _storage.readString(key);
            if (content != null) {
              // 根据文件类型计算 MD5
              String md5Hash;
              if (key.toLowerCase().endsWith('.json')) {
                try {
                  final json = jsonDecode(content) as Map<String, dynamic>;
                  md5Hash = _encryption.computeMd5(json);
                } catch (e) {
                  // JSON 解析失败，按普通文本处理
                  md5Hash = _encryption.computeStringMd5(content);
                }
              } else {
                md5Hash = _encryption.computeStringMd5(content);
              }

              // 统一使用正斜杠作为路径分隔符
              final normalizedPath = key.replaceAll('\\', '/');
              files.add({'path': normalizedPath, 'md5': md5Hash});
            }
          } catch (e) {
            // 忽略读取失败的文件
          }
        }
      } catch (e) {
        // 忽略不存在的目录
      }
    }

    return files;
  }

  /// 获取认证请求头
  Map<String, String> _authHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_token',
      if (_deviceId != null) 'X-Device-ID': _deviceId!,
    };
  }

  /// 输出日志
  void _log(String message) {
    if (kDebugMode) {
      debugPrint('$_tag: $message');
    }
  }
}

/// 同步数据更新事件参数
class SyncDataUpdatedArgs extends EventArgs {
  final String filePath;
  final String source; // 'server' or 'local'

  SyncDataUpdatedArgs({required this.filePath, required this.source})
    : super('sync_data_updated');
}

/// 服务器文件信息
class ServerFileInfo {
  final String filePath;
  final bool exists;
  final String? md5;
  final DateTime? modifiedAt;
  final int? size;

  ServerFileInfo({
    required this.filePath,
    required this.exists,
    this.md5,
    this.modifiedAt,
    this.size,
  });
}
