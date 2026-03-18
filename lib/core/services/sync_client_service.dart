import 'dart:convert';

import 'package:http/http.dart' as http;

import '../storage/storage_manager.dart';
import '../event/event_manager.dart';
import 'encryption_service.dart';
import 'sync_record_service.dart';

/// 二进制文件扩展名列表
const _binaryExtensions = {
  '.png', '.jpg', '.jpeg', '.gif', '.webp', '.bmp', '.ico',
  '.mp3', '.mp4', '.wav', '.avi', '.mov', '.mkv',
  '.pdf', '.zip', '.tar', '.gz', '.7z', '.rar',
  '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx',
};

/// 判断文件是否为二进制文件
bool _isBinaryFile(String filePath) {
  final lowerPath = filePath.toLowerCase();
  for (final ext in _binaryExtensions) {
    if (lowerPath.endsWith(ext)) return true;
  }
  return false;
}

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

  /// MD5 快照缓存（内存中的 Map）
  Map<String, String> _md5Snapshots = {};

  /// MD5 快照 JSON 文件路径
  static const String _snapshotFilePath = '.sync_snapshots.json';

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

    // 加载 MD5 快照
    await _loadMd5Snapshots();
  }

  /// 加载 MD5 快照到内存
  Future<void> _loadMd5Snapshots() async {
    try {
      final content = await _storage.readString(_snapshotFilePath);
      if (content != null) {
        final json = jsonDecode(content) as Map<String, dynamic>;
        _md5Snapshots = json.map((key, value) => MapEntry(key, value as String));
      }
    } catch (e) {
      _md5Snapshots = {};
    }
  }

  /// 保存 MD5 快照到文件
  Future<void> _saveMd5SnapshotsToFile() async {
    try {
      await _storage.writeString(
        _snapshotFilePath,
        jsonEncode(_md5Snapshots),
      );
    } catch (e) {
      // 静默失败
    }
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
      final isBinary = _isBinaryFile(filePath);

      // 1. 读取本地文件内容
      String? localContent;
      String? base64Data;

      if (isBinary) {
        // 二进制文件：读取字节并转为 base64
        final bytes = await _storage.readBytes(filePath);
        if (bytes == null) {
          return SyncResult.noChanges(filePath: filePath);
        }
        base64Data = base64Encode(bytes);
        localContent = base64Data; // 用于计算 MD5
      } else {
        localContent = await _storage.readString(filePath);
        if (localContent == null) {
          return SyncResult.noChanges(filePath: filePath);
        }
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

      // 5. 加密数据
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
          'is_binary': isBinary, // 标记是否为二进制文件
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
          serverTime: serverTime,
          isBinary: conflict['is_binary'] as bool? ?? isBinary,
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
        final isBinary = data['is_binary'] as bool? ?? _isBinaryFile(filePath);
        await _applyServerData(
          filePath,
          data['encrypted_data'] as String,
          data['md5'] as String,
          serverTime: serverTime,
          isBinary: isBinary,
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
      return null;
    }
  }

  /// 双向同步单个文件
  ///
  /// 同步逻辑顺序：
  /// 1. 检查本地文件是否存在
  /// 2. 检查服务端文件是否存在
  /// 3. 根据存在性决定同步方向
  /// 4. 两边都存在时，比较时间戳决定方向
  ///
  /// [serverFileEntry] 可选的服务端文件信息，用于避免重复请求
  Future<SyncResult> bidirectionalSync(
    String filePath, {
    ServerFileEntry? serverFileEntry,
  }) async {
    if (!isLoggedIn) {
      return SyncResult.error('未登录');
    }

    if (!_encryption.isInitialized) {
      return SyncResult.error('加密服务未初始化');
    }

    try {
      // 1. 检查本地文件是否存在
      final localExists = await _storage.exists(filePath);

      // 2. 获取服务端文件信息（优先使用传入的信息，避免重复请求）
      final serverInfo = serverFileEntry;
      final serverExists = serverInfo != null;

      // 3. 根据存在性决定同步方向
      if (!localExists && !serverExists) {
        // 两边都不存在，跳过
        return SyncResult.noChanges(filePath: filePath);
      }

      if (!localExists && serverExists) {
        // 本地不存在，服务端存在 → 下载
        return await pullFile(filePath);
      }

      if (localExists && !serverExists) {
        // 本地存在，服务端不存在 → 上传
        return await syncFile(filePath);
      }

      // 4. 两边都存在，比较时间戳决定方向
      if (_recordService.needsPull(
        filePath,
        serverInfo?.updatedAt ?? DateTime.now(),
      )) {
        // 服务端更新，拉取
        return await pullFile(filePath);
      } else {
        // 客户端更新，推送
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
      // 1. 获取服务端完整文件索引（递归获取所有文件）
      final serverIndex = await getServerFileIndex();
      if (serverIndex == null) {
        return [SyncResult.error('获取服务端文件索引失败')];
      }

      // 2. 提取服务端文件路径和 Map
      final serverFilesMap = serverIndex.filesByPath;
      final serverFilePaths = serverFilesMap.keys.toSet();

      // 3. 获取本地文件列表（递归）
      final localFiles = await _listLocalDataFiles();
      final localFilePaths = localFiles.map((f) => f['path']!).toSet();

      // 4. 合并所有文件路径
      final allFilePaths = <String>{...serverFilePaths, ...localFilePaths};

      // 5. 对每个文件执行双向同步（使用预取的服务端索引）
      for (final filePath in allFilePaths) {
        final result = await bidirectionalSync(
          filePath,
          serverFileEntry: serverFilesMap[filePath],
        );
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
    String serverMd5, {
    DateTime? serverTime,
    bool isBinary = false,
  }) async {
    // 1. 解密服务器数据
    final serverContent = _encryption.decryptString(encryptedData);

    // 2. 覆盖本地文件
    if (isBinary || _isBinaryFile(filePath)) {
      // 二进制文件：从 base64 解码后写入
      final bytes = base64Decode(serverContent);
      await _storage.writeBytes(filePath, bytes);
    } else {
      // 文本文件：直接写入字符串
      await _storage.writeString(filePath, serverContent);
    }

    // 3. 更新 MD5 快照
    await _saveSyncMd5(filePath, serverMd5);

    // 4. 记录拉取时间
    await _recordService.recordPull(filePath, serverTime ?? DateTime.now());

    // 5. 通知 UI 数据已更新
    EventManager.instance.broadcast(
      'sync_data_updated',
      SyncDataUpdatedArgs(filePath: filePath, source: 'server'),
    );
  }

  /// 获取文件的同步 MD5 快照
  Future<String?> _getSyncMd5(String filePath) async {
    return _md5Snapshots[filePath];
  }

  /// 保存文件的同步 MD5 快照
  Future<void> _saveSyncMd5(String filePath, String md5) async {
    _md5Snapshots[filePath] = md5;
    await _saveMd5SnapshotsToFile();
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
            final isBinary = _isBinaryFile(key);
            String? content;

            if (isBinary) {
              // 二进制文件：读取字节并转为 base64
              final bytes = await _storage.readBytes(key);
              if (bytes != null) {
                content = base64Encode(bytes);
              }
            } else {
              // 文本文件：读取字符串
              content = await _storage.readString(key);
            }

            if (content != null) {
              // 根据文件类型计算 MD5
              String md5Hash;
              if (!isBinary && key.toLowerCase().endsWith('.json')) {
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

  // ========== Git 风格同步方法 ==========

  /// 获取服务端完整文件索引
  ///
  /// 返回所有文件的 path、md5、size、updated_at 信息
  Future<ServerFileIndex?> getServerFileIndex() async {
    if (!isLoggedIn) return null;

    try {
      final response = await http.get(
        Uri.parse('$_serverUrl/api/v1/sync/index'),
        headers: _authHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return ServerFileIndex.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 计算同步差异
  ///
  /// 对比客户端和服务端的文件列表，返回差异
  SyncDiff computeSyncDiff(
    ServerFileIndex serverIndex,
    List<Map<String, String>> localFiles,
  ) {
    final toDownload = <ServerFileEntry>[];
    final toUpload = <LocalFileEntry>[];
    final conflicts = <ConflictEntry>[];

    final serverFilesMap = serverIndex.filesByPath;
    final localFilesMap = <String, String>{};
    for (final f in localFiles) {
      localFilesMap[f['path']!] = f['md5']!;
    }

    // 找出所有唯一的文件路径
    final allPaths = <String>{
      ...serverFilesMap.keys,
      ...localFilesMap.keys,
    };

    for (final path in allPaths) {
      final serverFile = serverFilesMap[path];
      final localMd5 = localFilesMap[path];

      if (serverFile != null && localMd5 == null) {
        // 服务端有但客户端没有 → 需要下载
        toDownload.add(serverFile);
      } else if (serverFile == null && localMd5 != null) {
        // 客户端有但服务端没有 → 需要上传
        toUpload.add(LocalFileEntry(path: path, md5: localMd5));
      } else if (serverFile != null && localMd5 != null) {
        // 两边都有，比较 MD5
        if (serverFile.md5 != localMd5) {
          // MD5 不同 → 冲突
          conflicts.add(ConflictEntry(
            path: path,
            clientMd5: localMd5,
            serverMd5: serverFile.md5,
            serverModifiedAt: serverFile.updatedAt,
          ));
        }
        // MD5 相同 → 无需处理
      }
    }

    return SyncDiff(
      toDownload: toDownload,
      toUpload: toUpload,
      conflicts: conflicts,
    );
  }

  /// 完整双向同步（Git 风格）
  ///
  /// 1. 获取服务端索引
  /// 2. 获取本地文件列表
  /// 3. 计算差异
  /// 4. 下载服务端新增文件
  /// 5. 上传客户端新增文件
  /// 6. 处理冲突（比较修改时间，新的覆盖旧的）
  Future<List<SyncResult>> fullBidirectionalSync() async {
    if (!isLoggedIn) {
      return [SyncResult.error('未登录')];
    }

    if (!_encryption.isInitialized) {
      return [SyncResult.error('加密服务未初始化')];
    }

    final results = <SyncResult>[];

    try {
      // 1. 获取服务端文件索引
      final serverIndex = await getServerFileIndex();
      if (serverIndex == null) {
        return [SyncResult.error('获取服务端文件索引失败')];
      }

      // 2. 获取本地文件列表
      final localFiles = await _listLocalDataFiles();

      // 3. 计算差异
      final diff = computeSyncDiff(serverIndex, localFiles);

      // 4. 下载服务端新增文件
      for (final file in diff.toDownload) {
        final result = await pullFile(file.path);
        results.add(result);
      }

      // 5. 上传客户端新增文件
      for (final file in diff.toUpload) {
        final result = await syncFile(file.path);
        results.add(result);
      }

      // 6. 处理冲突（基于修改时间，新的覆盖旧的）
      for (final conflict in diff.conflicts) {
        // 获取本地最后上传时间
        final lastUpload = _recordService.getRecord(conflict.path)?.lastUploadTime;
        final serverTime = conflict.serverModifiedAt;

        if (lastUpload != null && lastUpload.isAfter(serverTime)) {
          // 客户端更新，推送
          final result = await syncFile(conflict.path);
          results.add(result);
        } else {
          // 服务端更新或无法判断，拉取（服务器优先）
          final result = await pullFile(conflict.path);
          results.add(result);
        }
      }

      return results;
    } catch (e) {
      return [SyncResult.error('完整双向同步错误: $e')];
    }
  }

  /// 强制同步到服务端
  ///
  /// 1. 上传所有客户端文件到服务端
  /// 2. 删除服务端存在但客户端没有的文件
  Future<ForceSyncResult> forceSyncToServer() async {
    if (!isLoggedIn) {
      return ForceSyncResult(uploaded: 0, downloaded: 0, deleted: 0, errors: ['未登录']);
    }

    if (!_encryption.isInitialized) {
      return ForceSyncResult(uploaded: 0, downloaded: 0, deleted: 0, errors: ['加密服务未初始化']);
    }

    int uploaded = 0;
    int deleted = 0;
    final errors = <String>[];

    try {
      // 1. 获取本地文件列表
      final localFiles = await _listLocalDataFiles();
      final localPaths = localFiles.map((f) => f['path']!).toSet();

      // 2. 获取服务端文件索引
      final serverIndex = await getServerFileIndex();
      if (serverIndex == null) {
        return ForceSyncResult(uploaded: 0, downloaded: 0, deleted: 0, errors: ['获取服务端文件索引失败']);
      }

      // 3. 找出服务端多余的文件（服务端有但客户端没有的）
      final toDeleteOnServer = <String>[];
      for (final serverFile in serverIndex.files) {
        if (!localPaths.contains(serverFile.path)) {
          toDeleteOnServer.add(serverFile.path);
        }
      }

      // 4. 删除服务端多余的文件
      if (toDeleteOnServer.isNotEmpty) {
        final deleteResult = await _batchDeleteServerFiles(toDeleteOnServer);
        deleted = deleteResult['deleted'] as int;
        if (deleteResult['errors'] != null) {
          errors.addAll(List<String>.from(deleteResult['errors']));
        }
      }

      // 5. 上传所有本地文件
      for (final file in localFiles) {
        final path = file['path']!;
        try {
          // 直接推送，不检查 old_md5（强制覆盖）
          final result = await _forcePushFile(path);
          if (result.isSuccess) {
            uploaded++;
          } else {
            errors.add('$path: ${result.message}');
          }
        } catch (e) {
          errors.add('$path: $e');
        }
      }

      return ForceSyncResult(
        uploaded: uploaded,
        downloaded: 0,
        deleted: deleted,
        errors: errors,
      );
    } catch (e) {
      return ForceSyncResult(uploaded: 0, downloaded: 0, deleted: 0, errors: ['$e']);
    }
  }

  /// 强制同步到客户端
  ///
  /// 1. 下载所有服务端文件到客户端
  /// 2. 删除客户端存在但服务端没有的文件
  Future<ForceSyncResult> forceSyncToClient() async {
    if (!isLoggedIn) {
      return ForceSyncResult(uploaded: 0, downloaded: 0, deleted: 0, errors: ['未登录']);
    }

    if (!_encryption.isInitialized) {
      return ForceSyncResult(uploaded: 0, downloaded: 0, deleted: 0, errors: ['加密服务未初始化']);
    }

    int downloaded = 0;
    int deleted = 0;
    final errors = <String>[];

    try {
      // 1. 获取服务端文件索引
      final serverIndex = await getServerFileIndex();
      if (serverIndex == null) {
        return ForceSyncResult(uploaded: 0, downloaded: 0, deleted: 0, errors: ['获取服务端文件索引失败']);
      }

      final serverPaths = serverIndex.files.map((f) => f.path).toSet();

      // 2. 获取本地文件列表
      final localFiles = await _listLocalDataFiles();
      final localPaths = localFiles.map((f) => f['path']!).toSet();

      // 3. 找出客户端多余的文件（客户端有但服务端没有的）
      final toDeleteOnClient = <String>[];
      for (final localPath in localPaths) {
        if (!serverPaths.contains(localPath)) {
          toDeleteOnClient.add(localPath);
        }
      }

      // 4. 删除客户端多余的文件
      for (final path in toDeleteOnClient) {
        try {
          await deleteLocalFile(path);
          deleted++;
        } catch (e) {
          errors.add('删除失败 $path: $e');
        }
      }

      // 5. 下载所有服务端文件
      for (final serverFile in serverIndex.files) {
        try {
          final result = await pullFile(serverFile.path);
          if (result.isSuccess) {
            downloaded++;
          } else if (result.type != SyncResultType.noChanges) {
            errors.add('${serverFile.path}: ${result.message}');
          }
        } catch (e) {
          errors.add('${serverFile.path}: $e');
        }
      }

      return ForceSyncResult(
        uploaded: 0,
        downloaded: downloaded,
        deleted: deleted,
        errors: errors,
      );
    } catch (e) {
      return ForceSyncResult(uploaded: 0, downloaded: 0, deleted: 0, errors: ['$e']);
    }
  }

  /// 删除本地文件（包括数据文件和 MD5 快照）
  Future<void> deleteLocalFile(String filePath) async {
    // 1. 删除数据文件
    await _storage.delete(filePath);

    // 2. 删除 MD5 快照
    _md5Snapshots.remove(filePath);
    await _saveMd5SnapshotsToFile();

    // 3. 清除同步记录
    await _recordService.removeRecord(filePath);

    // 4. 通知 UI 数据已更新
    EventManager.instance.broadcast(
      'sync_data_updated',
      SyncDataUpdatedArgs(filePath: filePath, source: 'deleted'),
    );
  }

  /// 强制推送文件（不检查 old_md5）
  Future<SyncResult> _forcePushFile(String filePath) async {
    if (!isLoggedIn) {
      return SyncResult.error('未登录');
    }

    try {
      final isBinary = _isBinaryFile(filePath);

      // 读取本地文件内容
      String? localContent;
      if (isBinary) {
        final bytes = await _storage.readBytes(filePath);
        if (bytes == null) {
          return SyncResult.noChanges(filePath: filePath);
        }
        localContent = base64Encode(bytes);
      } else {
        localContent = await _storage.readString(filePath);
        if (localContent == null) {
          return SyncResult.noChanges(filePath: filePath);
        }
      }

      // 计算 MD5
      String currentMd5;
      final isJsonFile = filePath.toLowerCase().endsWith('.json');
      if (isJsonFile) {
        try {
          final localJson = jsonDecode(localContent) as Map<String, dynamic>;
          currentMd5 = _encryption.computeMd5(localJson);
        } catch (e) {
          currentMd5 = _encryption.computeStringMd5(localContent);
        }
      } else {
        currentMd5 = _encryption.computeStringMd5(localContent);
      }

      // 加密数据
      final encryptedData = _encryption.encryptString(localContent);

      // 强制推送（不提供 old_md5，直接覆盖）
      final response = await http.post(
        Uri.parse('$_serverUrl/api/v1/sync/push'),
        headers: _authHeaders(),
        body: jsonEncode({
          'file_path': filePath,
          'encrypted_data': encryptedData,
          'old_md5': null, // 不检查冲突，强制覆盖
          'new_md5': currentMd5,
          'is_binary': isBinary,
        }),
      );

      if (response.statusCode == 200) {
        await _saveSyncMd5(filePath, currentMd5);

        final responseData = jsonDecode(response.body);
        final serverTime = responseData['timestamp'] != null
            ? DateTime.parse(responseData['timestamp'] as String)
            : DateTime.now();
        await _recordService.recordUpload(filePath, serverTime);
        _recordService.markRecentUpload(filePath);

        return SyncResult.success(filePath: filePath);
      } else {
        final error = jsonDecode(response.body);
        return SyncResult.error(
          error['error'] ?? '推送失败: ${response.statusCode}',
          filePath: filePath,
        );
      }
    } catch (e) {
      return SyncResult.error('推送错误: $e', filePath: filePath);
    }
  }

  /// 批量删除服务端文件
  Future<Map<String, dynamic>> _batchDeleteServerFiles(List<String> filePaths) async {
    try {
      final response = await http.post(
        Uri.parse('$_serverUrl/api/v1/sync/batch-delete'),
        headers: _authHeaders(),
        body: jsonEncode({'file_paths': filePaths}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'deleted': data['deleted_count'] as int? ?? 0,
          'errors': data['errors'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'deleted': 0,
          'errors': [error['error'] ?? '批量删除失败'],
        };
      }
    } catch (e) {
      return {'deleted': 0, 'errors': ['$e']};
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

/// 服务端文件索引条目
class ServerFileEntry {
  final String path;
  final String md5;
  final int size;
  final DateTime updatedAt;

  ServerFileEntry({
    required this.path,
    required this.md5,
    required this.size,
    required this.updatedAt,
  });

  factory ServerFileEntry.fromJson(Map<String, dynamic> json) {
    return ServerFileEntry(
      path: json['path'] as String,
      md5: json['md5'] as String,
      size: json['size'] as int,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

/// 服务端文件索引
class ServerFileIndex {
  final DateTime generatedAt;
  final List<ServerFileEntry> files;
  final int totalFiles;
  final int totalSize;

  ServerFileIndex({
    required this.generatedAt,
    required this.files,
    required this.totalFiles,
    required this.totalSize,
  });

  factory ServerFileIndex.fromJson(Map<String, dynamic> json) {
    final indexData = json['index'] as Map<String, dynamic>;
    final filesList = indexData['files'] as List;
    return ServerFileIndex(
      generatedAt: DateTime.parse(indexData['generated_at'] as String),
      files: filesList
          .map((f) => ServerFileEntry.fromJson(f as Map<String, dynamic>))
          .toList(),
      totalFiles: indexData['total_files'] as int,
      totalSize: indexData['total_size'] as int,
    );
  }

  /// 按 path 查找文件的 Map
  Map<String, ServerFileEntry> get filesByPath {
    return {for (final f in files) f.path: f};
  }
}

/// 本地文件条目
class LocalFileEntry {
  final String path;
  final String md5;

  LocalFileEntry({required this.path, required this.md5});
}

/// 同步差异
class SyncDiff {
  /// 服务端有但客户端没有的文件（需要下载）
  final List<ServerFileEntry> toDownload;

  /// 客户端有但服务端没有的文件（需要上传）
  final List<LocalFileEntry> toUpload;

  /// 两边都有但 MD5 不同的文件（冲突）
  final List<ConflictEntry> conflicts;

  SyncDiff({
    required this.toDownload,
    required this.toUpload,
    required this.conflicts,
  });
}

/// 冲突条目
class ConflictEntry {
  final String path;
  final String clientMd5;
  final String serverMd5;
  final DateTime? clientModifiedAt;
  final DateTime serverModifiedAt;

  ConflictEntry({
    required this.path,
    required this.clientMd5,
    required this.serverMd5,
    this.clientModifiedAt,
    required this.serverModifiedAt,
  });
}

/// 强制同步结果
class ForceSyncResult {
  final int uploaded;
  final int downloaded;
  final int deleted;
  final List<String> errors;

  ForceSyncResult({
    required this.uploaded,
    required this.downloaded,
    required this.deleted,
    required this.errors,
  });
}
