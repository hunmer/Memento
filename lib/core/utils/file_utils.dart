import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';

class FileUtils {
  /// 复制目录及其所有内容到目标位置
  static Future<void> copyDirectory(
    Directory source,
    Directory destination, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      // 使用超时机制防止卡死
      await _copyDirectoryWithTimeout(source, destination, timeout);
    } catch (e) {
      debugPrint('复制目录失败: ${source.path} -> ${destination.path}');
      rethrow;
    }
  }

  static Future<void> _copyDirectoryWithTimeout(
    Directory source,
    Directory destination,
    Duration timeout,
  ) async {
    final completer = Completer<void>();
    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.completeError(TimeoutException('复制目录操作超时'));
      }
    });

    try {
      await _copyDirectoryImpl(source, destination);
      completer.complete();
    } catch (e) {
      completer.completeError(e);
    } finally {
      timer.cancel();
    }

    return completer.future;
  }

  static Future<void> _copyDirectoryImpl(
    Directory source,
    Directory destination,
  ) async {
    debugPrint('开始复制目录: ${source.path} -> ${destination.path}');

    // 确保目标目录存在
    if (!await destination.exists()) {
      await destination.create(recursive: true);
    }

    // 限制递归深度
    const maxDepth = 20;
    int currentDepth = 0;

    Future<void> copyRecursive(Directory src, Directory dst, int depth) async {
      if (depth > maxDepth) {
        throw StateError('达到最大递归深度 $maxDepth');
      }

      final entities = await src.list().toList();
      for (final entity in entities) {
        final newPath = '${dst.path}/${entity.path.split('/').last}';
        debugPrint('处理: ${entity.path} -> $newPath');

        if (entity is File) {
          // 大文件分块复制
          await _copyLargeFile(entity, File(newPath));
        } else if (entity is Directory) {
          final newDir = Directory(newPath);
          await newDir.create(recursive: true);
          await copyRecursive(entity, newDir, depth + 1);
        }
      }
    }

    await copyRecursive(source, destination, currentDepth);
    debugPrint('目录复制完成: ${source.path}');
  }

  static Future<void> _copyLargeFile(File source, File destination) async {
    const chunkSize = 1024 * 1024; // 1MB chunks
    final fileLength = await source.length();
    var position = 0;

    final sink = destination.openWrite();
    try {
      while (position < fileLength) {
        final chunk =
            await source.openRead(position, position + chunkSize).first;
        sink.add(chunk);
        position += chunk.length;
        debugPrint(
          '文件复制进度: ${(position / fileLength * 100).toStringAsFixed(1)}%',
        );
      }
    } finally {
      await sink.close();
    }
  }
}
