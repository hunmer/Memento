import 'dart:io';
import 'package:flutter/material.dart';
import '../models/plugin_widget_config.dart';
import '../../../utils/image_utils.dart';

/// 通用插件小组件
///
/// 支持自定义配置的统一小组件，包括：
/// - 显示风格（一列/两列文字）
/// - 可选择的统计项
/// - 背景图片
/// - 图标颜色
/// - 背景颜色
class GenericPluginWidget extends StatelessWidget {
  /// 插件名称
  final String pluginName;

  /// 插件图标
  final IconData pluginIcon;

  /// 插件默认颜色
  final Color pluginDefaultColor;

  /// 可用的统计项数据
  final List<StatItemData> availableItems;

  /// 小组件配置
  final PluginWidgetConfig config;

  const GenericPluginWidget({
    super.key,
    required this.pluginName,
    required this.pluginIcon,
    required this.pluginDefaultColor,
    required this.availableItems,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 计算最终的图标颜色和背景颜色
    final finalIconColor = config.iconColor ?? pluginDefaultColor;
    final finalBackgroundColor = config.backgroundColor ?? theme.cardColor;

    return Container(
      decoration: BoxDecoration(
        color: config.backgroundImagePath == null
          ? finalBackgroundColor
          : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        image: config.backgroundImagePath != null
          ? _buildBackgroundImage(config.backgroundImagePath!)
          : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部图标和标题
            _buildHeader(theme, finalIconColor),

            const SizedBox(height: 16),

            // 统计信息
            Expanded(
              child: _buildStatItems(theme, finalIconColor),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建背景图片
  DecorationImage? _buildBackgroundImage(String path) {
    try {
      return DecorationImage(
        image: FileImage(File(ImageUtils.getAbsolutePathSync(path))),
        fit: BoxFit.cover,
        opacity: 0.2, // 降低不透明度避免影响文字显示
      );
    } catch (e) {
      debugPrint('加载背景图片失败: $e');
      return null;
    }
  }

  /// 构建头部（图标和标题）
  Widget _buildHeader(ThemeData theme, Color iconColor) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            pluginIcon,
            size: 24,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            pluginName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              // 如果有背景图片，增强文字对比度
              color: config.backgroundImagePath != null
                ? theme.colorScheme.onSurface
                : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// 构建统计项
  Widget _buildStatItems(ThemeData theme, Color iconColor) {
    // 过滤出选中的统计项
    final selectedItems = availableItems.where((item) {
      return config.selectedItemIds.isEmpty ||
        config.selectedItemIds.contains(item.id);
    }).toList();

    if (selectedItems.isEmpty) {
      return Center(
        child: Text(
          '暂无数据',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
      );
    }

    // 根据显示风格选择布局
    return config.displayStyle == PluginWidgetDisplayStyle.oneColumn
      ? _buildOneColumnLayout(selectedItems, theme, iconColor)
      : _buildTwoColumnsLayout(selectedItems, theme, iconColor);
  }

  /// 一列布局
  Widget _buildOneColumnLayout(
    List<StatItemData> items,
    ThemeData theme,
    Color iconColor,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: items.map((item) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: _StatItem(
          data: item,
          theme: theme,
          defaultColor: iconColor,
        ),
      )).toList(),
    );
  }

  /// 两列布局
  Widget _buildTwoColumnsLayout(
    List<StatItemData> items,
    ThemeData theme,
    Color iconColor,
  ) {
    // 将items按照2个一组分组
    final rows = <Widget>[];

    for (int i = 0; i < items.length; i += 2) {
      final firstItem = items[i];
      final secondItem = i + 1 < items.length ? items[i + 1] : null;

      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: _StatItem(
                data: firstItem,
                theme: theme,
                defaultColor: iconColor,
              ),
            ),
            if (secondItem != null) ...[
              Container(
                width: 1,
                height: 30,
                color: theme.dividerColor,
              ),
              Expanded(
                child: _StatItem(
                  data: secondItem,
                  theme: theme,
                  defaultColor: iconColor,
                ),
              ),
            ],
          ],
        ),
      );

      // 添加间距（除了最后一行）
      if (i + 2 < items.length) {
        rows.add(const SizedBox(height: 12));
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: rows,
    );
  }
}

/// 统计项组件
class _StatItem extends StatelessWidget {
  final StatItemData data;
  final ThemeData theme;
  final Color defaultColor;

  const _StatItem({
    required this.data,
    required this.theme,
    required this.defaultColor,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = data.highlight
      ? (data.color ?? defaultColor)
      : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          data.label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodySmall?.color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          data.value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: displayColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
