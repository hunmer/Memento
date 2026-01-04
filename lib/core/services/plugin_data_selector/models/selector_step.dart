import 'selectable_item.dart';
import 'package:flutter/material.dart';

/// 选择器视图类型
enum SelectorViewType {
  /// 列表视图
  list,

  /// 网格视图
  grid,

  /// 日历视图
  calendar,

  /// 自定义表单视图
  customForm,
}

/// 选择步骤数据加载器类型
typedef SelectorDataLoader = Future<List<SelectableItem>> Function(
  Map<String, dynamic> previousSelections,
);

/// 选择步骤搜索过滤器类型
typedef SelectorSearchFilter = List<SelectableItem> Function(
  List<SelectableItem> items,
  String query,
);

/// 自定义表单构建器类型
typedef CustomFormBuilder = Widget Function(
  BuildContext context,
  Map<String, dynamic> previousSelections,
  Function(dynamic) onComplete,
);

/// 选择步骤
///
/// 定义多级选择中的每一级
class SelectorStep {
  /// 步骤 ID（用于内部标识）
  final String id;

  /// 步骤标题
  final String title;

  /// 视图类型
  final SelectorViewType viewType;

  /// 数据加载器（接收前序选择结果，返回当前步骤的数据项）
  final SelectorDataLoader dataLoader;

  /// 搜索过滤器（可选，用于本地搜索）
  final SelectorSearchFilter? searchFilter;

  /// 是否为最终选择步骤
  final bool isFinalStep;

  /// 空状态提示文本
  final String? emptyText;

  /// 网格视图的列数（仅 grid 视图有效）
  final int gridCrossAxisCount;

  /// 网格视图的子项宽高比（仅 grid 视图有效）
  final double gridChildAspectRatio;

  /// 自定义表单构建器（仅 customForm 视图有效）
  final CustomFormBuilder? customFormBuilder;

  const SelectorStep({
    required this.id,
    required this.title,
    required this.viewType,
    required this.dataLoader,
    this.searchFilter,
    this.isFinalStep = false,
    this.emptyText,
    this.gridCrossAxisCount = 2,
    this.gridChildAspectRatio = 1.0,
    this.customFormBuilder,
  });

  /// 默认搜索过滤器
  static List<SelectableItem> defaultSearchFilter(
    List<SelectableItem> items,
    String query,
  ) {
    if (query.isEmpty) return items;

    final lowerQuery = query.toLowerCase();
    return items.where((item) {
      return item.title.toLowerCase().contains(lowerQuery) ||
          (item.subtitle?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  /// 执行搜索
  List<SelectableItem> performSearch(
    List<SelectableItem> items,
    String query,
  ) {
    if (query.isEmpty) return items;
    return (searchFilter ?? defaultSearchFilter)(items, query);
  }
}
