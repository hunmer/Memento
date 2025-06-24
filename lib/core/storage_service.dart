import 'dart:convert';
import 'dart:io';
import 'package:Memento/core/storage/storage_manager.dart';
import 'package:path/path.dart' as path;

class StorageService {
  Future<String> get _localPath async {
    final directory = await StorageManager.getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> _getFile(String filePath) async {
    final basePath = await _localPath;
    final fullPath = path.join(basePath, filePath);

    // 确保目录存在
    final dir = Directory(path.dirname(fullPath));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return File(fullPath);
  }

  /// 读取指定路径的文件内容
  Future<Map<String, dynamic>> read(String filePath) async {
    try {
      final file = await _getFile(filePath);
      if (!await file.exists()) {
        return {};
      }
      final contents = await file.readAsString();
      return contents.isEmpty
          ? {}
          : json.decode(contents) as Map<String, dynamic>;
    } catch (e) {
      print('Error reading file: $e');
      return {};
    }
  }

  /// 写入内容到指定路径的文件
  Future<void> write(String filePath, Map<String, dynamic> data) async {
    final file = await _getFile(filePath);
    await file.writeAsString(json.encode(data));
  }

  /// 删除指定路径的文件或目录
  Future<void> delete(String filePath) async {
    final basePath = await _localPath;
    final fullPath = path.join(basePath, filePath);

    try {
      final entity = await FileSystemEntity.type(fullPath);
      if (entity == FileSystemEntityType.directory) {
        await Directory(fullPath).delete(recursive: true);
      } else if (entity == FileSystemEntityType.file) {
        await File(fullPath).delete();
      }
    } catch (e) {
      print('Error deleting: $e');
    }
  }
}
