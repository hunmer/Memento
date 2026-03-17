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
/// │       ├── .file_index.json  (持久化文件索引)
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

  /// 索引文件名
  static const String _indexFileName = '.file_index.json';

  /// 索引版本
  static const int _indexVersion = 1;

  /// 内存中的索引缓存
  final Map<String, Map<String, dynamic>> _indexCache = {};

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
    String md5Hash, {
    bool isBinary = false,
  }) async {
    final file = File(path.join(getUserDir(userId), filePath));

    // 确保父目录存在
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }

    final now = DateTime.now();
    final data = {
      'encrypted_data': encryptedData,
      'md5': md5Hash,
      'updated_at': now.toIso8601String(),
      'is_binary': isBinary,
    };

    await file.writeAsString(jsonEncode(data));

    // 更新文件索引
    await _updateFileIndex(userId, filePath, {
      'md5': md5Hash,
      'size': await file.length(),
      'updated_at': now.toIso8601String(),
    });
  }

  /// 删除文件
  Future<bool> deleteFile(String userId, String filePath) async {
    final file = File(path.join(getUserDir(userId), filePath));
    if (await file.exists()) {
      await file.delete();

      // 从文件索引中移除
      await _removeFromFileIndex(userId, filePath);

      return true;
    }
    return false;
  }

  // ========== 文件索引操作 ==========

  /// 获取索引文件路径
  String _getIndexFilePath(String userId) {
    return path.join(getUserDir(userId), _indexFileName);
  }

  /// 加载用户文件索引
  Future<Map<String, dynamic>> _loadFileIndex(String userId) async {
    // 先检查缓存
    if (_indexCache.containsKey(userId)) {
      return _indexCache[userId]!;
    }

    final indexFile = File(_getIndexFilePath(userId));

    if (!await indexFile.exists()) {
      // 索引不存在，重建索引
      final index = await rebuildFileIndex(userId);
      return index;
    }

    try {
      final content = await indexFile.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      // 检查版本
      final version = data['version'] as int? ?? 0;
      if (version < _indexVersion) {
        // 版本过旧，重建索引
        final index = await rebuildFileIndex(userId);
        return index;
      }

      _indexCache[userId] = data;
      return data;
    } catch (e) {
      print('加载文件索引失败: $e，将重建索引');
      final index = await rebuildFileIndex(userId);
      return index;
    }
  }

  /// 保存用户文件索引
  Future<void> _saveFileIndex(String userId, Map<String, dynamic> index) async {
    final indexFile = File(_getIndexFilePath(userId));

    // 确保用户目录存在
    if (!await indexFile.parent.exists()) {
      await indexFile.parent.create(recursive: true);
    }

    index['updated_at'] = DateTime.now().toIso8601String();
    await indexFile.writeAsString(jsonEncode(index));

    // 更新缓存
    _indexCache[userId] = index;
  }

  /// 更新文件索引中的单个文件
  Future<void> _updateFileIndex(String userId, String filePath, Map<String, dynamic> fileInfo) async {
    final index = await _loadFileIndex(userId);
    final files = index['files'] as Map<String, dynamic>? ?? {};

    // 标准化路径（使用正斜杠）
    final normalizedPath = filePath.replaceAll('\\', '/');
    files[normalizedPath] = fileInfo;

    index['files'] = files;
    await _saveFileIndex(userId, index);
  }

  /// 从文件索引中移除文件
  Future<void> _removeFromFileIndex(String userId, String filePath) async {
    final index = await _loadFileIndex(userId);
    final files = index['files'] as Map<String, dynamic>? ?? {};

    // 标准化路径
    final normalizedPath = filePath.replaceAll('\\', '/');
    files.remove(normalizedPath);

    index['files'] = files;
    await _saveFileIndex(userId, index);
  }

  /// 获取用户文件索引
  ///
  /// 返回完整的文件索引，包含所有文件的 path、md5、size、updated_at
  Future<Map<String, dynamic>> getFileIndex(String userId) async {
    return await _loadFileIndex(userId);
  }

  /// 重建文件索引
  ///
  /// 遍历用户目录下的所有文件，重新生成索引
  Future<Map<String, dynamic>> rebuildFileIndex(String userId) async {
    final userDir = Directory(getUserDir(userId));
    final files = <String, dynamic>{};

    if (await userDir.exists()) {
      await for (final entity in userDir.list(recursive: true)) {
        if (entity is File) {
          final fileName = path.basename(entity.path);

          // 排除索引文件本身和临时文件
          if (fileName == _indexFileName ||
              fileName.startsWith('.') ||
              fileName.endsWith('.tmp') ||
              fileName.endsWith('.bak')) {
            continue;
          }

          // 只处理 JSON 文件
          if (!fileName.endsWith('.json')) {
            continue;
          }

          try {
            final relativePath = path.relative(entity.path, from: userDir.path);
            final normalizedPath = relativePath.replaceAll('\\', '/');

            final content = await entity.readAsString();
            final data = jsonDecode(content) as Map<String, dynamic>;

            files[normalizedPath] = {
              'md5': data['md5'] as String? ?? '',
              'size': await entity.length(),
              'updated_at': data['updated_at'] as String? ?? DateTime.now().toIso8601String(),
            };
          } catch (e) {
            print('重建索引时读取文件失败: ${entity.path} - $e');
          }
        }
      }
    }

    final index = {
      'version': _indexVersion,
      'updated_at': DateTime.now().toIso8601String(),
      'files': files,
    };

    await _saveFileIndex(userId, index);
    print('已为用户 $userId 重建文件索引，共 ${files.length} 个文件');

    return index;
  }

  /// 批量从索引中移除文件
  Future<void> batchRemoveFromFileIndex(String userId, List<String> filePaths) async {
    final index = await _loadFileIndex(userId);
    final files = index['files'] as Map<String, dynamic>? ?? {};

    for (final filePath in filePaths) {
      final normalizedPath = filePath.replaceAll('\\', '/');
      files.remove(normalizedPath);
    }

    index['files'] = files;
    await _saveFileIndex(userId, index);
  }

  /// 列出用户文件（单层目录）
  ///
  /// [userId] 用户ID
  /// [directory] 可选的目录路径，为空时返回根目录内容
  /// 只返回指定目录下的一层内容，不递归遍历子目录
  Future<List<FileInfo>> listUserFiles(String userId, {String? directory}) async {
    final userDir = Directory(getUserDir(userId));
    if (!await userDir.exists()) return [];

    // 确定要列出的目录
    final targetDir = directory != null && directory.isNotEmpty
        ? Directory(path.join(userDir.path, directory))
        : userDir;

    if (!await targetDir.exists()) return [];

    final items = <FileInfo>[];

    await for (final entity in targetDir.list()) {
      final entityName = path.basename(entity.path);
      final relativePath = directory != null && directory.isNotEmpty
          ? '$directory/$entityName'
          : entityName;

      if (entity is File) {
        try {
          final content = await entity.readAsString();
          final data = jsonDecode(content) as Map<String, dynamic>;

          items.add(FileInfo(
            path: relativePath.replaceAll('\\', '/'), // 统一使用正斜杠
            size: await entity.length(),
            md5: data['md5'] as String?,
            updatedAt: DateTime.parse(data['updated_at'] as String),
            isFolder: false,
          ));
        } catch (e) {
          // 非 JSON 文件或解析失败，仍然返回基本信息
          items.add(FileInfo(
            path: relativePath.replaceAll('\\', '/'),
            size: await entity.length(),
            updatedAt: await entity.lastModified(),
            isFolder: false,
          ));
        }
      } else if (entity is Directory) {
        final stat = await entity.stat();
        items.add(FileInfo(
          path: relativePath.replaceAll('\\', '/'),
          updatedAt: stat.modified,
          isFolder: true,
        ));
      }
    }

    // 按名称排序：文件夹在前，文件在后
    items.sort((a, b) {
      if (a.isFolder && !b.isFolder) return -1;
      if (!a.isFolder && b.isFolder) return 1;
      return a.path.compareTo(b.path);
    });

    return items;
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

  /// 获取用户存储统计信息
  /// 返回文件数量、文件夹数量和总大小
  Future<Map<String, dynamic>> getUserStorageStats(String userId) async {
    final userDir = Directory(getUserDir(userId));
    if (!await userDir.exists()) {
      return {
        'file_count': 0,
        'folder_count': 0,
        'total_size': 0,
      };
    }

    int fileCount = 0;
    int folderCount = 0;
    int totalSize = 0;

    await for (final entity in userDir.list(recursive: true)) {
      if (entity is File) {
        fileCount++;
        totalSize += await entity.length();
      } else if (entity is Directory) {
        folderCount++;
      }
    }

    return {
      'file_count': fileCount,
      'folder_count': folderCount,
      'total_size': totalSize,
    };
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