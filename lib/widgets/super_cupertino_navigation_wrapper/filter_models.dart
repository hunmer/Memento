import 'package:flutter/material.dart';

/// 过滤条件类型
enum FilterType {
  /// 单选标签
  tagsSingle,

  /// 多选标签
  tagsMultiple,

  /// 输入框
  input,

  /// 日期选择
  date,

  /// 日期范围选择
  dateRange,

  /// 复选框
  checkbox,

  /// 自定义
  custom,
}

/// 过滤条件配置
class FilterItem {
  /// 唯一标识
  final String id;

  /// 显示标题
  final String title;

  /// 过滤类型
  final FilterType type;

  /// 内容构建器
  /// 参数：
  /// - context: BuildContext
  /// - currentValue: 当前值
  /// - onChanged: 值变更回调
  final Widget Function(
    BuildContext context,
    dynamic currentValue,
    ValueChanged<dynamic> onChanged,
  ) builder;

  /// 从值生成 Badge 文本
  /// 返回 null 表示无 badge
  final String? Function(dynamic value)? getBadge;

  /// 初始值
  final dynamic initialValue;

  const FilterItem({
    required this.id,
    required this.title,
    required this.type,
    required this.builder,
    this.getBadge,
    this.initialValue,
  });

  /// 复制并修改部分属性
  FilterItem copyWith({
    String? id,
    String? title,
    FilterType? type,
    Widget Function(
      BuildContext context,
      dynamic currentValue,
      ValueChanged<dynamic> onChanged,
    )? builder,
    String? Function(dynamic value)? getBadge,
    dynamic initialValue,
  }) {
    return FilterItem(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      builder: builder ?? this.builder,
      getBadge: getBadge ?? this.getBadge,
      initialValue: initialValue ?? this.initialValue,
    );
  }
}

/// 过滤状态管理
class MultiFilterState extends ChangeNotifier {
  /// 存储每个过滤条件的值
  final Map<String, dynamic> _values = {};

  /// 获取指定过滤条件的值
  dynamic getValue(String filterId) {
    return _values[filterId];
  }

  /// 设置指定过滤条件的值
  void setValue(String filterId, dynamic value) {
    if (_values[filterId] != value) {
      _values[filterId] = value;
      notifyListeners();
    }
  }

  /// 清空所有过滤条件
  void clearAll() {
    if (_values.isNotEmpty) {
      _values.clear();
      notifyListeners();
    }
  }

  /// 清空指定过滤条件
  void clearFilter(String filterId) {
    if (_values.containsKey(filterId)) {
      _values.remove(filterId);
      notifyListeners();
    }
  }

  /// 获取所有过滤值
  Map<String, dynamic> getAllValues() {
    return Map.unmodifiable(_values);
  }

  /// 是否有任何过滤条件
  bool get hasAnyFilter {
    return _values.isNotEmpty;
  }

  /// 指定过滤条件是否有值
  bool hasFilter(String filterId) {
    final value = _values[filterId];
    if (value == null) return false;
    if (value is String) return value.isNotEmpty;
    if (value is List) return value.isNotEmpty;
    if (value is Map) return value.isNotEmpty;
    return true;
  }

  /// 从 Map 初始化
  void initializeFromMap(Map<String, dynamic> values) {
    _values.clear();
    _values.addAll(values);
    notifyListeners();
  }
}
