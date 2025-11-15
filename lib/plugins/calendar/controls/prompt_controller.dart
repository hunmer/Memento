import '../../openai/openai_plugin.dart';
import '../calendar_plugin.dart';
import '../services/prompt_replacements.dart';

/// Calendar 插件的 Prompt 控制器
///
/// 负责注册 Prompt 替换方法到 OpenAI 插件
class CalendarPromptController {
  final CalendarPlugin plugin;
  late final CalendarPromptReplacements _replacements;

  CalendarPromptController(this.plugin) {
    _replacements = CalendarPromptReplacements(plugin);
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
        // 注册 calendar_getEvents 方法
        OpenAIPlugin.instance.registerPromptReplacementMethod(
          'calendar_getEvents',
          _replacements.getEvents,
        );

        // 注册 calendar_getTodayEvents 方法
        OpenAIPlugin.instance.registerPromptReplacementMethod(
          'calendar_getTodayEvents',
          _replacements.getTodayEvents,
        );
      } catch (e) {
        // 如果注册失败,可能是OpenAI插件还未初始化,稍后重试
        Future.delayed(const Duration(seconds: 5), _registerPromptMethods);
      }
    });
  }

  /// 释放资源
  void dispose() {
    _replacements.dispose();
  }
}
