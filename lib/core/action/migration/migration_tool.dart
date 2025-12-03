/// 配置迁移工具
/// 演示如何从旧格式迁移到新格式
library migration_tool;

import 'dart:convert';
import 'dart:io';
import 'package:Memento/core/floating_ball/models/floating_ball_gesture.dart';
import 'package:flutter/material.dart';
import '../action_manager.dart';
import '../action_storage.dart';
import '../models/action_instance.dart';
import '../models/action_group.dart';
import '../models/action_definition.dart';

/// 迁移结果
class MigrationResult {
  final bool success;
  final String message;
  final int migratedCount;
  final int skippedCount;
  final int errorCount;
  final List<String> errors;
  final String? backupPath;

  const MigrationResult({
    required this.success,
    required this.message,
    required this.migratedCount,
    required this.skippedCount,
    required this.errorCount,
    required this.errors,
    this.backupPath,
  });
}

/// 迁移进度
class MigrationProgress {
  final String currentStep;
  final int current;
  final int total;
  final String? message;

  const MigrationProgress({
    required this.currentStep,
    required this.current,
    required this.total,
    this.message,
  });

  double get progress => total > 0 ? current / total : 0.0;
}

/// 配置迁移工具
class MigrationTool {
  // 旧配置文件名
  static const String OLD_CONFIG_FILE = 'floating_ball_config.json';

  // 新配置文件名
  static const String NEW_CONFIG_FILE = 'floating_ball_config_v1.json';

  final ActionManager _actionManager;
  final ActionStorage _storage;

  MigrationTool({
    ActionManager? actionManager,
    ActionStorage? storage,
  })  : _actionManager = actionManager ?? ActionManager(),
        _storage = storage ?? ActionStorage();

  /// 执行迁移
  Future<MigrationResult> migrate({
    VoidCallback? onProgress,
    Function(MigrationProgress)? onStep,
  }) async {
    try {
      onStep?.call(const MigrationProgress(
        currentStep: '开始迁移',
        current: 0,
        total: 10,
        message: '初始化...',
      ));

      // 检查旧配置文件是否存在
      final oldConfigPath = await _getOldConfigPath();
      if (!await File(oldConfigPath).exists()) {
        return const MigrationResult(
          success: false,
          message: '旧配置文件不存在',
          migratedCount: 0,
          skippedCount: 0,
          errorCount: 0,
          errors: [],
        );
      }

      onStep?.call(const MigrationProgress(
        currentStep: '读取旧配置',
        current: 1,
        total: 10,
        message: '正在读取旧配置...',
      ));

      // 读取旧配置
      final oldConfig = await _readOldConfig(oldConfigPath);

      onStep?.call(const MigrationProgress(
        currentStep: '备份旧配置',
        current: 2,
        total: 10,
        message: '正在备份旧配置...',
      ));

      // 备份旧配置
      final backupPath = await _backupOldConfig(oldConfigPath);

      onStep?.call(const MigrationProgress(
        currentStep: '转换配置格式',
        current: 3,
        total: 10,
        message: '正在转换配置格式...',
      ));

      // 转换配置
      final migrationData = await _convertConfig(oldConfig);

      onStep?.call(const MigrationProgress(
        currentStep: '保存新配置',
        current: 4,
        total: 10,
        message: '正在保存新配置...',
      ));

      // 保存新配置
      await _storage.initialize();
      await _storage.saveConfig(migrationData);

      onStep?.call(const MigrationProgress(
        currentStep: '加载新配置',
        current: 5,
        total: 10,
        message: '正在加载新配置...',
      ));

      // 加载到 ActionManager
      await _actionManager.initialize();
      final loadedData = await _storage.loadConfig();

      // 应用配置
      await _applyMigratedData(loadedData);

      onStep?.call(const MigrationProgress(
        currentStep: '验证迁移结果',
        current: 6,
        total: 10,
        message: '正在验证迁移结果...',
      ));

      // 验证
      final validationResult = await _validateMigration(loadedData);

      onStep?.call(const MigrationProgress(
        currentStep: '完成迁移',
        current: 10,
        total: 10,
        message: '迁移完成！',
      ));

      return MigrationResult(
        success: validationResult['success'] as bool,
        message: validationResult['message'] as String,
        migratedCount: validationResult['migratedCount'] as int,
        skippedCount: validationResult['skippedCount'] as int,
        errorCount: validationResult['errorCount'] as int,
        errors: List<String>.from(validationResult['errors'] as List),
        backupPath: backupPath,
      );
    } catch (e, stack) {
      return MigrationResult(
        success: false,
        message: '迁移失败: $e\n$stack',
        migratedCount: 0,
        skippedCount: 0,
        errorCount: 1,
        errors: [e.toString()],
      );
    }
  }

  /// 获取旧配置文件路径
  Future<String> _getOldConfigPath() async {
    // TODO: 使用 StorageManager 获取路径
    return 'storage/$OLD_CONFIG_FILE';
  }

