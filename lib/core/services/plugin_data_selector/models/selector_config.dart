import 'package:flutter/material.dart';

/// 选择器显示配置
class SelectorConfig {
  /// 对话框标题（可覆盖默认）
  final String? title;

  /// 确认按钮文本
  final String? confirmText;

  /// 取消按钮文本
  final String? cancelText;

  /// 是否显示面包屑导航
  final bool showBreadcrumb;

  /// 是否允许跳回前序步骤
  final bool allowBackNavigation;

  /// 主题色（默认使用插件颜色）
  final Color? themeColor;

  /// Sheet 最小高度比例（0.0-1.0）
  final double minHeightRatio;

  /// Sheet 最大高度比例（0.0-1.0）
  final double maxHeightRatio;

  /// Sheet 初始高度比例（0.0-1.0）
  final double initialHeightRatio;

  /// 初始选择（用于编辑模式）
  final Map<String, dynamic>? initialSelection;

  /// 是否显示搜索框
  final bool showSearch;

  /// 搜索框占位文本
  final String? searchHint;

  /// 是否显示关闭按钮
  final bool showCloseButton;

  /// 是否可通过下滑关闭
  final bool swipeDismissible;

  /// 自定义空状态组件
  final Widget? emptyStateWidget;

  const SelectorConfig({
    this.title,
    this.confirmText,
    this.cancelText,
    this.showBreadcrumb = true,
    this.allowBackNavigation = true,
    this.themeColor,
    this.minHeightRatio = 0.3,
    this.maxHeightRatio = 0.9,
    this.initialHeightRatio = 0.5,
    this.initialSelection,
    this.showSearch = true,
    this.searchHint,
    this.showCloseButton = true,
    this.swipeDismissible = true,
    this.emptyStateWidget,
  });

  /// 创建副本
  SelectorConfig copyWith({
    String? title,
    String? confirmText,
    String? cancelText,
    bool? showBreadcrumb,
    bool? allowBackNavigation,
    Color? themeColor,
    double? minHeightRatio,
    double? maxHeightRatio,
    double? initialHeightRatio,
    Map<String, dynamic>? initialSelection,
    bool? showSearch,
    String? searchHint,
    bool? showCloseButton,
    bool? swipeDismissible,
    Widget? emptyStateWidget,
  }) {
    return SelectorConfig(
      title: title ?? this.title,
      confirmText: confirmText ?? this.confirmText,
      cancelText: cancelText ?? this.cancelText,
      showBreadcrumb: showBreadcrumb ?? this.showBreadcrumb,
      allowBackNavigation: allowBackNavigation ?? this.allowBackNavigation,
      themeColor: themeColor ?? this.themeColor,
      minHeightRatio: minHeightRatio ?? this.minHeightRatio,
      maxHeightRatio: maxHeightRatio ?? this.maxHeightRatio,
      initialHeightRatio: initialHeightRatio ?? this.initialHeightRatio,
      initialSelection: initialSelection ?? this.initialSelection,
      showSearch: showSearch ?? this.showSearch,
      searchHint: searchHint ?? this.searchHint,
      showCloseButton: showCloseButton ?? this.showCloseButton,
      swipeDismissible: swipeDismissible ?? this.swipeDismissible,
      emptyStateWidget: emptyStateWidget ?? this.emptyStateWidget,
    );
  }
}
