import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 屏幕时间数据分段
class ScreenTimeSegment {
  final String category;
  final double percentage;

  const ScreenTimeSegment({
    required this.category,
    required this.percentage,
  });

  /// 从 JSON 创建
  factory ScreenTimeSegment.fromJson(Map<String, dynamic> json) {
    return ScreenTimeSegment(
      category: json['category'] as String? ?? 'gray',
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'percentage': percentage,
    };
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
      segments: (json['segments'] as List<dynamic>?)
              ?.map((e) => ScreenTimeSegment.fromJson(e as Map<String, dynamic>))
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

  const ScreenTimeChartCardWidget({
    super.key,
    this.avatarUrl,
    required this.totalHours,
    required this.totalMinutes,
    required this.dataPoints,
  });

  /// 从 props 创建实例
  factory ScreenTimeChartCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return ScreenTimeChartCardWidget(
      avatarUrl: props['avatarUrl'] as String?,
      totalHours: props['totalHours'] as int? ?? 0,
      totalMinutes: props['totalMinutes'] as int? ?? 0,
      dataPoints: (props['dataPoints'] as List<dynamic>?)
              ?.map((e) => ScreenTimeDataPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

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
        width: 320,
        height: 320,
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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 顶部区域：头像 + 时间
              _buildHeader(isDark),
              const SizedBox(height: 16),
              // 中间区域：图表
              Expanded(
                child: _buildChart(isDark),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建头部区域
  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        // 头像
        if (widget.avatarUrl != null)
          Container(
            width: 36,
            height: 36,
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
                    color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade300,
                    child: Icon(
                      Icons.person,
                      color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
                    ),
                  );
                },
              ),
            ),
          ),
        const SizedBox(width: 12),
        // 时间显示
        Text(
          '${widget.totalHours}h ${widget.totalMinutes}m',
          style: TextStyle(
            fontSize: 40,
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
        return Stack(
          children: [
            // 背景网格线
            _buildGridLines(isDark),
            // 垂直虚线
            _buildVerticalDashedLines(isDark, constraints.maxWidth),
            // 柱状图
            _buildBars(isDark, constraints.maxHeight),
            // X轴标签
            _buildXAxisLabels(isDark, constraints.maxWidth),
          ],
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
    return Stack(
      children: [
        Container(
          height: 1,
          color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA),
        ),
        Align(
          alignment: alignment,
          child: Container(
            padding: const EdgeInsets.only(left: 4),
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF636366) : const Color(0xFF8E8E93),
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
    return Positioned(
      bottom: 0,
      left: 8,
      right: 32,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(widget.dataPoints.length, (index) {
          final dataPoint = widget.dataPoints[index];
          return _Bar(
            segments: dataPoint.segments,
            heightPercentage: dataPoint.heightPercentage,
            maxHeight: maxHeight,
            animation: _animation,
            index: index,
          );
        }),
      ),
    );
  }

  /// 构建X轴标签
  Widget _buildXAxisLabels(bool isDark, double width) {
    return Positioned(
      bottom: -24,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 12,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              child: Transform.translate(
                offset: const Offset(4, 0),
                child: Text(
                  '6 AM',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF636366) : const Color(0xFF8E8E93),
                  ),
                ),
              ),
            ),
            Positioned(
              left: width * 0.55,
              child: Transform.translate(
                offset: const Offset(4, 0),
                child: Text(
                  '12 PM',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF636366) : const Color(0xFF8E8E93),
                  ),
                ),
              ),
            ),
          ],
        ),
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

  const _Bar({
    required this.segments,
    required this.heightPercentage,
    required this.maxHeight,
    required this.animation,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        index * 0.12,
        0.6 + index * 0.12,
        curve: Curves.easeOutCubic,
      ),
    );

    final barHeight = maxHeight * heightPercentage * itemAnimation.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 14,
      height: barHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
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
      ),
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