  /// 读取旧配置
  Future<Map<String, dynamic>> _readOldConfig(String path) async {
    final file = File(path);
    final content = await file.readAsString();
    return jsonDecode(content) as Map<String, dynamic>;
  }

  /// 备份旧配置
  Future<String> _backupOldConfig(String path) async {
    final file = File(path);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupPath = '${path}_backup_$timestamp.json';
    await file.copy(backupPath);
    return backupPath;
  }

  /// 转换配置格式
  Future<ActionStorageData> _convertConfig(Map<String, dynamic> oldConfig) async {
    final gestureActions = <FloatingBallGesture, GestureActionConfig>{};
    final errors = <String>[];
    int migratedCount = 0;
    int skippedCount = 0;

    // 转换手势动作
    final actionsJson = oldConfig['actions'] as Map<String, dynamic>?;
    if (actionsJson != null) {
      for (final entry in actionsJson.entries) {
        final gestureName = entry.key;
        final actionData = entry.value;

        try {
          // 查找对应的 FloatingBallGesture
          final gesture = _parseGesture(gestureName);
          if (gesture == null) {
            errors.add('未知的手势: $gestureName');
            skippedCount++;
            continue;
          }

          // 转换动作
          final config = await _convertGestureAction(actionData);
          if (config != null) {
            gestureActions[gesture] = config;
            migratedCount++;
          } else {
            skippedCount++;
          }
        } catch (e) {
          errors.add('转换失败 ($gestureName): $e');
          skippedCount++;
        }
      }
    }

    return ActionStorageData(
      version: '1.0',
      lastModified: DateTime.now(),
      gestureActions: gestureActions,
      customActions: {},
      actionGroups: {},
      settings: {
        'migratedFrom': OLD_CONFIG_FILE,
        'migrationTime': DateTime.now().toIso8601String(),
        'migratedCount': migratedCount,
        'skippedCount': skippedCount,
      },
    );
  }

  /// 解析手势名称
  FloatingBallGesture? _parseGesture(String gestureName) {
    switch (gestureName.toLowerCase()) {
      case 'tap':
        return FloatingBallGesture.tap;
      case 'swipeup':
      case 'swipe_up':
        return FloatingBallGesture.swipeUp;
      case 'swipedown':
      case 'swipe_down':
        return FloatingBallGesture.swipeDown;
      case 'swipeleft':
      case 'swipe_left':
        return FloatingBallGesture.swipeLeft;
      case 'swiperight':
      case 'swipe_right':
        return FloatingBallGesture.swipeRight;
      default:
        return null;
    }
  }

  /// 转换手势动作
  Future<GestureActionConfig?> _convertGestureAction(dynamic actionData) async {
    if (actionData is! Map) {
      return null;
    }

    // 提取动作标题
    final actionTitle = actionData['title'] as String?;
    if (actionTitle == null) {
      return null;
    }

    // 查找对应的内置动作
    final actionId = _findActionIdByTitle(actionTitle);
    if (actionId == null) {
      return null;
    }

    // 创建动作实例
    final actionInstance = ActionInstance.create(
      actionId: actionId,
      data: actionData['data'] as Map<String, dynamic>? ?? {},
    );

    // 这里需要推断手势类型，但旧的配置中没有手势信息
    // 所以我们需要让调用者传入手势类型
    // 这里先返回一个空的配置，实际使用时需要根据上下文设置

    return GestureActionConfig(
      gesture: FloatingBallGesture.tap, // 默认值，需要在调用时修正
      singleAction: actionInstance,
    );
  }

  /// 根据标题查找动作 ID
  String? _findActionIdByTitle(String title) {
    // 标题映射表
    final titleMapping = <String, String>{
      '打开上次插件': BuiltInActions.openLastPlugin,
      '选择打开插件': BuiltInActions.selectPlugin,
      '返回上一页': BuiltInActions.goBack,
      '返回首页': BuiltInActions.goHome,
      '刷新页面': BuiltInActions.refresh,
      '路由历史记录': BuiltInActions.showRouteHistory,
      '打开上个路由': BuiltInActions.reopenLastRoute,
    };

    return titleMapping[title];
  }

  /// 应用迁移后的数据
  Future<void> _applyMigratedData(ActionStorageData data) async {
    // 应用手势动作配置
    for (final entry in data.gestureActions.entries) {
      await _actionManager.setGestureAction(entry.key, entry.value);
    }
  }

  /// 验证迁移结果
  Future<Map<String, dynamic>> _validateMigration(ActionStorageData data) async {
    final errors = <String>[];
    int migratedCount = 0;
    int skippedCount = 0;

    // 验证手势动作
    for (final entry in data.gestureActions.entries) {
      final gesture = entry.key;
      final config = entry.value;

      if (config.hasAction) {
        migratedCount++;
      } else {
        skippedCount++;
        errors.add('手势 $gesture 没有有效的动作配置');
      }
    }

    return {
      'success': errors.isEmpty,
      'message': errors.isEmpty
          ? '迁移成功，共迁移 $migratedCount 个动作配置'
          : '迁移完成但有 ${errors.length} 个错误',
      'migratedCount': migratedCount,
      'skippedCount': skippedCount,
      'errorCount': errors.length,
      'errors': errors,
    };
  }

