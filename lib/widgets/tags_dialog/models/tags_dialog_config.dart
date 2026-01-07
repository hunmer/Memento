import 'package:flutter/material.dart';

/// 显示模式枚举
enum TagsDisplayMode {
  /// 对话框模式
  dialog,

  /// 嵌入模式
  embedded,
}

/// 选择模式枚举
enum TagsSelectionMode {
  /// 无选择模式（仅查看）
  none,

  /// 单选模式
  single,

  /// 多选模式
  multiple,
}

/// 排序方式枚举
enum TagsSortType {
  /// 按添加时间排序
  createdAt,

  /// 按最后使用时间排序
  lastUsedAt,

  /// 按名称排序
  name,
}

/// TagsDialog 配置类
class TagsDialogConfig {
  /// 标题
  final String title;

  /// 大标题
  final String largeTitle;

  /// 搜索占位符
  final String searchPlaceholder;

  /// 默认图标
  final IconData defaultIcon;

  /// 是否启用编辑功能
  final bool enableEditing;

  /// 是否启用批量编辑
  final bool enableBatchEdit;

  /// 是否启用长按菜单
  final bool enableLongPressMenu;

  /// 选择模式
  final TagsSelectionMode selectionMode;

  /// 确认按钮文本
  final String confirmButtonText;

  /// 取消按钮文本
  final String cancelButtonText;

  /// 删除按钮文本
  final String deleteButtonText;

  /// 编辑按钮文本
  final String editButtonText;

  /// 添加标签文本
  final String addTagText;

  /// 添加分组文本
  final String addGroupText;

  /// 空状态提示文本
  final String emptyStateText;

  /// 选中标签颜色
  final Color? selectedTagColor;

  /// 标签卡片圆角
  final double tagCardRadius;

  /// 标签卡片高度
  final double tagCardHeight;

  const TagsDialogConfig({
    this.title = '标签管理',
    this.largeTitle = '标签',
    this.searchPlaceholder = '搜索标签名称、注释...',
    this.defaultIcon = Icons.label,
    this.enableEditing = true,
    this.enableBatchEdit = true,
    this.enableLongPressMenu = true,
    this.selectionMode = TagsSelectionMode.none,
    this.confirmButtonText = '确定',
    this.cancelButtonText = '取消',
    this.deleteButtonText = '删除',
    this.editButtonText = '编辑',
    this.addTagText = '添加标签',
    this.addGroupText = '添加分组',
    this.emptyStateText = '暂无标签',
    this.selectedTagColor,
    this.tagCardRadius = 8,
    this.tagCardHeight = 60,
  });

  /// 创建副本
  TagsDialogConfig copyWith({
    String? title,
    String? largeTitle,
    String? searchPlaceholder,
    IconData? defaultIcon,
    bool? enableEditing,
    bool? enableBatchEdit,
    bool? enableLongPressMenu,
    TagsSelectionMode? selectionMode,
    String? confirmButtonText,
    String? cancelButtonText,
    String? deleteButtonText,
    String? editButtonText,
    String? addTagText,
    String? addGroupText,
    String? emptyStateText,
    Color? selectedTagColor,
    double? tagCardRadius,
    double? tagCardHeight,
  }) {
    return TagsDialogConfig(
      title: title ?? this.title,
      largeTitle: largeTitle ?? this.largeTitle,
      searchPlaceholder: searchPlaceholder ?? this.searchPlaceholder,
      defaultIcon: defaultIcon ?? this.defaultIcon,
      enableEditing: enableEditing ?? this.enableEditing,
      enableBatchEdit: enableBatchEdit ?? this.enableBatchEdit,
      enableLongPressMenu: enableLongPressMenu ?? this.enableLongPressMenu,
      selectionMode: selectionMode ?? this.selectionMode,
      confirmButtonText: confirmButtonText ?? this.confirmButtonText,
      cancelButtonText: cancelButtonText ?? this.cancelButtonText,
      deleteButtonText: deleteButtonText ?? this.deleteButtonText,
      editButtonText: editButtonText ?? this.editButtonText,
      addTagText: addTagText ?? this.addTagText,
      addGroupText: addGroupText ?? this.addGroupText,
      emptyStateText: emptyStateText ?? this.emptyStateText,
      selectedTagColor: selectedTagColor ?? this.selectedTagColor,
      tagCardRadius: tagCardRadius ?? this.tagCardRadius,
      tagCardHeight: tagCardHeight ?? this.tagCardHeight,
    );
  }
}
