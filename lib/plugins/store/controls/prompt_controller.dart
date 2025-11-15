import '../../openai/openai_plugin.dart';
import '../store_plugin.dart';
import '../services/prompt_replacements.dart';

/// Store 插件的 Prompt 控制器
///
/// 负责注册 Prompt 替换方法到 OpenAI 插件
class StorePromptController {
  final StorePlugin plugin;
  late final StorePromptReplacements _replacements;

  StorePromptController(this.plugin) {
    _replacements = StorePromptReplacements(plugin);
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
        // 注册所有 8 个方法

        // 1. 获取商品列表
        OpenAIPlugin.instance.registerPromptReplacementMethod(
          'store_getProducts',
          _replacements.getProducts,
        );

        // 2. 获取用户物品列表
        OpenAIPlugin.instance.registerPromptReplacementMethod(
          'store_getUserItems',
          _replacements.getUserItems,
        );

        // 3. 获取积分历史
        OpenAIPlugin.instance.registerPromptReplacementMethod(
          'store_getPointsHistory',
          _replacements.getPointsHistory,
        );

        // 4. 获取兑换历史
        OpenAIPlugin.instance.registerPromptReplacementMethod(
          'store_getRedeemHistory',
          _replacements.getRedeemHistory,
        );

        // 5. 获取积分统计
        OpenAIPlugin.instance.registerPromptReplacementMethod(
          'store_getPointsStats',
          _replacements.getPointsStats,
        );

        // 6. 获取归档商品列表
        OpenAIPlugin.instance.registerPromptReplacementMethod(
          'store_getArchivedProducts',
          _replacements.getArchivedProducts,
        );

        // 7. 获取即将过期的物品
        OpenAIPlugin.instance.registerPromptReplacementMethod(
          'store_getExpiringItems',
          _replacements.getExpiringItems,
        );

        // 8. 获取使用历史
        OpenAIPlugin.instance.registerPromptReplacementMethod(
          'store_getUsageHistory',
          _replacements.getUsageHistory,
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
