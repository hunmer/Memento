import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Shortcut 执行结果的共享存储（Flutter 端）
///
/// 使用 App Groups 共享容器写入执行结果，供 iOS App Intent 读取
class ShortcutResultStorage {
  static final ShortcutResultStorage instance = ShortcutResultStorage._();
  ShortcutResultStorage._();

  static const String _appGroupIdentifier = 'group.github.hunmer.memento';
  static const String _resultsDirectoryName = 'shortcut_results';

  Directory? _resultsDirectory;

  /// 初始化共享存储目录
  Future<void> initialize() async {
    if (kIsWeb) return; // Web 平台不支持

    try {
      // iOS 使用 App Groups 共享容器
      if (Platform.isIOS) {
        // 获取 App Groups 容器路径
        // 注意：path_provider 不直接支持 App Groups，需要使用原生方法
        // 这里使用约定的路径结构
        final containerPath = await _getAppGroupContainerPath();
        if (containerPath != null) {
          _resultsDirectory = Directory('$containerPath/$_resultsDirectoryName');
          if (!await _resultsDirectory!.exists()) {
            await _resultsDirectory!.create(recursive: true);
          }
          debugPrint('[ShortcutResult] 共享存储目录已初始化: ${_resultsDirectory!.path}');
        }
      }
    } catch (e) {
      debugPrint('[ShortcutResult] 初始化失败: $e');
    }
  }

  /// 获取 App Groups 容器路径（iOS）
  Future<String?> _getAppGroupContainerPath() async {
    // 通过 MethodChannel 调用原生方法获取路径
    // 或使用文件系统路径约定
    // 简化实现：使用已知的路径结构
    try {
      final libraryDir = await getLibraryDirectory();
      // App Groups 容器路径通常在:
      // /var/mobile/Containers/Shared/AppGroup/<UUID>
      // 但我们可以通过创建符号链接或使用原生方法获取

      // 临时解决方案：使用应用文档目录的共享子目录
      // 正式实现应该通过 MethodChannel 获取真实的 App Groups 路径
      final parentDir = libraryDir.parent;
      final sharedDir = Directory('${parentDir.path}/Shared/AppGroup/$_appGroupIdentifier');

      // 检查是否存在（如果不存在，说明需要原生方法）
      if (await sharedDir.exists()) {
        return sharedDir.path;
      }

      // 回退：使用应用目录（仅用于测试）
      debugPrint('[ShortcutResult] 警告：App Groups 路径不可用，使用应用目录');
      return libraryDir.path;
    } catch (e) {
      debugPrint('[ShortcutResult] 获取容器路径失败: $e');
      return null;
    }
  }

  /// 写入执行结果
  Future<void> writeResult(
    String callId, {
    required bool success,
    dynamic data,
    String? error,
  }) async {
    if (_resultsDirectory == null) {
      debugPrint('[ShortcutResult] 存储目录未初始化');
      return;
    }

    try {
      final resultFile = File('${_resultsDirectory!.path}/$callId.json');
      final resultData = {
        'status': 'completed',
        'success': success,
        'timestamp': DateTime.now().millisecondsSinceEpoch / 1000,
        if (data != null) 'data': data,
        if (error != null) 'error': error,
      };

      final jsonString = jsonEncode(resultData);
      await resultFile.writeAsString(jsonString);

      debugPrint('[ShortcutResult] 已写入结果: $callId');
      debugPrint('[ShortcutResult] 文件路径: ${resultFile.path}');
    } catch (e) {
      debugPrint('[ShortcutResult] 写入结果失败: $e');
    }
  }

  /// 清理过期的结果文件（超过 1 小时）
  Future<void> cleanupExpiredResults() async {
    if (_resultsDirectory == null || !await _resultsDirectory!.exists()) {
      return;
    }

    try {
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));

      await for (final entity in _resultsDirectory!.list()) {
        if (entity is File && entity.path.endsWith('.json')) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(oneHourAgo)) {
            await entity.delete();
            debugPrint('[ShortcutResult] 已清理过期文件: ${entity.path}');
          }
        }
      }
    } catch (e) {
      debugPrint('[ShortcutResult] 清理过期文件失败: $e');
    }
  }
}
