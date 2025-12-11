import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import 'package:shared_models/shared_models.dart';

/// 文件夹节点
class FolderNode {
  final String name;
  final String path;
  final bool isFolder;
  final List<FolderNode>? children;
  final int? size;
  final DateTime? updatedAt;

  FolderNode({
    required this.name,
    required this.path,
    required this.isFolder,
    this.children,
    this.size,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'path': path,
    'is_folder': isFolder,
    'children': children?.map((c) => c.toJson()).toList(),
    'size': size,
    'updated_at': updatedAt?.toIso8601String(),
  };
}

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

  /// 获取导出目录
  String getExportDir() => path.join(_baseDir, 'exports');

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

          final file = File(entity.path);
          files.add(FileInfo(
            path: relativePath.replaceAll('\\', '/'), // 统一使用正斜杠
            size: await file.length(),
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

  // ========== 目录树结构操作 ==========

  /// 获取目录树结构
  Future<FolderNode> getDirectoryTree(String userId) async {
    final userDir = Directory(getUserDir(userId));
    if (!await userDir.exists()) {
      return FolderNode(
        name: 'root',
        path: '',
        isFolder: true,
        children: [],
      );
    }

    return await _buildTree(userDir, '');
  }

  /// 递归构建目录树
  Future<FolderNode> _buildTree(Directory dir, String relativePath) async {
    final node = FolderNode(
      name: path.basename(dir.path),
      path: relativePath,
      isFolder: true,
      children: [],
    );

    final children = <FolderNode>[];

    try {
      await for (final entity in dir.list()) {
        final entityName = path.basename(entity.path);
        final entityRelativePath = relativePath.isEmpty
            ? entityName
            : '$relativePath/$entityName';

        if (entity is File && entity.path.endsWith('.json')) {
          try {
            final content = await entity.readAsString();
            final data = jsonDecode(content) as Map<String, dynamic>;

            children.add(FolderNode(
              name: entityName,
              path: entityRelativePath,
              isFolder: false,
              size: entity.lengthSync(),
              updatedAt: DateTime.parse(data['updated_at'] as String),
            ));
          } catch (e) {
            print('读取文件信息失败: ${entity.path} - $e');
          }
        } else if (entity is Directory) {
          // 递归处理子目录
          final subNode = await _buildTree(entity, entityRelativePath);
          children.add(subNode);
        }
      }
    } catch (e) {
      print('读取目录失败: ${dir.path} - $e');
    }

    // 按名称排序：文件夹在前，文件在后
    children.sort((a, b) {
      if (a.isFolder && !b.isFolder) return -1;
      if (!a.isFolder && b.isFolder) return 1;
      return a.name.compareTo(b.name);
    });

    return FolderNode(
      name: node.name,
      path: node.path,
      isFolder: true,
      children: children,
    );
  }

  // ========== ZIP导出功能 ==========

  /// 导出用户数据为ZIP文件
  Future<Map<String, dynamic>> exportUserDataAsZip(String userId) async {
    final userDir = Directory(getUserDir(userId));
    if (!await userDir.exists()) {
      throw Exception('用户数据目录不存在');
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
    final exportDir = getExportDir();
    final exportFileName = 'memento_export_$timestamp.zip';
    final exportFilePath = path.join(exportDir, exportFileName);

    // 确保导出目录存在
    final exportDirectory = Directory(exportDir);
    if (!await exportDirectory.exists()) {
      await exportDirectory.create(recursive: true);
    }

    // 创建ZIP归档
    final archive = Archive();

    // 收集所有文件并添加到ZIP
    final files = <String>[];
    int totalSize = 0;

    await for (final entity in userDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.json')) {
        final filePath = entity.path;
        final relativePath = path.relative(filePath, from: userDir.path);

        try {
          final content = await entity.readAsBytes();
          final archiveFile = ArchiveFile(
            relativePath.replaceAll('\\', '/'), // 统一使用正斜杠
            content.length,
            content,
          );
          archive.addFile(archiveFile);

          files.add(relativePath);
          totalSize += content.length;
        } catch (e) {
          print('添加文件到ZIP失败: $filePath - $e');
        }
      }
    }

    // 添加元数据文件
    final metadata = {
      'exported_at': DateTime.now().toIso8601String(),
      'user_id': userId,
      'file_count': files.length,
      'total_size_bytes': totalSize,
      'total_size_mb': (totalSize / 1024 / 1024).toStringAsFixed(2),
      'files': files,
    };

    final metadataContent = utf8.encode(JsonEncoder.withIndent('  ').convert(metadata));
    final metadataFile = ArchiveFile(
      'metadata.json',
      metadataContent.length,
      metadataContent,
    );
    archive.addFile(metadataFile);

    // 编码ZIP文件
    final zipData = ZipEncoder().encode(archive);

    if (zipData == null) {
      throw Exception('ZIP编码失败');
    }

    // 写入ZIP文件
    final exportFile = File(exportFilePath);
    await exportFile.writeAsBytes(zipData);

    return {
      'success': true,
      'file_path': exportFilePath,
      'file_name': exportFileName,
      'file_size': await exportFile.length(),
      'metadata': metadata,
    };
  }
}