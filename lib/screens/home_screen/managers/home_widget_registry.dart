import 'package:Memento/screens/home_screen/widgets/home_widget.dart';

/// 主页小组件注册中心（单例）
///
/// 管理所有插件注册的小组件定义
/// 提供查询和检索功能
class HomeWidgetRegistry {
  // 单例模式
  static final HomeWidgetRegistry _instance = HomeWidgetRegistry._internal();
  factory HomeWidgetRegistry() => _instance;
  HomeWidgetRegistry._internal();

  /// 所有已注册的小组件（key: widgetId）
  final Map<String, HomeWidget> _widgets = {};

  /// 注册一个小组件
  ///
  /// 如果已存在同ID的小组件，会覆盖
  void register(HomeWidget widget) {
    _widgets[widget.id] = widget;
  }

  /// 批量注册小组件
  void registerAll(List<HomeWidget> widgets) {
    for (var widget in widgets) {
      register(widget);
    }
  }

  /// 获取指定ID的小组件
  HomeWidget? getWidget(String id) {
    return _widgets[id];
  }

  /// 获取所有小组件
  List<HomeWidget> getAllWidgets() {
    return _widgets.values.toList();
  }

  /// 按分类获取小组件（用于添加对话框）
  Map<String, List<HomeWidget>> getWidgetsByCategory() {
    final result = <String, List<HomeWidget>>{};
    for (var widget in _widgets.values) {
      result.putIfAbsent(widget.category, () => []).add(widget);
    }
    return result;
  }

  /// 按插件ID获取小组件
  List<HomeWidget> getWidgetsByPlugin(String pluginId) {
    return _widgets.values
        .where((widget) => widget.pluginId == pluginId)
        .toList();
  }

  /// 获取所有分类名称
  List<String> getAllCategories() {
    return getWidgetsByCategory().keys.toList()..sort();
  }

  /// 获取支持公共小组件的插件小组件列表
  List<HomeWidget> getWidgetsSupportingCommonWidgets() {
    return _widgets.values
        .where((widget) => widget.supportsCommonWidgets)
        .toList();
  }

  /// 清空所有注册（主要用于测试）
  void clear() {
    _widgets.clear();
  }

  /// 获取注册数量
  int get count => _widgets.length;
}
