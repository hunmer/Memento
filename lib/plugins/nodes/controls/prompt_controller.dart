import '../services/prompt_replacements.dart';
import '../../openai/openai_plugin.dart';

/// Nodes 插件的 Prompt 控制器
///
/// 负责注册 Prompt 替换方法到 OpenAI 插件
class NodesPromptController {
  final NodesPromptReplacements _replacements = NodesPromptReplacements();

  /// 初始化并注册Prompt方法
  void initialize() {
    // 初始化prompt替换服务
    _replacements.initialize();

    // 延迟注册prompt替换方法，等待OpenAI插件初始化完成
    _registerPromptMethods();
  }

  /// 注册Prompt替换方法
  void _registerPromptMethods() {
    Future.delayed(const Duration(seconds: 1), () {
      try {
        // 注册 nodes_getNodePaths 方法
        OpenAIPlugin.instance.registerPromptReplacementMethod(
          'nodes_getNodePaths',
          _replacements.getNodePaths,
        );

        // 注册向后兼容的旧方法名（如果存在）
        OpenAIPlugin.instance.registerPromptReplacementMethod(
          'nodes_getNodes',
          _replacements.getNodePaths,
        );
      } catch (e) {
        // 如果OpenAI插件还未准备好，5秒后重试
        Future.delayed(const Duration(seconds: 5), _registerPromptMethods);
      }
    });
  }

  /// 注销Prompt替换方法
  void unregisterPromptMethods() {
    try {
      OpenAIPlugin.instance.unregisterPromptReplacementMethod('nodes_getNodePaths');
      OpenAIPlugin.instance.unregisterPromptReplacementMethod('nodes_getNodes');
    } catch (e) {
      // 忽略错误
    }

    // 清理prompt替换服务
    _replacements.dispose();
  }

  /// 释放资源
  void dispose() {
    _replacements.dispose();
  }
}
