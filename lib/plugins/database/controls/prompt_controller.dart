import 'package:flutter/material.dart';
import '../../openai/openai_plugin.dart';
import '../database_plugin.dart';
import '../services/prompt_replacements.dart';

/// Database 插件的 Prompt 控制器
///
/// 负责注册 Prompt 替换方法到 OpenAI 插件
class DatabasePromptController {
  final DatabasePlugin plugin;
  late final DatabasePromptReplacements _replacements;

  DatabasePromptController(this.plugin) {
    _replacements = DatabasePromptReplacements(plugin);
  }

  /// 初始化并注册Prompt方法
  void initialize() {
    // 延迟注册以确保OpenAI插件已初始化
    _registerPromptMethods();
  }

  /// 注册Prompt替换方法
  void _registerPromptMethods() {
    Future.delayed(const Duration(seconds: 1), () {
      try {
        // 注册 database_getDatabases 方法
        OpenAIPlugin.instance.registerPromptReplacementMethod(
          'database_getDatabases',
          _replacements.getDatabases,
        );

        // 注册 database_getRecords 方法
        OpenAIPlugin.instance.registerPromptReplacementMethod(
          'database_getRecords',
          _replacements.getRecords,
        );

        // 注册 database_getStatistics 方法
        OpenAIPlugin.instance.registerPromptReplacementMethod(
          'database_getStatistics',
          _replacements.getStatistics,
        );

        // 注册 database_queryRecords 方法
        OpenAIPlugin.instance.registerPromptReplacementMethod(
          'database_queryRecords',
          _replacements.queryRecords,
        );

        // 注册 database_getFieldStatistics 方法
        OpenAIPlugin.instance.registerPromptReplacementMethod(
          'database_getFieldStatistics',
          _replacements.getFieldStatistics,
        );

        // 注册 database_getRecordsByDateRange 方法
        OpenAIPlugin.instance.registerPromptReplacementMethod(
          'database_getRecordsByDateRange',
          _replacements.getRecordsByDateRange,
        );

        debugPrint('Database 插件 Prompt 方法注册成功');
      } catch (e) {
        // 如果注册失败，可能是OpenAI插件还未初始化，稍后重试
        debugPrint('Database 插件 Prompt 方法注册失败，5秒后重试: $e');
        Future.delayed(const Duration(seconds: 5), _registerPromptMethods);
      }
    });
  }

  /// 释放资源
  void dispose() {
    _replacements.dispose();
  }
}
