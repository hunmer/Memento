import '../../openai/openai_plugin.dart';
import '../notes_plugin.dart';
import '../services/prompt_replacements.dart';

/// Notes 插件的 Prompt 控制器
///
/// 负责注册 Prompt 替换方法到 OpenAI 插件
class NotesPromptController {
  final NotesPlugin plugin;
  late final NotesPromptReplacements _replacements;

  NotesPromptController(this.plugin) {
    _replacements = NotesPromptReplacements(plugin);
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
        // 注册 notes_getNotes 方法
        OpenAIPlugin.instance.registerPromptReplacementMethod(
          'notes_getNotes',
          _replacements.getNotes,
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
      OpenAIPlugin.instance.unregisterPromptReplacementMethod('notes_getNotes');
    } catch (e) {
      // 忽略注销错误
    }
  }

  /// 释放资源
  void dispose() {
    _replacements.dispose();
  }
}
