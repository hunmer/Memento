import 'package:flutter/material.dart';

/// 表单字段分组容器
///
/// 功能特性：
/// - 提供统一的背景色和圆角卡片样式
/// - 支持子组件间的分隔线
/// - 适用于将多个inline模式的表单字段组合在一起
class FormFieldGroup extends StatelessWidget {
  /// 子组件列表
  final List<Widget> children;

  /// 是否在子组件之间显示分隔线
  final bool showDividers;

  /// 分隔线缩进（从左侧开始）
  final double dividerIndent;

  /// 分隔线缩进（从右侧开始）
  final double dividerEndIndent;

  /// 容器内边距
  final EdgeInsetsGeometry? padding;

  /// 圆角半径
  final double borderRadius;

  const FormFieldGroup({
    super.key,
    required this.children,
    this.showDividers = true,
    this.dividerIndent = 16,
    this.dividerEndIndent = 0,
    this.padding,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 在子组件之间插入分隔线
    final List<Widget> childrenWithDividers = [];
    for (int i = 0; i < children.length; i++) {
      childrenWithDividers.add(children[i]);

      // 不在最后一个元素后添加分隔线
      if (showDividers && i < children.length - 1) {
        childrenWithDividers.add(
          Divider(
            height: 1,
            indent: dividerIndent,
            endIndent: dividerEndIndent,
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: childrenWithDividers,
        ),
      ),
    );
  }
}
