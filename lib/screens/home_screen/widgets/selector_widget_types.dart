import 'package:flutter/material.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selectable_item.dart';

/// 数据渲染器：将选择器结果渲染为Widget
///
/// 参数：
/// - context: BuildContext
/// - result: 选择器返回的结果
/// - config: 小组件自定义配置
typedef SelectorDataRenderer = Widget Function(
  BuildContext context,
  SelectorResult result,
  Map<String, dynamic> config,
);

/// 导航处理器：处理点击后的跳转逻辑
///
/// 参数：
/// - context: BuildContext
/// - result: 选择器返回的结果
typedef SelectorNavigationHandler = void Function(
  BuildContext context,
  SelectorResult result,
);

/// 选择器小组件配置
///
/// 存储在 HomeWidgetItem.config['selectorWidgetConfig'] 中
class SelectorWidgetConfig {
  /// 选择的数据（SelectorResult 序列化）
  final Map<String, dynamic>? selectedData;

  /// 最后更新时间
  final DateTime? lastUpdated;

  SelectorWidgetConfig({
    this.selectedData,
    this.lastUpdated,
  });

  /// 是否已配置
  bool get isConfigured => selectedData != null;

  /// 转换为 JSON
  Map<String, dynamic> toJson() => {
    'selectedData': selectedData,
    'lastUpdated': lastUpdated?.toIso8601String(),
  };

  /// 从 JSON 加载
  factory SelectorWidgetConfig.fromJson(Map<String, dynamic> json) {
    return SelectorWidgetConfig(
      selectedData: json['selectedData'] as Map<String, dynamic>?,
      lastUpdated: json['lastUpdated'] != null
        ? DateTime.parse(json['lastUpdated'] as String)
        : null,
    );
  }

  /// 从 SelectorResult 创建配置
  factory SelectorWidgetConfig.fromSelectorResult(SelectorResult result) {
    return SelectorWidgetConfig(
      selectedData: result.toMap(),
      lastUpdated: DateTime.now(),
    );
  }

  /// 恢复 SelectorResult
  SelectorResult? toSelectorResult() {
    if (selectedData == null) return null;

    try {
      return SelectorResult(
        pluginId: selectedData!['plugin'] as String,
        selectorId: selectedData!['selector'] as String,
        path: (selectedData!['path'] as List<dynamic>?)
          ?.map((p) => SelectionPathItem(
            stepId: p['stepId'] as String,
            stepTitle: p['stepTitle'] as String,
            selectedItem: SelectableItem(
              id: p['selectedItemId'] as String,
              title: p['selectedItemTitle'] as String,
            ),
          ))
          .toList() ?? [],
        data: selectedData!['data'],
      );
    } catch (e) {
      debugPrint('[SelectorWidgetConfig] 恢复 SelectorResult 失败: $e');
      return null;
    }
  }
}
