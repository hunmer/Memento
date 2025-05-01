import 'package:flutter/material.dart';
import 'package:Memento/core/plugin_manager.dart';
import '../services/prompt_replacements.dart';
import '../../openai/openai_plugin.dart';

class DiaryPromptController {
  final DiaryPromptReplacements _promptReplacements = DiaryPromptReplacements();
  
  void initialize() {
    // 初始化prompt替换服务
    _promptReplacements.initialize();
    
    // 延迟注册prompt替换方法，等待OpenAI插件初始化完成
    Future.delayed(const Duration(seconds: 1), () {
      _registerPromptMethods();
    });
  }

  /// 注册prompt替换方法
  void _registerPromptMethods() {
    try {
      final openaiPlugin = PluginManager.instance.getPlugin('openai') as OpenAIPlugin?;
      if (openaiPlugin != null) {
        openaiPlugin.registerPromptReplacementMethod(
          'diary_getDiaries',
          _promptReplacements.getDiaries,
        );
        debugPrint('成功注册diary_getDiaries方法到OpenAI插件');
      } else {
        debugPrint('注册diary_getDiaries方法失败：未找到OpenAI插件，将在5秒后重试');
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
    final openaiPlugin = PluginManager.instance.getPlugin('openai') as OpenAIPlugin?;
    if (openaiPlugin != null) {
      openaiPlugin.unregisterPromptReplacementMethod('diary_getDiaries');
      debugPrint('成功注销diary_getDiaries方法');
    }
    
    // 清理prompt替换服务
    _promptReplacements.dispose();
  }
}