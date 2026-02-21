/// WebView插件 - 内置网页小组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'utils.dart';
import 'widgets/embedded_webview_widget.dart';

/// 注册内置网页小组件 - 在小组件中直接显示网页
void registerEmbeddedWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'webview_embedded',
      pluginId: 'webview',
      name: 'webview_embeddedName'.tr,
      description: 'webview_embeddedDesc'.tr,
      icon: Icons.web,
      color: const Color(0xFF4285F4),
      defaultSize: const CustomSize(width: -1, height: -1),
      supportedSizes: [const CustomSize(width: -1, height: -1)],
      category: 'home_categoryTools'.tr,

      // 选择器配置
      selectorId: 'webview.card',
      dataSelector: extractCardData,
      dataRenderer: renderEmbeddedWebView,
      navigationHandler: navigateToCardEmbedded,

      builder: (context, config) {
        return GenericSelectorWidget(
          widgetDefinition: registry.getWidget('webview_embedded')!,
          config: config,
        );
      },
    ),
  );
}

/// 渲染内置 WebView 小组件
Widget renderEmbeddedWebView(
  BuildContext context,
  SelectorResult result,
  Map<String, dynamic> config,
) {
  // dataSelector 已经将数据转换为 Map，直接使用
  if (result.data == null || result.data is! Map) {
    return HomeWidget.buildErrorWidget(context, '数据不存在或格式错误');
  }

  final cardData = result.data as Map<String, dynamic>;
  final url = cardData['url'] as String? ?? '';
  final title = cardData['title'] as String? ?? '未知卡片';

  if (url.isEmpty) {
    return HomeWidget.buildErrorWidget(context, 'URL 为空');
  }

  // 获取自定义尺寸
  final customWidth = config['customWidth'] as int? ?? 2;
  final customHeight = config['customHeight'] as int? ?? 2;

  return EmbeddedWebViewWidget(
    url: url,
    title: title,
    width: customWidth,
    height: customHeight,
  );
}

/// 导航到卡片（内置网页版本）
void navigateToCardEmbedded(BuildContext context, SelectorResult result) {
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
    arguments: {'url': url, 'cardId': cardId, 'hideUI': true},
  );
}
