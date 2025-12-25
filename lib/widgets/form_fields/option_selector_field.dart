import 'package:flutter/material.dart';

/// 选项数据模型
class OptionItem {
  /// 选项ID
  final String id;

  /// 显示图标（当 useTextAsIcon 为 false 时使用）
  final IconData? icon;

  /// 显示标签
  final String label;

  /// 显示文本（当 useTextAsIcon 为 true 时使用，可以是 emoji）
  final String? subtitle;

  /// 是否使用文本代替图标
  final bool useTextAsIcon;

  const OptionItem({
    required this.id,
    this.icon,
    required this.label,
    this.subtitle,
    this.useTextAsIcon = false,
  });
}

/// 选项选择组件
///
/// 功能特性：
/// - 支持单选功能
/// - 支持多种布局方式（水平滚动或网格）
/// - 统一的样式和主题适配
/// - 适用于分类、状态等选择场景
class OptionSelectorField extends StatelessWidget {
  /// 选项列表
  final List<OptionItem> options;

  /// 当前选中的选项ID
  final String? selectedId;

  /// 选择变更回调
  final Function(String optionId) onSelectionChanged;

  /// 标签文本
  final String? labelText;

  /// 布局方式
  final bool useHorizontalScroll;

  /// 选项卡片宽度（水平滚动模式下使用）
  final double optionWidth;

  /// 选项卡片高度（水平滚动模式下使用）
  final double optionHeight;

  /// 网格列数（网格模式下使用）
  final int gridColumns;

  /// 主题色
  final Color primaryColor;

  const OptionSelectorField({
    super.key,
    required this.options,
    this.selectedId,
    required this.onSelectionChanged,
    this.labelText,
    this.useHorizontalScroll = true,
    this.optionWidth = 96,
    this.optionHeight = 96,
    this.gridColumns = 4,
    this.primaryColor = const Color(0xFF607AFB),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (labelText != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                labelText!,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
          if (useHorizontalScroll)
            _buildHorizontalScroll(theme)
          else
            _buildGridLayout(theme),
        ],
      ),
    );
  }

  Widget _buildHorizontalScroll(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      child: Row(
          children: options.map((option) {
            final isSelected = selectedId == option.id;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: InkWell(
                onTap: () => onSelectionChanged(option.id),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: optionWidth,
                  height: optionHeight,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor
                        : theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? primaryColor
                          : theme.colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                          if (option.useTextAsIcon)
                            Text(
                              option.label,
                              style: TextStyle(
                                fontSize: 32,
                                color:
                                    isSelected
                                        ? Colors.white
                                        : theme.colorScheme.onSurface,
                              ),
                            )
                          else if (option.icon != null)
                            Icon(
                              option.icon,
                              size: 32,
                              color:
                                  isSelected
                                      ? Colors.white
                                      : theme.colorScheme.onSurface,
                            ),
                          if (!option.useTextAsIcon) ...[
                            const SizedBox(height: 8),
                            Text(
                              option.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color:
                                    isSelected
                                        ? Colors.white
                                        : theme.colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
      ),
    );
  }

  Widget _buildGridLayout(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth =
            (constraints.maxWidth - (gridColumns - 1) * 8) / gridColumns;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedId == option.id;
            return InkWell(
              onTap: () => onSelectionChanged(option.id),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: itemWidth,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor
                      : theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? primaryColor
                        : theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                        if (option.useTextAsIcon)
                          Text(
                            option.label,
                            style: TextStyle(
                              fontSize: 28,
                              color:
                                  isSelected
                                      ? Colors.white
                                      : theme.colorScheme.onSurface,
                            ),
                          )
                        else if (option.icon != null)
                          Icon(
                            option.icon,
                            size: 24,
                            color:
                                isSelected
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
                          ),
                        if (!option.useTextAsIcon) ...[
                          const SizedBox(height: 4),
                          Text(
                            option.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color:
                                  isSelected
                                      ? Colors.white
                                      : theme.colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
