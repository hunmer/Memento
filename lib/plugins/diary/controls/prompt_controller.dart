import '../../openai/openai_plugin.dart';
import '../diary_plugin.dart';
import '../services/prompt_replacements.dart';

/// Diary 插件的 Prompt 控制器
///
/// 负责注册 Prompt 替换方法到 OpenAI 插件
class DiaryPromptController {
  final DiaryPlugin plugin;
  late final DiaryPromptReplacements _replacements;

  DiaryPromptController(this.plugin) {
    _replacements = DiaryPromptReplacements(plugin);
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
        // 注册 diary_getDiaries 方法
        OpenAIPlugin.instance.registerPromptReplacementMethod(
          'diary_getDiaries',
          _replacements.getDiaries,
        );
      } catch (e) {
        // 如果注册失败,可能是OpenAI插件还未初始化,稍后重试
        Future.delayed(const Duration(seconds: 5), _registerPromptMethods);
      }
    });
  }

  /// 注销Prompt方法
  void unregisterPromptMethods() {
    try {
      OpenAIPlugin.instance.unregisterPromptReplacementMethod('diary_getDiaries');
    } catch (e) {
      // 忽略注销错误
    }
  }

  /// 释放资源
  void dispose() {
    _replacements.dispose();
  }
}
