import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 图表图标数据模型
class ChartIconEntry {
  final String emoji;
  final String label;
  final int value;

  const ChartIconEntry({
    required this.emoji,
    required this.label,
    required this.value,
  });

  /// 从 JSON 创建
  factory ChartIconEntry.fromJson(Map<String, dynamic> json) {
    return ChartIconEntry(
      emoji: json['emoji'] as String? ?? '',
      label: json['label'] as String? ?? '',
      value: json['value'] as int? ?? 0,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {'emoji': emoji, 'label': label, 'value': value};
  }
}

/// 心情类型枚举
enum ChartIconType { emoji, color }

/// 心情类型扩展
extension ChartIconTypeExtension on ChartIconType {
  String toJson() {
    switch (this) {
      case ChartIconType.emoji:
        return 'emoji';
      case ChartIconType.color:
        return 'color';
    }
  }

  static ChartIconType fromJson(String value) {
    switch (value) {
      case 'emoji':
        return ChartIconType.emoji;
      case 'color':
        return ChartIconType.color;
      default:
        return ChartIconType.emoji;
    }
  }
}

/// 图标展示图表卡片小组件
class ChartIconDisplayCard extends StatefulWidget {
  /// 标题
  final String title;

  /// 副标题
  final String subtitle;

  /// 心情数据列表
  final List<ChartIconEntry> moods;

  /// 显示类型（emoji 或 color）
  final ChartIconType displayType;

