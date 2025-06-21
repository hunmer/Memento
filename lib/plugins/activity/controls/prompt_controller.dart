import 'package:flutter/material.dart';
import 'package:Memento/core/plugin_manager.dart';
import '../services/prompt_replacements.dart';
import '../../openai/openai_plugin.dart';
import '../../../core/storage/storage_manager.dart';

class ActivityPromptController {
  final ActivityPromptReplacements _promptReplacements =
      ActivityPromptReplacements();
  final String _pluginDir;
  final StorageManager _storage;

  ActivityPromptController(this._storage, this._pluginDir);

  void initialize() {
    // 初始化prompt替换服务
    _promptReplacements.initialize(_storage, _pluginDir);

    // 延迟注册prompt替换方法，等待OpenAI插件初始化完成
    Future.delayed(const Duration(seconds: 1), () {
      _registerPromptMethods();
    });
  }

  /// 注册prompt替换方法
  void _registerPromptMethods() {
    try {
      final openaiPlugin =
          PluginManager.instance.getPlugin('openai') as OpenAIPlugin?;
      if (openaiPlugin != null) {
        openaiPlugin.registerPromptReplacementMethod(
          'activity_getActivitys',
          _promptReplacements.getActivities,
        );
      } else {
        debugPrint('注册activity_getActivitys方法失败：未找到OpenAI插件，将在5秒后重试');
        // 如果OpenAI插件还未准备好，5秒后重试
        Future.delayed(const Duration(seconds: 5), _registerPromptMethods);
      }
    } catch (e) {
      debugPrint('注册prompt替换方法时出错: $e，将在5秒后重试');
      // 发生错误时，5秒后重试
      Future.delayed(const Duration(seconds: 5), _registerPromptMethods);
    }
  }

  void unregisterPromptMethods() {
    // 注销prompt替换方法
    final openaiPlugin =
        PluginManager.instance.getPlugin('openai') as OpenAIPlugin?;
    if (openaiPlugin != null) {
      openaiPlugin.unregisterPromptReplacementMethod('activity_getActivitys');
      debugPrint('成功注销activity_getActivitys方法');
    }

    // 清理prompt替换服务
    _promptReplacements.dispose();
  }
}
