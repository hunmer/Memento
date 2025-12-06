import 'package:fs_shim/fs_idb.dart';
import 'dart:convert';
import 'package:fs_shim/fs_shim.dart';
import 'package:path/path.dart';
import 'storage_interface.dart';

// 文件系统实例
final fs = fileSystemWeb.withIdbOptions(
  options: FileSystemIdbOptions.pageDefault,
);

/// Web平台的持久化存储实现，使用localStorage
/// 注意：这个类只在Web平台使用，在其他平台会抛出异常
class WebStorage implements StorageInterface {
  /// 私有构造函数，防止实例化
  WebStorage._() {
    // 初始化根目录
    _initRootDir();
  }

  // 应用根目录
  static const _rootDir = '/memento_app';

  // 初始化根目录
  Future<void> _initRootDir() async {
    final rootDir = fs.directory(_rootDir);
    if (!await rootDir.exists()) {
      await rootDir.create(recursive: true);
    }
  }

  /// 单例实例
  static final WebStorage _instance = WebStorage._();

  /// 获取单例实例
  static WebStorage get instance => _instance;

  /// 确保文件路径的所有目录都存在
  Future<void> _ensureDirectoryExists(String filePath) async {
    final dir = fs.directory(dirname(filePath));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  /// 保存数据到文件系统
  @override
  Future<void> saveData(String key, String value) async {
    try {
      final file = fs.file(join(_rootDir, key));
      await _ensureDirectoryExists(file.path);
      await file.writeAsString(value);
    } catch (e) {
      print('Web存储保存数据失败: $key - $e');
      rethrow;
    }
  }

  /// 从文件系统读取数据
  @override
  Future<String?> loadData(String key) async {
    try {
      final file = fs.file(join(_rootDir, key));
      if (await file.exists()) {
        return file.readAsString();
      }
      return null;
    } catch (e) {
      print('Web存储读取数据失败: $key - $e');
      return null;
    }
  }

  /// 从文件系统删除数据
  @override
  Future<void> removeData(String key) async {
    final file = fs.file(join(_rootDir, key));
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// 检查文件系统中是否存在数据
  @override
  Future<bool> hasData(String key) async {
    final file = fs.file(join(_rootDir, key));
    return file.exists();
  }

  /// 保存JSON对象到文件系统
  @override
  Future<void> saveJson(String key, dynamic data) async {
    try {
      final file = fs.file(join(_rootDir, key));
      await _ensureDirectoryExists(file.path);
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      print('Web存储保存JSON失败: $key - $e');
      rethrow; // 重新抛出异常，让调用者知道保存失败
    }
  }

  /// 从文件系统读取JSON对象
  @override
  Future<dynamic> loadJson(String key, [dynamic defaultValue]) async {
    try {
      final file = fs.file(join(_rootDir, key));
      if (await file.exists()) {
        final content = await file.readAsString();
        return jsonDecode(content);
      }
      return defaultValue ?? {};
    } catch (e) {
      print('Web存储读取JSON失败: $key - $e');
      return defaultValue ?? {};
    }
  }

  /// 获取所有以指定前缀开头的键
  @override
  Future<List<String>> getKeysWithPrefix(String prefix) async {
    final dir = fs.directory(_rootDir);
    final entities = await dir.list(recursive: true).toList();

    return entities
        .where((entity) => entity.path.startsWith(join(_rootDir, prefix)))
        .map((entity) => entity.path.substring(_rootDir.length + 1))
        .toList();
  }

  /// 清除所有以指定前缀开头的数据
  @override
  Future<void> clearWithPrefix(String prefix) async {
    final keys = await getKeysWithPrefix(prefix);
    for (final key in keys) {
      await removeData(key);
    }
  }

  /// 列出目录内容
  Future<List<FileSystemEntity>> listDirectory(String path) async {
    final dir = fs.directory(join(_rootDir, path));
    return dir.list().toList();
  }

  /// 检查路径是否存在
  Future<bool> exists(String path) async {
    final fullPath = join(_rootDir, path);
    if (await fs.file(fullPath).exists()) {
      return true;
    }
    return fs.directory(fullPath).exists();
  }

  /// 创建目录
  @override
  Future<void> createDirectory(String path) async {
    final dir = fs.directory(join(_rootDir, path));
    await dir.create(recursive: true);
  }

  /// 读取字符串内容
  @override
  Future<String> readString(String path) async {
    final file = fs.file(join(_rootDir, path));
    if (!await file.exists()) {
      throw Exception('文件不存在: $path');
    }
    return await file.readAsString();
  }

  /// 写入字符串内容
  @override
  Future<void> writeString(String path, String content) async {
    final file = fs.file(join(_rootDir, path));
    await _ensureDirectoryExists(file.path);
    await file.writeAsString(content);
  }

  /// 删除文件
  @override
  Future<void> deleteFile(String path) async {
    final file = fs.file(join(_rootDir, path));
    if (await file.exists()) {
      await file.delete();
    }
  }
}
