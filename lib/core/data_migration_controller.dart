import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path_provider;

/// 数据迁移控制器
/// 用于在应用加载前处理数据格式迁移
class DataMigrationController {
  static final DataMigrationController instance = DataMigrationController._();
  DataMigrationController._();

  /// 迁移统计信息
  int _renamedCount = 0;
  int _skippedCount = 0;
  int _errorCount = 0;

  int get renamedCount => _renamedCount;
  int get skippedCount => _skippedCount;
  int get errorCount => _errorCount;

  /// 执行数据迁移
  /// 扫描 app_data 目录，将非 .json 后缀但实际内容为 JSON 的文件重命名
  Future<void> migrate() async {
    // Web 平台不使用文件系统，跳过迁移
    if (kIsWeb) {
      debugPrint('[DataMigration] Web 平台，跳过文件迁移');
      return;
    }

    _renamedCount = 0;
    _skippedCount = 0;
    _errorCount = 0;

    try {
      final appDir = await path_provider.getApplicationDocumentsDirectory();
      final appDataDir = io.Directory(path.join(appDir.path, 'app_data'));

      if (!await appDataDir.exists()) {
        debugPrint('[DataMigration] app_data 目录不存在，跳过迁移');
        return;
      }

      debugPrint('[DataMigration] 开始扫描目录: ${appDataDir.path}');
      await _scanDirectory(appDataDir);

      debugPrint(
        '[DataMigration] 迁移完成 - 重命名: $_renamedCount, 跳过: $_skippedCount, 错误: $_errorCount',
      );
    } catch (e, stack) {
      debugPrint('[DataMigration] 迁移过程出错: $e');
      debugPrint('[DataMigration] 堆栈: $stack');
    }
  }

  /// 递归扫描目录
  Future<void> _scanDirectory(io.Directory directory) async {
    try {
      final entities = await directory.list().toList();

      for (final entity in entities) {
        if (entity is io.Directory) {
          // 递归扫描子目录
          await _scanDirectory(entity);
        } else if (entity is io.File) {
          await _processFile(entity);
        }
      }
    } catch (e) {
      debugPrint('[DataMigration] 扫描目录失败 ${directory.path}: $e');
      _errorCount++;
    }
  }

  /// 处理单个文件
  Future<void> _processFile(io.File file) async {
    final filePath = file.path;
    final fileName = path.basename(filePath);

    // 跳过有后缀名的文件（只处理无后缀名的文件）
    if (path.basenameWithoutExtension(fileName) != fileName) {
      return;
    }

    try {
      // 读取文件内容
      final content = await file.readAsString();

      // 检查是否为 JSON 内容
      if (_isJsonContent(content)) {
        final newFilePath = '$filePath.json';
        final newFile = io.File(newFilePath);

        // 如果目标文件已存在，先删除
        if (await newFile.exists()) {
          await newFile.delete();
          debugPrint('[DataMigration] 覆盖已存在的文件: $newFilePath');
        }

        // 重命名文件（移动）
        await file.rename(newFilePath);
        debugPrint('[DataMigration] 重命名: $filePath -> $newFilePath');
        _renamedCount++;
      } else {
        _skippedCount++;
      }
    } catch (e) {
      debugPrint('[DataMigration] 处理文件失败 $filePath: $e');
      _errorCount++;
    }
  }

  /// 检查内容是否为有效的 JSON
  bool _isJsonContent(String content) {
    if (content.isEmpty) return false;

    // 去除前导空白字符
    final trimmed = content.trimLeft();
    if (trimmed.isEmpty) return false;

    // JSON 对象以 { 开头，数组以 [ 开头
    final firstChar = trimmed[0];
    if (firstChar != '{' && firstChar != '[') {
      return false;
    }

    // 尝试解析整个内容
    try {
      jsonDecode(content);
      return true;
    } catch (e) {
      return false;
    }
  }
}
