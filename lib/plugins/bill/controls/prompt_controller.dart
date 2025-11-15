import '../../openai/openai_plugin.dart';
import '../bill_plugin.dart';
import '../services/prompt_replacements.dart';

/// Bill 插件的 Prompt 控制器
///
/// 负责注册 Prompt 替换方法到 OpenAI 插件
class PromptController {
  final BillPlugin plugin;
  late final BillPromptReplacements _replacements;

  PromptController(this.plugin) {
    _replacements = BillPromptReplacements(plugin);
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
        // 注册 bill_getBills 方法
        OpenAIPlugin.instance.registerPromptReplacementMethod(
          'bill_getBills',
          _replacements.getBills,
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
      OpenAIPlugin.instance.unregisterPromptReplacementMethod('bill_getBills');
    } catch (e) {
      // 忽略注销错误
    }
  }

  /// 释放资源
  void dispose() {
    _replacements.dispose();
  }
}
