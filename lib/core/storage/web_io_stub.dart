// Web环境下的dart:io存根实现

// 提供与dart:io兼容的Directory类存根
class Directory {
  final String path;

  Directory(this.path);

  // 这些方法不会在Web环境中被调用，因为我们在代码中使用了kIsWeb检查
  // 但需要提供它们以满足类型系统的要求
  Stream<FileSystemEntity> list({bool recursive = false}) {
    throw UnsupportedError(
      'Directory.list() is not supported on the web platform.',
    );
  }

  Future<bool> exists() async => false;

  Future<Directory> delete({bool recursive = false}) async {
    throw UnsupportedError(
      'Directory.delete() is not supported on the web platform.',
    );
  }
}

// 基础文件系统实体类
abstract class FileSystemEntity {
  final String path;

  FileSystemEntity(this.path);

  Future<FileSystemEntity> delete({bool recursive = false}) async {
    throw UnsupportedError(
      'FileSystemEntity.delete() is not supported on the web platform.',
    );
  }
}
