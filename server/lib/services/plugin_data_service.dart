import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'file_storage_service.dart';
import 'encryption_service.dart';

/// 密钥验证文件名
const String _keyVerificationFileName = '.key_verification.json';

/// 密钥验证文件内容（用于验证密钥是否正确）
const String _keyVerificationContent = 'MEMENTO_KEY_VERIFICATION_v1';

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

  // ==================== 密钥验证 ====================

  /// 检查用户是否已创建密钥验证文件
  Future<bool> hasKeyVerificationFile(String userId) async {
    final filePath = path.join(getUserDataDir(userId), _keyVerificationFileName);
    final file = File(filePath);
    return await file.exists();
  }

  /// 创建密钥验证文件（首次设置密钥时调用）
  ///
  /// 使用当前设置的密钥加密一个已知内容，用于后续验证
  Future<void> createKeyVerificationFile(String userId) async {
    if (!hasEncryptionKey(userId)) {
      throw StateError('用户未设置加密密钥');
    }

    final verificationData = {
      'content': _keyVerificationContent,
      'created_at': DateTime.now().toIso8601String(),
    };

    final encryptedData = encryptionService.encryptData(userId, verificationData);
    final md5Hash = encryptionService.computeStringMd5(jsonEncode(verificationData));

    final filePath = path.join(getUserDataDir(userId), _keyVerificationFileName);
    final file = File(filePath);

    // 确保用户目录存在
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }

    final fileContent = {
      'encrypted_data': encryptedData,
      'md5': md5Hash,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await file.writeAsString(jsonEncode(fileContent));
  }

  /// 验证密钥是否正确
  ///
  /// 尝试用提供的密钥解密验证文件，验证密钥是否与首次设置的相同
  /// 返回 (isValid, errorMessage)
  Future<(bool, String?)> verifyEncryptionKey(String userId, String encryptionKey) async {
    // 检查验证文件是否存在
    if (!await hasKeyVerificationFile(userId)) {
      // 验证文件不存在，这是首次设置密钥
      return (true, null);
    }

    // 读取验证文件
    final filePath = path.join(getUserDataDir(userId), _keyVerificationFileName);
    final file = File(filePath);

    if (!await file.exists()) {
      return (true, null);
    }

    try {
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      final encryptedData = data['encrypted_data'] as String?;

      if (encryptedData == null) {
        return (false, '验证文件格式错误');
      }

      // 临时设置密钥进行验证
      final originalKey = encryptionService.getUserKey(userId);
      encryptionService.setUserKey(userId, encryptionKey);

      try {
        // 尝试解密
        final decryptedData = encryptionService.decryptData(userId, encryptedData) as Map<String, dynamic>;
        final decryptedContent = decryptedData['content'] as String?;

        // 验证内容是否正确
        if (decryptedContent != _keyVerificationContent) {
          // 恢复原始密钥
          if (originalKey != null) {
            encryptionService.setUserKey(userId, originalKey);
          } else {
            encryptionService.removeUserKey(userId);
          }
          return (false, '密钥验证失败：内容不匹配');
        }

        // 验证成功，保持新密钥设置
        return (true, null);
      } catch (e) {
        // 解密失败，恢复原始密钥
        if (originalKey != null) {
          encryptionService.setUserKey(userId, originalKey);
        } else {
          encryptionService.removeUserKey(userId);
        }
        return (false, '密钥验证失败：无法解密验证文件，密钥可能不正确');
      }
    } catch (e) {
      return (false, '读取验证文件失败: $e');
    }
  }

  /// 更新验证文件（用于更改密钥后重新加密验证文件）
  Future<void> updateKeyVerificationFile(String userId) async {
    // 先删除旧的验证文件
    final filePath = path.join(getUserDataDir(userId), _keyVerificationFileName);
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
    // 创建新的验证文件
    await createKeyVerificationFile(userId);
  }

  // ==================== 数据读取 ====================

  /// 读取并解密插件数据文件
  Future<dynamic> readPluginData(
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

  /// 加密并写入插件数据（支持对象或数组）
  Future<void> writePluginData(
    String userId,
    String pluginId,
    String fileName,
    dynamic data,
  ) async {
    if (!hasEncryptionKey(userId)) {
      throw StateError('用户未设置加密密钥');
    }

    final encryptedData = encryptionService.encryptDynamic(userId, data);
    final md5Hash = encryptionService.computeDynamicMd5(data);
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
