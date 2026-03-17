import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'file_storage_service.dart';
import 'encryption_service.dart';

/// 插件数据访问服务
///
/// 负责读取、解密、加密和写入各插件的数据
/// 提供统一的数据访问接口供 HTTP 路由使用
///
/// 安全说明：加密密钥只保存在内存中，不持久化到文件
class PluginDataService {
  final FileStorageService storageService;
  final ServerEncryptionService encryptionService;
  final String _dataDir;

  PluginDataService(this.storageService, this._dataDir)
      : encryptionService = ServerEncryptionService();

  /// 初始化服务
  Future<void> initialize() async {
    // 不再从文件加载密钥，密钥只保存在内存中
  }

  // ==================== 密钥管理（仅内存）====================

  /// 设置用户的加密密钥（仅内存，不持久化）
  void setEncryptionKey(String userId, String encryptionKey) {
    encryptionService.setUserKey(userId, encryptionKey);
  }

  /// 移除用户的加密密钥（仅内存）
  void removeEncryptionKey(String userId) {
    encryptionService.removeUserKey(userId);
  }

  /// 检查用户是否已设置密钥（仅检查内存）
  bool hasEncryptionKey(String userId) {
    return encryptionService.hasUserKey(userId);
  }

  /// 获取用户的加密密钥（仅从内存）
  String? getEncryptionKey(String userId) {
    return encryptionService.getUserKey(userId);
  }

  // ==================== 数据读取 ====================

  /// 读取并解密插件数据文件
  Future<Map<String, dynamic>?> readPluginData(
    String userId,
    String pluginId,
    String fileName,
  ) async {
    if (!hasEncryptionKey(userId)) {
      throw StateError('用户未设置加密密钥');
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
    if (!hasEncryptionKey(userId)) {
      throw StateError('用户未设置加密密钥');
    }

    final encryptedData = encryptionService.encryptData(userId, data);
    final md5Hash = encryptionService.computeMd5(data);
    final filePath = '$pluginId/$fileName';

    await storageService.writeEncryptedFile(
        userId, filePath, encryptedData, md5Hash);
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

  // ==================== 重新加密（密钥更改）====================

  /// 重新加密用户的所有文件
  ///
  /// [userId] 用户ID
  /// [newKey] 新的加密密钥 (Base64)
  /// 返回重新加密的文件数量和错误列表
  Future<Map<String, dynamic>> reEncryptAllFiles(String userId, String newKey) async {
    final oldKey = encryptionService.getUserKey(userId);
    if (oldKey == null) {
      throw StateError('请先设置当前加密密钥');
    }

    int fileCount = 0;
    final errors = <String>[];

    // 获取用户数据目录
    final userDir = Directory(getUserDataDir(userId));
    if (!await userDir.exists()) {
      return {'file_count': 0, 'errors': errors};
    }

    // 遍历所有 JSON 文件
    await for (final entity in userDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.json')) {
        try {
          // 读取加密文件
          final relativePath = path.relative(entity.path, from: userDir.path);
          final fileData = await storageService.readEncryptedFile(userId, relativePath);

          if (fileData == null) continue;

          final encryptedData = fileData['encrypted_data'] as String?;
          if (encryptedData == null) continue;

          // 用旧密钥解密
          final decryptedData = encryptionService.decryptData(userId, encryptedData);

          // 临时设置新密钥
          encryptionService.setUserKey(userId, newKey);

          // 用新密钥重新加密
          final newEncryptedData = encryptionService.encryptString(
            userId,
            jsonEncode(decryptedData),
          );
          final newMd5 = encryptionService.computeStringMd5(jsonEncode(decryptedData));

          // 保存文件
          await storageService.writeEncryptedFile(
            userId,
            relativePath,
            newEncryptedData,
            newMd5,
          );

          fileCount++;
        } catch (e) {
          errors.add('${entity.path}: $e');
          // 恢复旧密钥以便继续处理其他文件
          encryptionService.setUserKey(userId, oldKey);
        }
      }
    }

    // 确保新密钥设置正确（仅内存，不持久化）
    encryptionService.setUserKey(userId, newKey);

    return {
      'file_count': fileCount,
      'errors': errors,
    };
  }
}
