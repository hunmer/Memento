import 'web_storage.dart';

// Web平台的文件系统存根实现，使用localStorage进行持久化
class File {
  final String path;

  File(this.path);

  Future<bool> exists() async {
    return WebStorage.hasData('file:$path');
  }

  Future<void> create({bool recursive = false}) async {
    // 如果文件不存在，创建一个空文件
    if (!await exists()) {
      await writeAsString('');
    }

    // 如果需要递归创建目录，确保父目录存在
    if (recursive) {
      final parentPath = path.substring(0, path.lastIndexOf('/'));
      if (parentPath.isNotEmpty) {
        final parentDir = Directory(parentPath);
        await parentDir.create(recursive: true);
      }
    }
  }

  Future<void> delete() async {
    WebStorage.removeData('file:$path');
  }

  Future<String> readAsString() async {
    final content = WebStorage.loadData('file:$path');
    if (content == null) {
      throw FileSystemException('文件不存在', path);
    }
    return content;
  }

  Future<void> writeAsString(String content) async {
    WebStorage.saveData('file:$path', content);

    // 确保父目录存在于目录记录中
    final parentPath = path.substring(0, path.lastIndexOf('/'));
    if (parentPath.isNotEmpty) {
      // 获取目录列表或创建新的
      final dirListKey = 'dir:$parentPath:files';
      List<String> fileList = [];
      final existingList = WebStorage.loadJson(dirListKey);
      if (existingList != null && existingList is List) {
        fileList = List<String>.from(existingList);
      }

      // 添加当前文件（如果不存在）
      final fileName = path.substring(path.lastIndexOf('/') + 1);
      if (!fileList.contains(fileName)) {
        fileList.add(fileName);
        WebStorage.saveJson(dirListKey, fileList);
      }
    }
  }

  Directory get parent {
    final parentPath = path.substring(0, path.lastIndexOf('/'));
    return Directory(parentPath.isEmpty ? '/' : parentPath);
  }
}

class Directory {
  final String path;

  Directory(this.path);

  Future<bool> exists() async {
    // 检查目录记录是否存在
    return WebStorage.hasData('dir:$path:info');
  }

  Future<void> create({bool recursive = false}) async {
    // 创建目录记录
    WebStorage.saveJson('dir:$path:info', {
      'created': DateTime.now().toIso8601String(),
    });

    // 初始化空文件列表
    if (!WebStorage.hasData('dir:$path:files')) {
      WebStorage.saveJson('dir:$path:files', []);
    }

    // 如果需要递归创建父目录
    if (recursive && path != '/' && path.contains('/')) {
      final parentPath = path.substring(0, path.lastIndexOf('/'));
      if (parentPath.isNotEmpty) {
        final parentDir = Directory(parentPath);
        await parentDir.create(recursive: true);

        // 将当前目录添加到父目录的子目录列表中
        final dirName = path.substring(path.lastIndexOf('/') + 1);
        final parentDirsKey = 'dir:$parentPath:dirs';
        List<String> dirList = [];
        final existingList = WebStorage.loadJson(parentDirsKey);
        if (existingList != null && existingList is List) {
          dirList = List<String>.from(existingList);
        }
        if (!dirList.contains(dirName)) {
          dirList.add(dirName);
          WebStorage.saveJson(parentDirsKey, dirList);
        }
      }
    }
  }

  Future<void> delete() async {
    // 获取所有相关的键并删除
    final prefix = 'dir:$path';
    WebStorage.clearWithPrefix(prefix);

    // 从父目录的子目录列表中移除
    if (path != '/' && path.contains('/')) {
      final parentPath = path.substring(0, path.lastIndexOf('/'));
      final dirName = path.substring(path.lastIndexOf('/') + 1);
      final parentDirsKey = 'dir:$parentPath:dirs';

      final existingList = WebStorage.loadJson(parentDirsKey);
      if (existingList != null && existingList is List) {
        final dirList = List<String>.from(existingList);
        dirList.remove(dirName);
        WebStorage.saveJson(parentDirsKey, dirList);
      }
    }
  }

  // 列出目录中的文件
  Future<List<String>> listFiles() async {
    final fileListKey = 'dir:$path:files';
    final existingList = WebStorage.loadJson(fileListKey);
    if (existingList != null && existingList is List) {
      return List<String>.from(existingList);
    }
    return [];
  }

  // 列出子目录
  Future<List<String>> listDirectories() async {
    final dirListKey = 'dir:$path:dirs';
    final existingList = WebStorage.loadJson(dirListKey);
    if (existingList != null && existingList is List) {
      return List<String>.from(existingList);
    }
    return [];
  }
}

class FileSystemException implements Exception {
  final String message;
  final String path;

  FileSystemException(this.message, this.path);

  @override
  String toString() => 'FileSystemException: $message, path = $path';
}
