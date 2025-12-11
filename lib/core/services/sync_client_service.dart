import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../storage/storage_manager.dart';
import '../event/event_manager.dart';
import 'encryption_service.dart';

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
class SyncClientService {
  final String _serverUrl;
  final StorageManager _storage;
  final EncryptionService _encryption;

  String? _token;
  String? _userId;
  String? _deviceId;

  /// 是否已登录
  bool get isLoggedIn => _token != null && _userId != null;

  SyncClientService({
    required String serverUrl,
    required StorageManager storage,
    required EncryptionService encryption,
  }) : _serverUrl =
           serverUrl.endsWith('/')
               ? serverUrl.substring(0, serverUrl.length - 1)
               : serverUrl,
       _storage = storage,
       _encryption = encryption;

  /// 初始化 (设置认证信息)
  void initialize({
    required String token,
    required String userId,
    required String deviceId,
  }) {
    _token = token;
    _userId = userId;
    _deviceId = deviceId;
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
      // 1. 读取本地文件
      final localContent = await _storage.readString(filePath);
      if (localContent == null) {
        return SyncResult.noChanges(filePath: filePath);
      }

      final localJson = jsonDecode(localContent) as Map<String, dynamic>;

      // 2. 读取上次同步的 MD5 快照
      final snapshotMd5 = await _getSyncMd5(filePath);
      final currentMd5 = _encryption.computeMd5(localJson);

      // 3. 如果没有变化，跳过
      if (snapshotMd5 == currentMd5) {
        return SyncResult.noChanges(filePath: filePath);
      }

      // 4. 加密数据
      final encryptedData = _encryption.encryptData(localJson);

      // 5. 发送到服务器
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

      // 6. 处理响应
      if (response.statusCode == 200) {
        // 成功: 更新 MD5 快照
        await _saveSyncMd5(filePath, currentMd5);
        return SyncResult.success(filePath: filePath);
      } else if (response.statusCode == 409) {
        // 冲突: 服务器优先 - 自动使用服务器版本覆盖本地
        final conflict = jsonDecode(response.body);
        await _applyServerData(
          filePath,
          conflict['server_data'] as String,
          conflict['server_md5'] as String,
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
        await _applyServerData(
          filePath,
          data['encrypted_data'] as String,
          data['md5'] as String,
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

  /// 全量同步 - 比较本地和服务器文件列表
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
      final serverFiles =
          (serverData['files'] as List)
              .map(
                (f) => {'path': f['path'] as String, 'md5': f['md5'] as String},
              )
              .toList();

      // 2. 获取本地文件列表
      final localFiles = await _listLocalDataFiles();

      // 3. 处理服务器文件 (拉取新的或更新的)
      for (final serverFile in serverFiles) {
        final path = serverFile['path']!;
        final serverMd5 = serverFile['md5']!;

        final localFile = localFiles.firstWhere(
          (f) => f['path'] == path,
          orElse: () => {},
        );

        if (localFile.isEmpty || localFile['md5'] != serverMd5) {
          // 服务器有更新或本地没有，拉取
          final result = await pullFile(path);
          results.add(result);
        }
      }

      // 4. 处理本地文件 (推送新的)
      for (final localFile in localFiles) {
        final path = localFile['path']!;

        final serverFile = serverFiles.firstWhere(
          (f) => f['path'] == path,
          orElse: () => {},
        );

        if (serverFile.isEmpty) {
          // 服务器没有此文件，推送
          final result = await syncFile(path);
          results.add(result);
        }
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
    String serverMd5,
  ) async {
    // 1. 解密服务器数据
    final serverJson = _encryption.decryptData(encryptedData);

    // 2. 覆盖本地文件
    await _storage.writeString(filePath, jsonEncode(serverJson));

    // 3. 更新 MD5 快照
    await _saveSyncMd5(filePath, serverMd5);

    // 4. 通知 UI 数据已更新
    EventManager.instance.broadcast(
      'sync_data_updated',
      SyncDataUpdatedArgs(filePath: filePath, source: 'server') as EventArgs,
    );
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
    // 实现根据实际存储结构调整
    // 这里返回一个示例结构
    final files = <Map<String, String>>[];

    // 遍历需要同步的插件目录
    final syncDirs = [
      'diary',
      'chat',
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
        final dirPath = await _storage.getPluginPath(dir);
        final directory = Directory(dirPath);

        if (await directory.exists()) {
          await for (final entity in directory.list(recursive: true)) {
            if (entity is File && entity.path.endsWith('.json')) {
              final content = await entity.readAsString();
              final json = jsonDecode(content) as Map<String, dynamic>;
              final md5 = _encryption.computeMd5(json);

              // 计算相对路径
              final relativePath = entity.path
                  .substring(dirPath.length)
                  .replaceAll('\\', '/')
                  .replaceFirst(RegExp(r'^/'), '');

              files.add({'path': '$dir/$relativePath', 'md5': md5});
            }
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
    };
  }
}

/// 同步数据更新事件参数
class SyncDataUpdatedArgs {
  final String filePath;
  final String source; // 'server' or 'local'

  SyncDataUpdatedArgs({required this.filePath, required this.source});
}
