/// WebView插件 - URL卡片选择器小组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'utils.dart';

/// 注册 URL 卡片选择器小组件 - 快速访问特定卡片
void registerCardSelectorWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'webview_card_selector',
      pluginId: 'webview',
      name: 'webview_cardQuickAccess'.tr,
      description: 'webview_cardQuickAccessDesc'.tr,
      icon: Icons.link,
      color: const Color(0xFF4285F4),
      defaultSize: const LargeSize(),
      supportedSizes: [const MediumSize(), const LargeSize()],
      category: 'home_categoryTools'.tr,

      // 选择器配置
      selectorId: 'webview.card',
      dataSelector: extractCardData,
      dataRenderer: renderCardData,

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
}

/// 渲染卡片数据
Widget renderCardData(
  BuildContext context,
  SelectorResult result,
  Map<String, dynamic> config,
) {
  final theme = Theme.of(context);

  // dataSelector 已经将数据转换为 Map，直接使用
  if (result.data == null || result.data is! Map) {
    return HomeWidget.buildErrorWidget(context, '数据不存在或格式错误');
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
