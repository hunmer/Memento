import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// 存储引擎的抽象基类
abstract class StorageEngine {
  Future<Map<String, dynamic>> read(String path);
  Future<void> write(String path, Map<String, dynamic> data);
  Future<bool> exists(String path);
  Future<void> createDirectory(String path);
}

/// JSON文件存储引擎实现
class JsonStorageEngine implements StorageEngine {
  @override
  Future<Map<String, dynamic>> read(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        final content = await file.readAsString();
        return json.decode(content) as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      debugPrint('Error reading JSON file: $e');
      return {};
    }
  }

  @override
  Future<void> write(String path, Map<String, dynamic> data) async {
    try {
      final file = File(path);
      final directory = file.parent;
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      await file.writeAsString(json.encode(data));
    } catch (e) {
      debugPrint('Error writing JSON file: $e');
      rethrow;
    }
  }

  @override
  Future<bool> exists(String path) async {
    return await File(path).exists();
  }

  @override
  Future<void> createDirectory(String path) async {
    final directory = Directory(path);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }
}