  /// 检查是否需要迁移
  Future<bool> needsMigration() async {
    final oldConfigPath = await _getOldConfigPath();
    return await File(oldConfigPath).exists();
  }

  /// 生成迁移报告
  Future<String> generateReport(MigrationResult result) async {
    final buffer = StringBuffer();

    buffer.writeln('配置迁移报告');
    buffer.writeln('==============');
    buffer.writeln();
    buffer.writeln('迁移时间: ${DateTime.now().toIso8601String()}');
    buffer.writeln('迁移状态: ${result.success ? '成功' : '失败'}');
    buffer.writeln();
    buffer.writeln('迁移统计:');
    buffer.writeln('  - 成功迁移: ${result.migratedCount} 个');
    buffer.writeln('  - 跳过: ${result.skippedCount} 个');
    buffer.writeln('  - 错误: ${result.errorCount} 个');
    buffer.writeln();

    if (result.errors.isNotEmpty) {
      buffer.writeln('错误详情:');
      for (final error in result.errors) {
        buffer.writeln('  - $error');
      }
      buffer.writeln();
    }

    if (result.backupPath != null) {
      buffer.writeln('备份位置: ${result.backupPath}');
      buffer.writeln();
    }

    buffer.writeln('说明:');
    buffer.writeln('本工具仅用于演示迁移功能。生产环境中，建议手动创建');
    buffer.writeln('新的动作配置，而不是自动迁移。');

    return buffer.toString();
  }

  /// 回滚迁移
  Future<bool> rollbackMigration(String backupPath) async {
    try {
      final newConfigPath = await _getOldConfigPath();
      await File(backupPath).copy(newConfigPath);
      return true;
    } catch (e) {
      debugPrint('回滚失败: $e');
      return false;
    }
  }

  /// 获取新配置文件路径
  Future<String> getNewConfigPath() async {
    await _storage.initialize();
    return _storage.configFilePath;
  }

  /// 显示迁移对话框
  static Future<MigrationResult?> showMigrationDialog(
    BuildContext context, {
    VoidCallback? onComplete,
  }) async {
    final tool = MigrationTool();

    // 检查是否需要迁移
    final needsMigration = await tool.needsMigration();
    if (!needsMigration) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('无需迁移，未找到旧配置文件'),
        ),
      );
      return null;
    }

    return showDialog<MigrationResult>(
      context: context,
      builder: (context) => _MigrationDialog(tool: tool),
    );
  }
}

class _MigrationDialog extends StatefulWidget {
  final MigrationTool tool;

  const _MigrationDialog({required this.tool});

  @override
  State<_MigrationDialog> createState() => _MigrationDialogState();
}

class _MigrationDialogState extends State<_MigrationDialog> {
  bool _isMigrating = false;
  MigrationProgress? _progress;
  MigrationResult? _result;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('配置迁移'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isMigrating) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                _progress?.message ?? '正在迁移...',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (_progress != null)
                LinearProgressIndicator(
                  value: _progress!.progress,
                ),
            ] else if (_result != null) ...[
              Icon(
                _result!.success ? Icons.check_circle : Icons.error,
                color: _result!.success ? Colors.green : Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                _result!.message,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '成功迁移: ${_result!.migratedCount} 个\n'
                '跳过: ${_result!.skippedCount} 个\n'
                '错误: ${_result!.errorCount} 个',
                textAlign: TextAlign.left,
              ),
            ] else ...[
              const Icon(
                Icons.info_outline,
                size: 64,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              const Text(
                '检测到旧版本的配置文件。\n\n'
                '是否要迁移到新格式？\n\n'
                '注意：迁移将备份旧配置，但建议手动创建新配置。',
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (_isMigrating)
          TextButton(
            onPressed: null,
            child: const Text('迁移中...'),
          )
        else if (_result == null) ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: _startMigration,
            child: const Text('开始迁移'),
          ),
        ] else ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ],
    );
  }

  void _startMigration() async {
    setState(() {
      _isMigrating = true;
    });

    try {
      final result = await widget.tool.migrate(
        onStep: (progress) {
          setState(() {
            _progress = progress;
          });
        },
      );

      setState(() {
        _result = result;
        _isMigrating = false;
      });
    } catch (e) {
      setState(() {
        _result = MigrationResult(
          success: false,
          message: '迁移失败: $e',
          migratedCount: 0,
          skippedCount: 0,
          errorCount: 1,
          errors: [e.toString()],
        );
        _isMigrating = false;
      });
    }
  }
}
