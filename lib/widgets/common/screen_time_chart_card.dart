import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 屏幕时间数据分段
class ScreenTimeSegment {
  final String category;
  final double percentage;

  const ScreenTimeSegment({required this.category, required this.percentage});

  /// 从 JSON 创建
  factory ScreenTimeSegment.fromJson(Map<String, dynamic> json) {
    return ScreenTimeSegment(
      category: json['category'] as String? ?? 'gray',
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {'category': category, 'percentage': percentage};
  }
}

/// 屏幕时间数据点
class ScreenTimeDataPoint {
  final String timeLabel;
  final List<ScreenTimeSegment> segments;
  final double heightPercentage;

  const ScreenTimeDataPoint({
    required this.timeLabel,
    required this.segments,
    required this.heightPercentage,
  });

  /// 从 JSON 创建
  factory ScreenTimeDataPoint.fromJson(Map<String, dynamic> json) {
    return ScreenTimeDataPoint(
      timeLabel: json['timeLabel'] as String? ?? '',
      segments:
          (json['segments'] as List<dynamic>?)
              ?.map(
                (e) => ScreenTimeSegment.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      heightPercentage: (json['heightPercentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'timeLabel': timeLabel,
      'segments': segments.map((e) => e.toJson()).toList(),
      'heightPercentage': heightPercentage,
    };
  }
}

/// 屏幕时间统计图表小组件
class ScreenTimeChartCardWidget extends StatefulWidget {
  /// 头像 URL（可选）
  final String? avatarUrl;

  /// 总小时数
  final int totalHours;

  /// 总分钟数
  final int totalMinutes;

  /// 数据点列表
  final List<ScreenTimeDataPoint> dataPoints;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const ScreenTimeChartCardWidget({
    super.key,
    this.avatarUrl,
    required this.totalHours,
    required this.totalMinutes,
    required this.dataPoints,
    this.size = const MediumSize(),
  });

  @override
  State<ScreenTimeChartCardWidget> createState() =>
      _ScreenTimeChartCardWidgetState();
}

class _ScreenTimeChartCardWidgetState extends State<ScreenTimeChartCardWidget>
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
    // 确保动画立即开始播放
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void didUpdateWidget(ScreenTimeChartCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当数据变化时重新播放动画
    if (oldWidget.dataPoints != widget.dataPoints ||
        oldWidget.totalHours != widget.totalHours ||
        oldWidget.totalMinutes != widget.totalMinutes) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final padding = widget.size.getPadding();
    final titleSpacing = widget.size.getTitleSpacing();

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: child,
          ),
        );
      },
      child: Container(
        constraints: widget.size.getHeightConstraints(),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 40,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 顶部区域：头像 + 时间
              _buildHeader(isDark),
              SizedBox(height: titleSpacing),
              // 中间区域：图表
              Expanded(child: _buildChart(isDark)),
              SizedBox(height: titleSpacing * 0.6),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建头部区域
  Widget _buildHeader(bool isDark) {
    final iconSize = widget.size.getIconSize();
    final containerSize = iconSize * widget.size.iconContainerScale;
    final smallSpacing = widget.size.getSmallSpacing();
    final valueFontSize = widget.size.getLargeFontSize() * 0.85;

    return Row(
      children: [
        // 头像
        if (widget.avatarUrl != null)
          Container(
            width: containerSize,
            height: containerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: Image.network(
                widget.avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color:
                        isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade300,
                    child: Icon(
                      Icons.person,
                      size: iconSize * 0.8,
                      color:
                          isDark ? Colors.grey.shade600 : Colors.grey.shade500,
                    ),
                  );
                },
              ),
            ),
          ),
        SizedBox(width: smallSpacing * 4),
        // 时间显示
        Text(
          '${widget.totalHours}h ${widget.totalMinutes}m',
          style: TextStyle(
            fontSize: valueFontSize * 0.7,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.5,
            color: isDark ? Colors.white : Colors.black,
            height: 1.0,
          ),
        ),
      ],
    );
  }

  /// 构建图表区域
  Widget _buildChart(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final xLabelHeight = widget.size.getLegendFontSize() * 1.5;

        return SizedBox.expand(
          child: Stack(
            children: [
              // 背景网格线（限制在柱状图区域内）
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: xLabelHeight,
                child: _buildGridLines(isDark),
              ),
              // 垂直虚线
              _buildVerticalDashedLines(isDark, constraints.maxWidth),
              // 柱状图
              _buildBars(isDark, constraints.maxHeight),
              // X轴标签
              _buildXAxisLabels(isDark, constraints.maxWidth),
            ],
          ),
        );
      },
    );
  }

  /// 构建背景网格线
  Widget _buildGridLines(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildGridLine(isDark, '60m', Alignment.topRight),
        _buildGridLine(isDark, '30m', Alignment.topRight),
        _buildGridLine(isDark, '0m', Alignment.topRight),
      ],
    );
  }

  Widget _buildGridLine(bool isDark, String label, Alignment alignment) {
    final legendFontSize = widget.size.getLegendFontSize();
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return Stack(
      children: [
        Container(
          height: 1,
          color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA),
        ),
        Align(
          alignment: alignment,
          child: Container(
            padding: EdgeInsets.only(left: widget.size.getSmallSpacing() * 2),
            color: cardColor,
            child: Text(
              label,
              style: TextStyle(
                fontSize: legendFontSize,
                fontWeight: FontWeight.w500,
                color:
                    isDark ? const Color(0xFF636366) : const Color(0xFF8E8E93),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建垂直虚线
  Widget _buildVerticalDashedLines(bool isDark, double width) {
    return Positioned.fill(
      child: Row(
        children: [
          _buildVerticalDashedLine(isDark),
          Expanded(child: Container()),
          _buildVerticalDashedLine(isDark),
        ],
      ),
    );
  }

  Widget _buildVerticalDashedLine(bool isDark) {
    return Container(
      width: 1,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFD1D1D6),
            width: 1,
          ),
        ),
      ),
    );
  }

  /// 构建柱状图
  Widget _buildBars(bool isDark, double maxHeight) {
    final barWidth = widget.size.getBarWidth();
    final smallSpacing = widget.size.getSmallSpacing();
    final xLabelHeight = widget.size.getLegendFontSize() * 1.5;
    // Y 轴标签宽度（"60m" 等文字 + padding）
    final yAxisLabelWidth = widget.size.getLegendFontSize() * 3.5 + smallSpacing * 2;

    return Positioned(
      left: smallSpacing * 2,
      right: yAxisLabelWidth,
      bottom: xLabelHeight,
      height: maxHeight - xLabelHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(widget.dataPoints.length, (index) {
          final dataPoint = widget.dataPoints[index];
          return _Bar(
            segments: dataPoint.segments,
            heightPercentage: dataPoint.heightPercentage,
            maxHeight: maxHeight - xLabelHeight,
            animation: _animation,
            index: index,
            size: widget.size,
            barWidth: barWidth,
          );
        }),
      ),
    );
  }

  /// 构建X轴标签
  Widget _buildXAxisLabels(bool isDark, double width) {
    final legendFontSize = widget.size.getLegendFontSize();
    final smallSpacing = widget.size.getSmallSpacing();
    final xLabelHeight = legendFontSize * 1.5;
    // Y 轴标签宽度（与柱状图保持一致）
    final yAxisLabelWidth = legendFontSize * 3.5 + smallSpacing * 2;

    return Positioned(
      left: smallSpacing * 2,
      right: yAxisLabelWidth,
      bottom: 0,
      height: xLabelHeight,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              '6 AM',
              style: TextStyle(
                fontSize: legendFontSize,
                fontWeight: FontWeight.w500,
                color:
                    isDark
                        ? const Color(0xFF636366)
                        : const Color(0xFF8E8E93),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Text(
              '12 PM',
              style: TextStyle(
                fontSize: legendFontSize,
                fontWeight: FontWeight.w500,
                color:
                    isDark
                        ? const Color(0xFF636366)
                        : const Color(0xFF8E8E93),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              '6 PM',
              style: TextStyle(
                fontSize: legendFontSize,
                fontWeight: FontWeight.w500,
                color:
                    isDark
                        ? const Color(0xFF636366)
                        : const Color(0xFF8E8E93),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 单个柱状图条
class _Bar extends StatelessWidget {
  final List<ScreenTimeSegment> segments;
  final double heightPercentage;
  final double maxHeight;
  final Animation<double> animation;
  final int index;
  final HomeWidgetSize size;
  final double barWidth;

  const _Bar({
    required this.segments,
    required this.heightPercentage,
    required this.maxHeight,
    required this.animation,
    required this.index,
    required this.size,
    required this.barWidth,
  });

  @override
  Widget build(BuildContext context) {
    // 计算每个柱子的动画区间，确保 start < end 且都在 [0, 1] 范围内
    final totalBars = 7; // 估计的最大柱子数量
    final animationDuration = 0.6; // 动画持续时间比例
    final startDelay = index / totalBars; // 每个柱子的起始延迟
    final start = startDelay.clamp(0.0, 0.9);
    final end = (startDelay + animationDuration / totalBars).clamp(0.1, 1.0);

    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        start,
        end,
        curve: Curves.easeOutCubic,
      ),
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderRadius = size.getSmallSpacing() * 0.5;

    return AnimatedBuilder(
      animation: itemAnimation,
      builder: (context, child) {
        final barHeight = maxHeight * heightPercentage * itemAnimation.value;
        return Container(
          width: barWidth,
          height: barHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          clipBehavior: Clip.antiAlias,
          child: barHeight > 0
              ? Column(
                  verticalDirection: VerticalDirection.up,
                  children: segments.map((segment) {
                    final color = _getSegmentColor(segment.category, isDark);
                    final height = barHeight * segment.percentage;
                    return Container(
                      height: height,
                      width: double.infinity,
                      color: color,
                    );
                  }).toList(),
                )
              : null,
        );
      },
    );
  }

  Color _getSegmentColor(String category, bool isDark) {
    switch (category) {
      case 'blue':
        return const Color(0xFF007AFF);
      case 'teal':
        return const Color(0xFF5AC8FA);
      case 'orange':
        return const Color(0xFFFF9500);
      case 'gray':
        return isDark ? const Color(0xFF636366) : const Color(0xFFC7C7CC);
      default:
        return Colors.grey;
    }
  }
}
