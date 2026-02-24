/// 习惯卡片小组件 - 公共组件版本
///
/// 纯 UI 渲染组件，接受 HabitCardData 进行渲染。
/// 根据 HomeWidgetSize 自动调整所有元素的大小。
library;

import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/plugins/habits/home_widgets/widgets/habit_card_widget.dart';

/// 习惯卡片公共小组件
///
/// 显示习惯的打卡记录、统计和计时状态。
/// 支持通过 HabitCardData 进行数据渲染，也可通过 fromProps 工厂方法创建。
class HabitCardWidget extends StatelessWidget {
  /// 习惯卡片数据
  final HabitCardData data;

  /// 卡片点击回调
  final VoidCallback? onTap;

  /// 卡片长按回调
  final VoidCallback? onLongPress;

  /// 小组件尺寸（用于调整所有元素大小）
  final HomeWidgetSize size;

  const HabitCardWidget({
    super.key,
    required this.data,
    this.onTap,
    this.onLongPress,
    this.size = const MediumSize(),
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory HabitCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final habitCardData = props['data'] != null
        ? HabitCardData.fromJson(props['data'] as Map<String, dynamic>)
        : HabitCardData.fromJson(props);

    return HabitCardWidget(
      data: habitCardData,
      onTap: props['onTap'] as VoidCallback?,
      onLongPress: props['onLongPress'] as VoidCallback?,
      size: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white;
    final themeColor = Color(data.themeColor);

    // 根据尺寸获取各个值
    final padding = size.getPadding();
    final iconContainerSize = size.getIconSize() * 1.3; // 约 40-52px
    final iconSize = size.getIconSize() * 0.9; // 约 20-32px
    final titleFontSize = size.getSubtitleFontSize() * 1.1; // 约 14-20px
    final subtitleFontSize = size.getSubtitleFontSize() * 0.8; // 约 10-14px
    final heatmapHeight = iconSize * 1.2; // 约 24-38px
    final dayCellHeight = iconSize; // 约 20-32px
    final dayFontSize = size.getLegendFontSize() * 0.9; // 约 8-12px
    final buttonHeight = size.getIconSize() * 1.8; // 约 32-48px
    final progressHeight = size.getStrokeWidth() * 0.75; // 约 2-3px
    final statsPadding = size.getSmallSpacing() * 1.5; // 约 6-12px
    final badgeMinSize = size.getIconSize() * 0.5; // 约 10-16px
    final badgeFontSize = size.getLegendFontSize(); // 约 9-13px

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(size.getIconSize() * 0.4),
          border: Border.all(
            color:
                isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: size.getIconSize(),
                offset: Offset(0, size.getSmallSpacing()),
              ),
          ],
        ),
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Header
            _buildHeader(
              themeColor,
              iconContainerSize,
              iconSize,
              titleFontSize,
              subtitleFontSize,
              isDark,
            ),
            SizedBox(height: size.getSmallSpacing() * 2),

            // Heatmap
            _buildHeatmap(
              context,
              themeColor,
              heatmapHeight,
              dayCellHeight,
              dayFontSize,
              badgeMinSize,
              badgeFontSize,
              isDark,
            ),

            SizedBox(height: size.getSmallSpacing() * 1.5),

            // Stats
            _buildStats(
              themeColor,
              statsPadding,
              progressHeight,
              isDark,
            ),

            SizedBox(height: size.getSmallSpacing() * 2),

            // Button
            _buildButton(
              themeColor,
              buttonHeight,
              isDark,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建头部区域
  Widget _buildHeader(
    Color themeColor,
    double iconContainerSize,
    double iconSize,
    double titleFontSize,
    double subtitleFontSize,
    bool isDark,
  ) {
    return Row(
      children: [
        Container(
          width: iconContainerSize,
          height: iconContainerSize,
          decoration: BoxDecoration(
            color: themeColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(size.getIconSize() * 0.25),
          ),
          child: Icon(
            _getIcon(),
            color: themeColor,
            size: iconSize,
          ),
        ),
        SizedBox(width: size.getSmallSpacing()),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey[800],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _getSkillTitle(),
                style: TextStyle(
                  fontSize: subtitleFontSize,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建热力图区域
  Widget _buildHeatmap(
    BuildContext context,
    Color themeColor,
    double height,
    double cellHeight,
    double fontSize,
    double badgeMinSize,
    double badgeFontSize,
    bool isDark,
  ) {
    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Row(
            children: data.last7DaysStatus.asMap().entries.map((entry) {
              final index = entry.key;
              final isActive = entry.value;
              final date = DateTime.now().subtract(
                Duration(days: 6 - index),
              );

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  height: cellHeight,
                  decoration: BoxDecoration(
                    color: isActive
                        ? themeColor
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.grey[200]),
                    borderRadius: BorderRadius.circular(size.getStrokeWidth() * 0.8),
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: isActive
                            ? Colors.white
                            : (isDark
                                ? Colors.white30
                                : Colors.grey[400]),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (data.todayCount > 0)
            Positioned(
              right: -size.getSmallSpacing(),
              top: -size.getSmallSpacing() * 1.5,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: size.getStrokeWidth(),
                  vertical: size.getStrokeWidth() * 0.5,
                ),
                decoration: BoxDecoration(
                  color: themeColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: size.getStrokeWidth() * 0.5,
                  ),
                ),
                constraints: BoxConstraints(
                  minWidth: badgeMinSize,
                  minHeight: badgeMinSize,
                ),
                child: Center(
                  child: Text(
                    '${data.todayCount}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: badgeFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建统计区域
  Widget _buildStats(
    Color themeColor,
    double padding,
    double progressHeight,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: size.getStrokeWidth() * 4,
        vertical: size.getStrokeWidth() * 3,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(size.getStrokeWidth() * 1.5),
      ),
      child: Column(
        children: [
          // 文本
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${_formatTotalDuration(data.totalDurationMinutes)}(${data.completionCount})',
                style: TextStyle(
                  fontSize: size.getLegendFontSize(),
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.grey[700],
                ),
              ),
              Text(
                ' / ${data.durationMinutes}m',
                style: TextStyle(
                  fontSize: size.getLegendFontSize(),
                  color: isDark ? Colors.white38 : Colors.grey[500],
                ),
              ),
              if (data.currentTotalDurationMinutes > 0) ...[
                Text(
                  ' | ',
                  style: TextStyle(
                    fontSize: size.getLegendFontSize(),
                    color: isDark ? Colors.white24 : Colors.grey[400],
                  ),
                ),
                Text(
                  '总${_formatTotalDuration(data.currentTotalDurationMinutes)}',
                  style: TextStyle(
                    fontSize: size.getLegendFontSize() * 0.9,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white54 : Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: size.getStrokeWidth() * 2),
          // 进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(size.getStrokeWidth() * 0.5),
            child: LinearProgressIndicator(
              value: data.durationMinutes > 0
                  ? (data.totalDurationMinutes / data.durationMinutes).clamp(0.0, 1.0)
                  : 0.0,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(themeColor),
              minHeight: progressHeight,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建按钮区域
  Widget _buildButton(
    Color themeColor,
    double height,
    bool isDark,
  ) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Material(
        color: data.isTiming
            ? themeColor
            : themeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(size.getIconSize() * 0.3),
        child: InkWell(
          onTap: null, // Command widget 不处理交互
          borderRadius: BorderRadius.circular(size.getIconSize() * 0.3),
          child: Center(
            child: data.isTiming
                ? Text(
                    data.timerText,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: size.getSubtitleFontSize(),
                    ),
                  )
                : Icon(
                    Icons.play_arrow,
                    color: themeColor,
                    size: size.getIconSize(),
                  ),
          ),
        ),
      ),
    );
  }

  /// 获取图标
  IconData _getIcon() {
    final iconCode = data.icon;
    if (iconCode != null) {
      try {
        return IconData(int.parse(iconCode), fontFamily: 'MaterialIcons');
      } catch (e) {
        return Icons.auto_awesome;
      }
    }
    return Icons.auto_awesome;
  }

  /// 获取技能标题
  String _getSkillTitle() => data.skillTitle ?? data.group ?? 'Uncategorized';

  /// 格式化总时长
  String _formatTotalDuration(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    }
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m}m';
  }
}
