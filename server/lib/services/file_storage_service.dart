import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:shared_models/shared_models.dart';

/// 文件存储服务 - 纯文件系统存储
///
/// 目录结构:
/// {dataDir}/
/// ├── users/
/// │   └── {userId}/
/// │       ├── diary/
/// │       │   └── 2024-01-01.json
/// │       ├── chat/
/// │       │   └── channels.json
/// │       └── ...
/// ├── auth/
/// │   └── users.json
/// └── logs/
///     └── sync_2024-01-01.log
class FileStorageService {
  final String _baseDir;

  FileStorageService(this._baseDir);

  /// 初始化存储目录
  Future<void> initialize() async {
    final dirs = [
      _baseDir,
      path.join(_baseDir, 'users'),
      path.join(_baseDir, 'auth'),
      path.join(_baseDir, 'logs'),
    ];

    for (final dir in dirs) {
      final directory = Directory(dir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    }

    // 初始化用户数据文件
    final usersFile = File(path.join(_baseDir, 'auth', 'users.json'));
    if (!await usersFile.exists()) {
      await usersFile.writeAsString(jsonEncode({'users': []}));
    }
  }

  // ========== 用户数据操作 ==========

  /// 获取用户数据目录
  String getUserDir(String userId) => path.join(_baseDir, 'users', userId);

  /// 读取加密文件
  Future<Map<String, dynamic>?> readEncryptedFile(
    String userId,
    String filePath,
  ) async {
    final file = File(path.join(getUserDir(userId), filePath));
    if (!await file.exists()) return null;

    try {
      final content = await file.readAsString();
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      print('读取文件失败: $filePath - $e');
      return null;
    }
  }

  /// 写入加密文件
  Future<void> writeEncryptedFile(
    String userId,
    String filePath,
    String encryptedData,
    String md5Hash,
  ) async {
    final file = File(path.join(getUserDir(userId), filePath));

    // 确保父目录存在
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }

    final data = {
      'encrypted_data': encryptedData,
      'md5': md5Hash,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await file.writeAsString(jsonEncode(data));
  }

  /// 删除文件
  Future<bool> deleteFile(String userId, String filePath) async {
    final file = File(path.join(getUserDir(userId), filePath));
    if (await file.exists()) {
      await file.delete();
      return true;
    }
    return false;
  }

  /// 列出用户所有文件
  Future<List<FileInfo>> listUserFiles(String userId) async {
    final userDir = Directory(getUserDir(userId));
    if (!await userDir.exists()) return [];

    final files = <FileInfo>[];

    await for (final entity in userDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.json')) {
        try {
          final content = await entity.readAsString();
          final data = jsonDecode(content) as Map<String, dynamic>;

          // 计算相对路径
          final relativePath = path.relative(entity.path, from: userDir.path);

          files.add(FileInfo(
            path: relativePath.replaceAll('\\', '/'), // 统一使用正斜杠
            md5: data['md5'] as String,
            updatedAt: DateTime.parse(data['updated_at'] as String),
          ));
        } catch (e) {
          print('读取文件信息失败: ${entity.path} - $e');
        }
      }
    }

    return files;
  }

  /// 获取用户数据大小 (字节)
  Future<int> getUserDataSize(String userId) async {
    final userDir = Directory(getUserDir(userId));
    if (!await userDir.exists()) return 0;

    int totalSize = 0;
    await for (final entity in userDir.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }

    return totalSize;
  }

  // ========== 用户认证数据操作 ==========

  /// 获取用户认证文件路径
  String get _usersFilePath => path.join(_baseDir, 'auth', 'users.json');

  /// 读取所有用户
  Future<List<UserInfo>> readAllUsers() async {
    final file = File(_usersFilePath);
    if (!await file.exists()) return [];

    try {
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      final users = (data['users'] as List?)
              ?.map((u) => UserInfo.fromJson(u as Map<String, dynamic>))
              .toList() ??
          [];
      return users;
    } catch (e) {
      print('读取用户数据失败: $e');
      return [];
    }
  }

  /// 保存所有用户
  Future<void> saveAllUsers(List<UserInfo> users) async {
    final file = File(_usersFilePath);
    final data = {
      'users': users.map((u) => u.toJson()).toList(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    await file.writeAsString(jsonEncode(data));
  }

  /// 根据用户名查找用户
  Future<UserInfo?> findUserByUsername(String username) async {
    final users = await readAllUsers();
    try {
      return users.firstWhere((u) => u.username == username);
    } catch (e) {
      return null;
    }
  }

  /// 根据 ID 查找用户
  Future<UserInfo?> findUserById(String userId) async {
    final users = await readAllUsers();
    try {
      return users.firstWhere((u) => u.id == userId);
    } catch (e) {
      return null;
    }
  }

  /// 添加用户
  Future<void> addUser(UserInfo user) async {
    final users = await readAllUsers();
    users.add(user);
    await saveAllUsers(users);
  }

  /// 更新用户
  Future<void> updateUser(UserInfo updatedUser) async {
    final users = await readAllUsers();
    final index = users.indexWhere((u) => u.id == updatedUser.id);
    if (index >= 0) {
      users[index] = updatedUser;
      await saveAllUsers(users);
    }
  }

  // ========== 日志操作 ==========

  /// 记录同步日志
  Future<void> logSync({
    required String userId,
    required String action,
    required String filePath,
    String? details,
  }) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final logFile = File(path.join(_baseDir, 'logs', 'sync_$today.log'));

    final logEntry = [
      DateTime.now().toIso8601String(),
      userId,
      action,
      filePath,
      details ?? '',
    ].join('\t');

    await logFile.writeAsString('$logEntry\n', mode: FileMode.append);
  }
}
