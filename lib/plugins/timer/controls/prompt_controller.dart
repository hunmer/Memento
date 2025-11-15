import '../../openai/openai_plugin.dart';
import '../timer_plugin.dart';
import '../services/prompt_replacements.dart';

/// Timer 插件的 Prompt 控制器
///
/// 负责注册 Prompt 替换方法到 OpenAI 插件
class TimerPromptController {
  final TimerPlugin plugin;
  late final TimerPromptReplacements _replacements;

  TimerPromptController(this.plugin) {
    _replacements = TimerPromptReplacements(plugin);
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
        // 注册 timer_getTasks 方法
        OpenAIPlugin.instance.registerPromptReplacementMethod(
          'timer_getTasks',
          _replacements.getTasks,
        );

        // 注册 timer_getTaskById 方法
        OpenAIPlugin.instance.registerPromptReplacementMethod(
          'timer_getTaskById',
          _replacements.getTaskById,
        );

        // 注册 timer_getStatistics 方法
        OpenAIPlugin.instance.registerPromptReplacementMethod(
          'timer_getStatistics',
          _replacements.getStatistics,
        );

        // 注册 timer_getCompletedHistory 方法
        OpenAIPlugin.instance.registerPromptReplacementMethod(
          'timer_getCompletedHistory',
          _replacements.getCompletedHistory,
        );

        // 注册 timer_getGroupSummary 方法
        OpenAIPlugin.instance.registerPromptReplacementMethod(
          'timer_getGroupSummary',
          _replacements.getGroupSummary,
        );

        // 注册 timer_getTimerTypeStatistics 方法
        OpenAIPlugin.instance.registerPromptReplacementMethod(
          'timer_getTimerTypeStatistics',
          _replacements.getTimerTypeStatistics,
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
