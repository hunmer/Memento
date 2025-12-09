import 'package:flutter/material.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';

/// 选择器面包屑导航组件
///
/// 显示选择路径，支持点击跳转
class SelectorBreadcrumb extends StatelessWidget {
  /// 选择路径
  final List<SelectionPathItem> path;

  /// 当前步骤标题
  final String currentStep;

  /// 主题颜色
  final Color? themeColor;

  /// 点击步骤回调（返回步骤索引）
  final ValueChanged<int>? onStepTap;

  /// 是否允许点击
  final bool allowTap;

  const SelectorBreadcrumb({
    super.key,
    required this.path,
    required this.currentStep,
    this.themeColor,
    this.onStepTap,
    this.allowTap = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = themeColor ?? theme.colorScheme.primary;

    if (path.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: effectiveColor.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 历史步骤
            for (int i = 0; i < path.length; i++) ...[
              _BreadcrumbItem(
                title: path[i].selectedItem.title,
                isActive: false,
                canTap: allowTap && onStepTap != null,
                color: effectiveColor,
                onTap: allowTap && onStepTap != null
                    ? () => onStepTap!(i)
                    : null,
              ),
              _BreadcrumbSeparator(color: theme.colorScheme.onSurface.withOpacity(0.3)),
            ],
            // 当前步骤
            _BreadcrumbItem(
              title: currentStep,
              isActive: true,
              canTap: false,
              color: effectiveColor,
            ),
          ],
        ),
      ),
    );
  }
}

/// 面包屑项
class _BreadcrumbItem extends StatelessWidget {
  final String title;
  final bool isActive;
  final bool canTap;
  final Color color;
  final VoidCallback? onTap;

  const _BreadcrumbItem({
    required this.title,
    required this.isActive,
    required this.canTap,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayTitle = title.length > 12 ? '${title.substring(0, 12)}...' : title;

    Widget child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        displayTitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: isActive ? color : theme.colorScheme.onSurface.withOpacity(0.7),
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );

    if (canTap && onTap != null) {
      child = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: child,
      );
    }

    return child;
  }
}

/// 面包屑分隔符
class _BreadcrumbSeparator extends StatelessWidget {
  final Color color;

  const _BreadcrumbSeparator({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(
        Icons.chevron_right,
        size: 16,
        color: color,
      ),
    );
  }
}
