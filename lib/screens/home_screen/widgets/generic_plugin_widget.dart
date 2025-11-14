import 'dart:io';
import 'package:flutter/material.dart';
import '../models/plugin_widget_config.dart';
import '../../../utils/image_utils.dart';

/// 通用图标小组件构建器
///
/// 用于创建简单的 1x1 图标组件
class GenericIconWidget extends StatelessWidget {
  final IconData icon;
  final Color color;

  const GenericIconWidget({
    super.key,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 根据可用空间计算图标大小
        final size = constraints.maxWidth.clamp(0.0, constraints.maxHeight);
        final iconSize = size * 0.5; // 图标占容器的50%

        return Center(
          child: Icon(
            icon,
            size: iconSize,
            color: color,
          ),
        );
      },
    );
  }
}

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

    // 使用 LayoutBuilder 获取小组件的实际大小，实现响应式设计
    return LayoutBuilder(
      builder: (context, constraints) {
        // 根据可用空间计算合适的尺寸
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;

        // 计算响应式尺寸
        final iconSize = _calculateIconSize(availableWidth, availableHeight);
        final fontSize = _calculateFontSize(availableWidth, availableHeight);
        final padding = _calculatePadding(availableWidth, availableHeight);

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
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 顶部图标和标题
                _buildHeader(theme, finalIconColor, iconSize, fontSize),

                SizedBox(height: padding * 0.5),

                // 统计信息
                Expanded(
                  child: _buildStatItems(theme, finalIconColor, fontSize),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 计算图标大小（根据可用空间）
  double _calculateIconSize(double width, double height) {
    // 小组件：32, 中等组件：40, 大组件：48
    if (width < 120 || height < 120) return 32;
    if (width < 200 || height < 200) return 40;
    return 48;
  }

  /// 计算字体大小
  double _calculateFontSize(double width, double height) {
    // 小组件使用较小的字体
    if (width < 120 || height < 120) return 12;
    if (width < 200 || height < 200) return 14;
    return 16;
  }

  /// 计算内边距
  double _calculatePadding(double width, double height) {
    if (width < 120 || height < 120) return 8;
    if (width < 200 || height < 200) return 12;
    return 16;
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
  Widget _buildHeader(ThemeData theme, Color iconColor, double iconSize, double fontSize) {
    final containerSize = iconSize + 16; // 图标 + padding

    return Row(
      children: [
        Container(
          width: containerSize,
          height: containerSize,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            pluginIcon,
            size: iconSize * 0.6, // 图标占容器的60%
            color: iconColor,
          ),
        ),
        SizedBox(width: iconSize * 0.3),
        Expanded(
          child: Text(
            pluginName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
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
  Widget _buildStatItems(ThemeData theme, Color iconColor, double fontSize) {
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
            fontSize: fontSize,
          ),
        ),
      );
    }

    // 根据显示风格选择布局
    return config.displayStyle == PluginWidgetDisplayStyle.oneColumn
      ? _buildOneColumnLayout(selectedItems, theme, iconColor, fontSize)
      : _buildTwoColumnsLayout(selectedItems, theme, iconColor, fontSize);
  }

  /// 一列布局
  Widget _buildOneColumnLayout(
    List<StatItemData> items,
    ThemeData theme,
    Color iconColor,
    double fontSize,
  ) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: items.map((item) => Padding(
          padding: EdgeInsets.symmetric(vertical: fontSize * 0.5),
          child: _StatItem(
            data: item,
            theme: theme,
            defaultColor: iconColor,
            fontSize: fontSize,
          ),
        )).toList(),
      ),
    );
  }

  /// 两列布局
  Widget _buildTwoColumnsLayout(
    List<StatItemData> items,
    ThemeData theme,
    Color iconColor,
    double fontSize,
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
                fontSize: fontSize,
              ),
            ),
            if (secondItem != null) ...[
              Container(
                width: 1,
                height: fontSize * 2,
                color: theme.dividerColor,
              ),
              Expanded(
                child: _StatItem(
                  data: secondItem,
                  theme: theme,
                  defaultColor: iconColor,
                  fontSize: fontSize,
                ),
              ),
            ],
          ],
        ),
      );

      // 添加间距（除了最后一行）
      if (i + 2 < items.length) {
        rows.add(SizedBox(height: fontSize * 0.75));
      }
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: rows,
      ),
    );
  }
}

/// 统计项组件
class _StatItem extends StatelessWidget {
  final StatItemData data;
  final ThemeData theme;
  final Color defaultColor;
  final double fontSize;

  const _StatItem({
    required this.data,
    required this.theme,
    required this.defaultColor,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = data.highlight
      ? (data.color ?? defaultColor)
      : null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            data.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
              fontSize: fontSize * 0.875, // 标签字体稍小
            ),
            textAlign: TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: fontSize * 0.5),
        Expanded(
          flex: 2,
          child: Text(
            data.value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: fontSize * 1.5, // 数值字体较大
              color: displayColor,
            ),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
