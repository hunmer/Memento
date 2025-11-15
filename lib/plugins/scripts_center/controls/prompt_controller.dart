import '../../openai/openai_plugin.dart';
import '../scripts_center_plugin.dart';
import '../services/prompt_replacements.dart';

/// ScriptsCenter 插件的 Prompt 控制器
///
/// 负责注册 Prompt 替换方法到 OpenAI 插件
class ScriptsCenterPromptController {
  final ScriptsCenterPlugin plugin;
  late final ScriptsCenterPromptReplacements _replacements;

  ScriptsCenterPromptController(this.plugin) {
    _replacements = ScriptsCenterPromptReplacements(plugin);
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
        // 获取 OpenAI 插件实例
        final openaiPlugin = OpenAIPlugin.instance;

        // 注册所有方法
        openaiPlugin.registerPromptReplacementMethod(
          'scripts_center_getScripts',
          _replacements.getScripts,
        );

        openaiPlugin.registerPromptReplacementMethod(
          'scripts_center_getScriptDetail',
          _replacements.getScriptDetail,
        );

        openaiPlugin.registerPromptReplacementMethod(
          'scripts_center_getExecutionHistory',
          _replacements.getExecutionHistory,
        );

        openaiPlugin.registerPromptReplacementMethod(
          'scripts_center_getStatistics',
          _replacements.getStatistics,
        );

        openaiPlugin.registerPromptReplacementMethod(
          'scripts_center_getTriggers',
          _replacements.getTriggers,
        );

        openaiPlugin.registerPromptReplacementMethod(
          'scripts_center_getFolders',
          _replacements.getFolders,
        );

        print('✅ ScriptsCenter Prompt 方法注册成功 (6个方法)');
      } catch (e) {
        print('⚠️ ScriptsCenter Prompt 方法注册失败: $e');
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
