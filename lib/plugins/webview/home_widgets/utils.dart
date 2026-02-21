/// WebView插件主页小组件工具函数
library;

import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';

/// 从选择器数据中提取必要字段保存到本地存储
Map<String, dynamic> extractCardData(List<dynamic> dataArray) {
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

/// 导航到卡片
void navigateToCard(BuildContext context, SelectorResult result) {
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