  /// 主题颜色
  final Color primaryColor;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const ChartIconDisplayCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.moods,
    this.displayType = ChartIconType.emoji,
    this.primaryColor = const Color(0xFF6366F1),
    this.inline = false,
    this.size = const MediumSize(),
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory ChartIconDisplayCard.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final moodsList =
        (props['moods'] as List<dynamic>?)
            ?.map((e) => ChartIconEntry.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return ChartIconDisplayCard(
      title: props['title'] as String? ?? '',
      subtitle: props['subtitle'] as String? ?? '',
      moods: moodsList,
      displayType:
          props['displayType'] != null
              ? ChartIconTypeExtension.fromJson(props['displayType'] as String)
              : ChartIconType.emoji,
      primaryColor:
          props.containsKey('primaryColor')
              ? Color(props['primaryColor'] as int)
              : const Color(0xFF6366F1),
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<ChartIconDisplayCard> createState() => _ChartIconDisplayCardState();
}

class _ChartIconDisplayCardState extends State<ChartIconDisplayCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: widget.inline ? double.maxFinite : 320,
              constraints: BoxConstraints(
                minWidth: 280,
                minHeight: widget.size.getHeightConstraints().minHeight,
              ),
              decoration: BoxDecoration(
                color: isDark ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 40,
                      offset: const Offset(0, 12),
                    ),
                ],
                border:
                    isDark
                        ? Border.all(color: Colors.white.withOpacity(0.1))
                        : null,
              ),
              padding: widget.size.getPadding(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题和副标题
                  _buildHeader(isDark),
                  // 心情图表
                  Expanded(child: _buildMoodChart(isDark)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建标题区域
  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.title,
          style: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
            fontSize: widget.size.getSubtitleFontSize(),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          widget.subtitle,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.grey.shade900,
            fontSize: widget.size.getTitleFontSize(),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// 构建心情图表
  Widget _buildMoodChart(bool isDark) {
    // 计算最大值用于缩放
    int maxValue = 0;
    for (var mood in widget.moods) {
      if (mood.value > maxValue) maxValue = mood.value;
    }

    // 根据尺寸计算柱状图高度和宽度
    final chartHeight = widget.size.getHeightConstraints().minHeight * 0.4;
    final axisFontSize = widget.size.getLegendFontSize();
    final axisLabelFontSize = widget.size.getLegendFontSize() * 0.9;

    // 根据 size 计算柱子宽度和间距
    double barWidth;
    double barSpacing;
    if (widget.size is SmallSize) {
      barWidth = 24;
      barSpacing = 8;
    } else if (widget.size is MediumSize) {
      barWidth = 36;
      barSpacing = 12;
    } else if (widget.size is LargeSize) {
      barWidth = 48;
      barSpacing = 16;
    } else if (widget.size is WideSize) {
      barWidth = 40;
      barSpacing = 14;
    } else {
      // Wide2Size
      barWidth = 48;
      barSpacing = 18;
    }

    // 计算所有柱子的总宽度（包括间距）
    final totalBarsWidth =
        (widget.moods.length * barWidth) +
        ((widget.moods.length - 1) * barSpacing);

    // 确保最小宽度至少为 barWidth（避免空数据或单个数据时的负宽度）
    final safeTotalWidth = totalBarsWidth.clamp(barWidth, double.maxFinite);

    return Scrollbar(
      thumbVisibility: true,
      thickness: 4,
      radius: const Radius.circular(2),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: widget.size.getItemSpacing(),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Y轴刻度
            SizedBox(
              width: safeTotalWidth + widget.size.getItemSpacing() / 2,
              child: Row(
                children: [
                  ...List.generate(5, (index) {
                    final value = maxValue * (4 - index) ~/ 4;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: widget.size.getItemSpacing() / 2,
                        ),
                        child: Text(
                          value.toString(),
                          style: TextStyle(
                            color: isDark
                                ? Colors.grey.shade600
                                : Colors.grey.shade400,
                            fontSize: axisFontSize,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }),
                  SizedBox(width: widget.size.getItemSpacing() / 2),
                ],
              ),
            ),
            // 柱状图
            SizedBox(
              height: chartHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _buildMoodBars(
                  maxValue,
                  isDark,
                  barWidth,
                  barSpacing,
                  chartHeight,
                ),
              ),
            ),
            // X轴标签
            SizedBox(height: widget.size.getItemSpacing()),
            SizedBox(
              height: axisLabelFontSize * 1.5,
              child: Row(
                children: _buildAxisLabels(
                  axisLabelFontSize,
                  barWidth,
                  barSpacing,
                  isDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建柱子列表
  List<Widget> _buildMoodBars(
    int maxValue,
    bool isDark,
    double barWidth,
    double barSpacing,
    double chartHeight,
  ) {
    return List.generate(widget.moods.length, (index) {
      final mood = widget.moods[index];

      // 计算动画区间，确保 end 不超过 1.0
      final start = (index * 0.1).clamp(0.0, 0.9);
      final end = (0.5 + index * 0.1).clamp(0.1, 1.0);

      final barAnimation = CurvedAnimation(
        parent: _animation,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );

      return Padding(
        padding: EdgeInsets.only(
          right: index < widget.moods.length - 1 ? barSpacing : 0,
        ),
        child: SizedBox(
          width: barWidth,
          child: _MoodBar(
            mood: mood,
            maxValue: maxValue,
            animation: barAnimation,
            displayType: widget.displayType,
            primaryColor: widget.primaryColor,
            isDark: isDark,
            size: widget.size,
            maxHeight: chartHeight,
          ),
        ),
      );
    });
  }

  /// 构建X轴标签列表
  List<Widget> _buildAxisLabels(
    double fontSize,
    double barWidth,
    double barSpacing,
    bool isDark,
  ) {
    return List.generate(widget.moods.length, (index) {
      final mood = widget.moods[index];

      return Padding(
        padding: EdgeInsets.only(
          right: index < widget.moods.length - 1 ? barSpacing : 0,
        ),
        child: SizedBox(
          width: barWidth,
          child: Text(
            mood.label,
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontSize: fontSize,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    });
  }
}

/// 单个心情柱
class _MoodBar extends StatelessWidget {
  final ChartIconEntry mood;
  final int maxValue;
  final Animation<double> animation;
  final ChartIconType displayType;
  final Color primaryColor;
  final bool isDark;
  final HomeWidgetSize size;
  final double maxHeight;

  const _MoodBar({
    required this.mood,
    required this.maxValue,
    required this.animation,
    required this.displayType,
    required this.primaryColor,
    required this.isDark,
    required this.size,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final baseEmojiSize = size.getIconSize();
    final borderRadius = baseEmojiSize * 0.4;
    final barHeight =
        maxValue > 0 ? (mood.value / maxValue) * (maxHeight * 0.9) : 0.0;

    // 如果柱子高度小于 emoji 基础尺寸，则缩小 emoji
    final actualEmojiSize =
        barHeight < baseEmojiSize ? barHeight * 0.8 : baseEmojiSize;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Container(
              height: barHeight * animation.value,
              decoration: BoxDecoration(
                color:
                    displayType == ChartIconType.color
                        ? primaryColor.withOpacity(0.7)
                        : isDark
                        ? Colors.grey.shade700
                        : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child:
                  displayType == ChartIconType.emoji
                      ? Center(
                        child: Text(
                          mood.emoji,
                          style: TextStyle(fontSize: actualEmojiSize),
                        ),
                      )
                      : null,
            );
          },
        ),
      ],
    );
  }
}
