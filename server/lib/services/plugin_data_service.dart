import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'file_storage_service.dart';
import 'encryption_service.dart';

/// 插件数据访问服务
///
/// 负责读取、解密、加密和写入各插件的数据
/// 提供统一的数据访问接口供 HTTP 路由使用
class PluginDataService {
  final FileStorageService storageService;
  final ServerEncryptionService encryptionService;
  final String _dataDir;

  /// API 密钥存储文件路径
  late final String _apiKeysPath;

  PluginDataService(this.storageService, this._dataDir)
      : encryptionService = ServerEncryptionService() {
    _apiKeysPath = path.join(_dataDir, 'auth', 'api_keys.json');
  }

  /// 初始化服务
  Future<void> initialize() async {
    // 加载已保存的 API 密钥
    await _loadApiKeys();
  }

  /// 加载 API 密钥
  Future<void> _loadApiKeys() async {
    final file = File(_apiKeysPath);
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        final keys = data['keys'] as Map<String, dynamic>? ?? {};

        for (final entry in keys.entries) {
          encryptionService.setUserKey(entry.key, entry.value as String);
        }
      } catch (e) {
        print('加载 API 密钥失败: $e');
      }
    }
  }

  /// 保存 API 密钥
  Future<void> _saveApiKeys() async {
    final file = File(_apiKeysPath);
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }

    final keys = <String, String>{};
    // 收集所有用户的密钥
    // 注意：这里需要遍历已知用户，实际实现中需要维护用户列表
    // 暂时通过 encryptionService 的内部状态来保存

    await file.writeAsString(jsonEncode({
      'keys': keys,
      'updated_at': DateTime.now().toIso8601String(),
    }));
  }

  // ==================== API 密钥管理 ====================

  /// 启用用户的 API 访问
  ///
  /// [userId] 用户ID
  /// [encryptionKey] Base64 编码的加密密钥
  Future<void> enableApi(String userId, String encryptionKey) async {
    encryptionService.setUserKey(userId, encryptionKey);
    await _persistApiKey(userId, encryptionKey);
  }

  /// 禁用用户的 API 访问
  Future<void> disableApi(String userId) async {
    encryptionService.removeUserKey(userId);
    await _removeApiKey(userId);
  }

  /// 检查用户是否已启用 API
  bool isApiEnabled(String userId) {
    return encryptionService.hasUserKey(userId);
  }

  /// 持久化 API 密钥
  Future<void> _persistApiKey(String userId, String key) async {
    final file = File(_apiKeysPath);
    Map<String, dynamic> data = {'keys': <String, dynamic>{}};

    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        data = jsonDecode(content) as Map<String, dynamic>;
        data['keys'] ??= <String, dynamic>{};
      } catch (e) {
        // 忽略解析错误，使用默认值
      }
    }

    (data['keys'] as Map<String, dynamic>)[userId] = key;
    data['updated_at'] = DateTime.now().toIso8601String();

    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    await file.writeAsString(jsonEncode(data));
  }

  /// 移除 API 密钥
  Future<void> _removeApiKey(String userId) async {
    final file = File(_apiKeysPath);
    if (!await file.exists()) return;

    try {
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      final keys = data['keys'] as Map<String, dynamic>? ?? {};
      keys.remove(userId);
      data['keys'] = keys;
      data['updated_at'] = DateTime.now().toIso8601String();
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      print('移除 API 密钥失败: $e');
    }
  }

  // ==================== 数据读取 ====================

  /// 读取并解密插件数据文件
  ///
  /// [userId] 用户ID
  /// [pluginId] 插件ID (如 'chat', 'notes')
  /// [fileName] 文件名 (如 'channels.json')
  Future<Map<String, dynamic>?> readPluginData(
    String userId,
    String pluginId,
    String fileName,
  ) async {
    if (!isApiEnabled(userId)) {
      throw StateError('用户未启用 API 访问');
    }

    final filePath = '$pluginId/$fileName';
    final fileData = await storageService.readEncryptedFile(userId, filePath);

    if (fileData == null) return null;

    final encryptedData = fileData['encrypted_data'] as String?;
    if (encryptedData == null) return null;

    try {
      return encryptionService.decryptData(userId, encryptedData);
    } catch (e) {
      print('解密数据失败 ($filePath): $e');
      return null;
    }
  }

  /// 读取插件数据文件列表
  ///
  /// [userId] 用户ID
  /// [pluginId] 插件ID
  /// [pattern] 文件名模式 (如 'activities_*.json')
  Future<List<String>> listPluginFiles(
    String userId,
    String pluginId, {
    String? pattern,
  }) async {
    final userDir = Directory(path.join(_dataDir, 'users', userId, pluginId));
    if (!await userDir.exists()) return [];

    final files = <String>[];
    await for (final entity in userDir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        final fileName = path.basename(entity.path);
        if (pattern == null || _matchPattern(fileName, pattern)) {
          files.add(fileName);
        }
      }
    }
    return files;
  }

  /// 简单的文件名模式匹配
  bool _matchPattern(String fileName, String pattern) {
    // 支持 * 通配符
    final regex = RegExp('^${pattern.replaceAll('*', '.*')}\$');
    return regex.hasMatch(fileName);
  }

  // ==================== 数据写入 ====================

  /// 加密并写入插件数据
  Future<void> writePluginData(
    String userId,
    String pluginId,
    String fileName,
    Map<String, dynamic> data,
  ) async {
    if (!isApiEnabled(userId)) {
      throw StateError('用户未启用 API 访问');
    }

    final encryptedData = encryptionService.encryptData(userId, data);
    final md5Hash = encryptionService.computeMd5(data);
    final filePath = '$pluginId/$fileName';

    await storageService.writeEncryptedFile(userId, filePath, encryptedData, md5Hash);
  }

  /// 删除插件数据文件
  Future<bool> deletePluginFile(
    String userId,
    String pluginId,
    String fileName,
  ) async {
    final filePath = '$pluginId/$fileName';
    return await storageService.deleteFile(userId, filePath);
  }

  // ==================== 辅助方法 ====================

  /// 获取用户数据目录
  String getUserDataDir(String userId) {
    return path.join(_dataDir, 'users', userId);
  }

  /// 检查插件目录是否存在
  Future<bool> pluginDirExists(String userId, String pluginId) async {
    final dir = Directory(path.join(getUserDataDir(userId), pluginId));
    return await dir.exists();
  }

  /// 创建插件目录
  Future<void> createPluginDir(String userId, String pluginId) async {
    final dir = Directory(path.join(getUserDataDir(userId), pluginId));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  // ==================== 分页辅助 ====================

  /// 分页处理列表数据
  Map<String, dynamic> paginate<T>(
    List<T> list, {
    int offset = 0,
    int count = 100,
  }) {
    final total = list.length;
    final start = offset.clamp(0, total);
    final end = (start + count).clamp(start, total);
    final data = list.sublist(start, end);

    return {
      'data': data,
      'total': total,
      'offset': start,
      'count': data.length,
      'hasMore': end < total,
    };
  }
}
