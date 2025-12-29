import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'webview_plugin.dart';
import 'widgets/embedded_webview.dart';

/// WebView插件的主页小组件注册
class WebviewHomeWidgets {
  /// 注册所有WebView插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(
      HomeWidget(
        id: 'webview_icon',
        pluginId: 'webview',
        name: 'webview_widgetName'.tr,
        description: 'webview_widgetDescription'.tr,
        icon: Icons.language,
        color: const Color(0xFF4285F4),
        defaultSize: HomeWidgetSize.small,
        supportedSizes: [HomeWidgetSize.small],
        category: 'home_categoryTools'.tr,
        builder:
            (context, config) => GenericIconWidget(
              icon: Icons.language,
              color: const Color(0xFF4285F4),
              name: 'webview_name'.tr,
            ),
      ),
    );

    // 2x2 详细卡片 - 显示浏览器统计
    registry.register(
      HomeWidget(
        id: 'webview_overview',
        pluginId: 'webview',
        name: 'webview_overviewName'.tr,
        description: 'webview_overviewDescription'.tr,
        icon: Icons.language_outlined,
        color: const Color(0xFF4285F4),
        defaultSize: HomeWidgetSize.large,
        supportedSizes: [HomeWidgetSize.large],
        category: 'home_categoryTools'.tr,
        builder: (context, config) => _buildOverviewWidget(context, config),
        availableStatsProvider: _getAvailableStats,
      ),
    );

    // URL 卡片选择器小组件 - 快速访问特定卡片
    registry.register(
      HomeWidget(
        id: 'webview_card_selector',
        pluginId: 'webview',
        name: 'webview_cardQuickAccess'.tr,
        description: 'webview_cardQuickAccessDesc'.tr,
        icon: Icons.link,
        color: const Color(0xFF4285F4),
        defaultSize: HomeWidgetSize.large,
        supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
        category: 'home_categoryTools'.tr,

        // 选择器配置
        selectorId: 'webview.card',
        dataSelector: _extractCardData,
        dataRenderer: _renderCardData,
        navigationHandler: _navigateToCard,

        builder: (context, config) {
          // GenericSelectorWidget 只负责显示，不处理点击
          // 点击事件由 HomeCard 处理
          return GenericSelectorWidget(
            widgetDefinition: registry.getWidget('webview_card_selector')!,
            config: config,
          );
        },
      ),
    );

    // 内置网页小组件 - 在小组件中直接显示网页
    registry.register(
      HomeWidget(
        id: 'webview_embedded',
        pluginId: 'webview',
        name: 'webview_embeddedName'.tr,
        description: 'webview_embeddedDesc'.tr,
        icon: Icons.web,
        color: const Color(0xFF4285F4),
        defaultSize: HomeWidgetSize.custom,
        supportedSizes: [HomeWidgetSize.custom],
        category: 'home_categoryTools'.tr,

        // 选择器配置
        selectorId: 'webview.card',
        dataSelector: _extractCardData,
        dataRenderer: _renderEmbeddedWebView,
        navigationHandler: _navigateToCard,

        builder: (context, config) {
          return GenericSelectorWidget(
            widgetDefinition: registry.getWidget('webview_embedded')!,
            config: config,
          );
        },
      ),
    );
  }

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats(BuildContext context) {
    try {
      final plugin =
          PluginManager.instance.getPlugin('webview') as WebViewPlugin?;
      if (plugin == null) return [];

      final cardsCount = plugin.getTotalCardsCount();
      final tabsCount = plugin.getActiveTabsCount();

      return [
        StatItemData(
          id: 'total_cards',
          label: 'webview_cards'.tr,
          value: '$cardsCount',
          highlight: cardsCount > 0,
          color: const Color(0xFF4285F4),
        ),
        StatItemData(
          id: 'active_tabs',
          label: 'webview_tabs'.tr,
          value: '$tabsCount',
          highlight: tabsCount > 0,
          color: Colors.green,
        ),
      ];
    } catch (e) {
      return [];
    }
  }

  /// 构建 2x2 详细卡片组件
  static Widget _buildOverviewWidget(
    BuildContext context,
    Map<String, dynamic> config,
  ) {
    try {
      // 解析插件配置
      PluginWidgetConfig widgetConfig;
      try {
        if (config.containsKey('pluginWidgetConfig')) {
          widgetConfig = PluginWidgetConfig.fromJson(
            config['pluginWidgetConfig'] as Map<String, dynamic>,
          );
        } else {
          widgetConfig = PluginWidgetConfig();
        }
      } catch (e) {
        widgetConfig = PluginWidgetConfig();
      }

      // 获取可用的统计项数据
      final availableItems = _getAvailableStats(context);

      // 使用通用小组件
      return GenericPluginWidget(
        pluginId: 'webview',
        pluginName: 'webview_name'.tr,
        pluginIcon: Icons.language,
        pluginDefaultColor: const Color(0xFF4285F4),
        availableItems: availableItems,
        config: widgetConfig,
      );
    } catch (e) {
      return _buildErrorWidget(context, e.toString());
    }
  }

  /// 构建错误提示组件
  static Widget _buildErrorWidget(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 32, color: Colors.red),
          const SizedBox(height: 8),
          Text(
            'home_loadFailed'.tr,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  // ===== 选择器小组件相关方法 =====

  /// 从选择器数据中提取必要字段保存到本地存储
  static Map<String, dynamic> _extractCardData(List<dynamic> dataArray) {
    if (dataArray.isEmpty) {
      return {};
    }

    final itemData = dataArray[0] as Map<String, dynamic>;

    return {
      'id': itemData['id'] as String?,
      'title': itemData['title'] as String?,
      'url': itemData['url'] as String?,
      'type': itemData['type'] as String?,
    };
  }

  /// 渲染卡片数据
  static Widget _renderCardData(
    BuildContext context,
    SelectorResult result,
    Map<String, dynamic> config,
  ) {
    final theme = Theme.of(context);

    // dataSelector 已经将数据转换为 Map，直接使用
    if (result.data == null || result.data is! Map) {
      return _buildErrorWidget(context, '数据不存在或格式错误');
    }

    final cardData = result.data as Map<String, dynamic>;
    final title = cardData['title'] as String? ?? '未知卡片';
    final url = cardData['url'] as String? ?? '';
    final type = cardData['type'] as String?;
    final isLocalFile = type == 'local';

    return Material(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 顶部标签行
            Row(
              children: [
                if (isLocalFile)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'webview_localFile'.tr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
            // 卡片标题
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // URL 或路径
            Row(
              children: [
                Icon(
                  isLocalFile ? Icons.folder : Icons.public,
                  size: 16,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    url,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 渲染内置 WebView 小组件
  static Widget _renderEmbeddedWebView(
    BuildContext context,
    SelectorResult result,
    Map<String, dynamic> config,
  ) {
    // dataSelector 已经将数据转换为 Map，直接使用
    if (result.data == null || result.data is! Map) {
      return _buildErrorWidget(context, '数据不存在或格式错误');
    }

    final cardData = result.data as Map<String, dynamic>;
    final url = cardData['url'] as String? ?? '';
    final title = cardData['title'] as String? ?? '未知卡片';

    if (url.isEmpty) {
      return _buildErrorWidget(context, 'URL 为空');
    }

    // 获取自定义尺寸
    final customWidth = config['customWidth'] as int? ?? 2;
    final customHeight = config['customHeight'] as int? ?? 2;

    return _EmbeddedWebViewWidget(
      url: url,
      title: title,
      width: customWidth,
      height: customHeight,
    );
  }

  /// 导航到卡片
  static void _navigateToCard(BuildContext context, SelectorResult result) {
    // dataSelector 已经将数据转换为 Map，直接使用
    if (result.data == null || result.data is! Map) {
      return;
    }

    final cardData = result.data as Map<String, dynamic>;
    final cardId = cardData['id'] as String?;
    final url = cardData['url'] as String?;

    if (cardId == null || url == null) return;

    // 跳转到 WebView 浏览器，直接打开该 URL
    NavigationHelper.pushNamed(
      context,
      '/webview/browser',
      arguments: {'url': url, 'cardId': cardId},
    );
  }
}

/// 嵌入式 WebView 小组件件
class _EmbeddedWebViewWidget extends StatefulWidget {
  final String url;
  final String title;
  final int width;
  final int height;

  const _EmbeddedWebViewWidget({
    required this.url,
    required this.title,
    required this.width,
    required this.height,
  });

  @override
  State<_EmbeddedWebViewWidget> createState() => _EmbeddedWebViewWidgetState();
}

class _EmbeddedWebViewWidgetState extends State<_EmbeddedWebViewWidget> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 添加超时机制：10 秒后自动隐藏加载指示器
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // 使用可复用的 EmbeddedWebView 组件
            EmbeddedWebView(
              url: widget.url,
              onLoadingChanged: (isLoading) {
                if (mounted && _isLoading != isLoading) {
                  setState(() {
                    _isLoading = isLoading;
                  });
                }
              },
            ),
            // 加载进度指示器
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text('加载中...', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
