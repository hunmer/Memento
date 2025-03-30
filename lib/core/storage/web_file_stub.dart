// Web平台的文件系统API存根实现
import 'dart:async';

// 文件系统异常类
class FileSystemException implements Exception {
  final String message;
  final String? path;

  FileSystemException(this.message, [this.path]);

  @override
  String toString() =>
      path != null
          ? 'FileSystemException: $message, path = $path'
          : 'FileSystemException: $message';
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

// Directory类存根实现
class Directory extends FileSystemEntity {
  Directory(super.path);

  Future<bool> exists() async => false;

  Future<Directory> create({bool recursive = false}) async {
    throw UnsupportedError(
      'Directory.create() is not supported on the web platform.',
    );
  }

  @override
  Future<Directory> delete({bool recursive = false}) async {
    throw UnsupportedError(
      'Directory.delete() is not supported on the web platform.',
    );
  }

  Stream<FileSystemEntity> list({bool recursive = false}) {
    throw UnsupportedError(
      'Directory.list() is not supported on the web platform.',
    );
  }
}

// File类存根实现
class File extends FileSystemEntity {
  File(super.path);

  Future<bool> exists() async => false;

  Future<File> create({bool recursive = false}) async {
    throw UnsupportedError(
      'File.create() is not supported on the web platform.',
    );
  }

  Future<void> writeAsString(String contents) async {
    throw UnsupportedError(
      'File.writeAsString() is not supported on the web platform.',
    );
  }

  Future<String> readAsString() async {
    throw UnsupportedError(
      'File.readAsString() is not supported on the web platform.',
    );
  }

  Directory get parent => Directory(path.substring(0, path.lastIndexOf('/')));
}
