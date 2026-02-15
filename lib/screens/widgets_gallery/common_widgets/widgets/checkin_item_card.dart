import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 签到项目卡片小组件
///
/// 显示签到项目的名称、图标、今日打卡状态和热力图
class CheckinItemCardWidget extends StatelessWidget {
  final Map<String, dynamic> props;
  final HomeWidgetSize size;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  const CheckinItemCardWidget({
    super.key,
    required this.props,
    required this.size,
    this.inline = false,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory CheckinItemCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return CheckinItemCardWidget(
      props: props,
      size: size,
      inline: props['inline'] as bool? ?? false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 从 props 获取数据
    final name = props['title'] as String? ??
                props['name'] as String? ??
                '签到项目';
    final group = props['subtitle'] as String? ??
                props['group'] as String?;
    final colorValue = props['color'] as int? ?? 0xFF007AFF;
    final iconCode = props['iconCodePoint'] as int? ??
                    props['icon'] as int? ??
                    Icons.checklist.codePoint;
    final isCheckedToday = props['isCheckedToday'] as bool? ?? false;

    final itemColor = Color(colorValue);
    // 获取 custom 尺寸的实际宽高（从 props 中获取）
    final actualWidth = props['customWidth'] as int?;
    final actualHeight = props['customHeight'] as int?;
    final showHeatmap = size.isAtLeast(
      const MediumSize(),
      actualWidth: actualWidth,
      actualHeight: actualHeight,
    );

    return Container(
      padding: size.getPadding(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 习惯图标和标题
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: size.getIconSize() * 1.6,
                height: size.getIconSize() * 1.6,
                decoration: BoxDecoration(
                  color: itemColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(size.getIconSize() * 0.3),
                ),
                child: Icon(
                  IconData(iconCode, fontFamily: 'MaterialIcons'),
                  color: itemColor,
                  size: size.getIconSize(),
                ),
              ),
              SizedBox(width: size.getItemSpacing() * 1.5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (group != null)
                      Text(
                        group,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // 右上角打卡状态
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: size.getSmallSpacing() * 2,
                  vertical: size.getSmallSpacing(),
                ),
                decoration: BoxDecoration(
                  color: isCheckedToday
                      ? Colors.green.withOpacity(0.15)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(size.getSmallSpacing() * 1.5),
                  border: Border.all(
                    color: isCheckedToday
                        ? Colors.green.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCheckedToday ? Icons.check_circle : Icons.circle_outlined,
                      size: size.getLegendFontSize(),
                      color: isCheckedToday ? Colors.green : Colors.grey,
                    ),
                    SizedBox(width: size.getSmallSpacing()),
                    Text(
                      isCheckedToday ? '已打卡' : '未打卡',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isCheckedToday ? Colors.green : Colors.grey,
                        fontSize: size.getLegendFontSize() - 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // 热力图（根据卡片大小显示不同范围）
          if (showHeatmap) ...[
            SizedBox(height: size.getItemSpacing() * 1.5),
            _buildHeatmapGrid(itemColor),
          ],
        ],
      ),
    );
  }

  /// 构建热力图网格
  Widget _buildHeatmapGrid(Color itemColor) {
    // 从 props 获取热力图数据
    final weekData = props['weekData'] as List<dynamic>?;
    final daysData = props['daysData'] as List<dynamic>?;
    // 获取 custom 尺寸的实际宽高
    final actualWidth = props['customWidth'] as int?;
    final actualHeight = props['customHeight'] as int?;

    // 根据尺寸决定使用哪个数据
    // large(2,2) 或更高尺寸：优先显示月数据
    if (size.isAtLeast(
          const LargeSize(),
          actualWidth: actualWidth,
          actualHeight: actualHeight,
        ) &&
        daysData != null &&
        daysData.isNotEmpty) {
      return _buildMonthHeatmap(daysData.cast<Map<String, dynamic>>(), itemColor);
    }
    // medium(2,1) 或更高尺寸：显示周数据
    else if (size.isAtLeast(
          const MediumSize(),
          actualWidth: actualWidth,
          actualHeight: actualHeight,
        ) &&
        weekData != null &&
        weekData.isNotEmpty) {
      return _buildWeekHeatmap(weekData.cast<Map<String, dynamic>>(), itemColor);
    }

    return const SizedBox.shrink();
  }

  /// 构建周热力图
  Widget _buildWeekHeatmap(List<Map<String, dynamic>> weekData, Color itemColor) {
    const crossAxisCount = 7;
    const spacing = 4.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final totalWidthSpacing = (crossAxisCount - 1) * spacing;
        final cellSize = (maxWidth - totalWidthSpacing) / crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: weekData.map((data) {
            final isChecked = data['isChecked'] as bool? ?? false;
            return SizedBox(
              width: cellSize,
              height: cellSize,
              child: Container(
                decoration: BoxDecoration(
                  color: isChecked
                      ? itemColor.withOpacity(0.6)
                      : itemColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(cellSize / 3),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// 构建月热力图
  Widget _buildMonthHeatmap(List<Map<String, dynamic>> daysData, Color itemColor) {
    const crossAxisCount = 7;
    const spacing = 3.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final totalWidthSpacing = (crossAxisCount - 1) * spacing;
        final cellSize = (maxWidth - totalWidthSpacing) / crossAxisCount;

        final totalItems = daysData.length;
        final rows = (totalItems / crossAxisCount).ceil();

        final totalHeightSpacing = (rows - 1) * spacing;
        final totalHeight = rows * cellSize + totalHeightSpacing;

        return SizedBox(
          height: totalHeight,
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: daysData.map((data) {
              final day = data['day'] as int? ?? 0;
              final isChecked = data['isChecked'] as bool? ?? false;
              final isToday = data['isToday'] as bool? ?? false;

              // day == 0 表示占位符
              if (day == 0) {
                return SizedBox(width: cellSize, height: cellSize);
              }

              return SizedBox(
                width: cellSize,
                height: cellSize,
                child: Container(
                  decoration: BoxDecoration(
                    color: isChecked
                        ? itemColor.withOpacity(0.6)
                        : itemColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(cellSize / 3),
                    border: isToday
                        ? Border.all(color: itemColor, width: 1.5)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: cellSize * 0.35,
                        color: Colors.black54,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
