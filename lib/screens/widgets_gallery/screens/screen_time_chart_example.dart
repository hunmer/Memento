import 'package:flutter/material.dart';

/// 屏幕时间统计图表示例
class ScreenTimeChartExample extends StatelessWidget {
  const ScreenTimeChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('屏幕时间统计图表')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: ScreenTimeChartWidget(
            avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCXQvcX8rQqhqCmwdBavY1gogXgYogija-OQqrGPWMkNVRdTOXp3y09ywNdXnQiGCc-P4vDokR0EZuET3x_sFa8qkqVhUpYHrWbT5jEY-aUWA34HMs4jtlKdSs0s6TB5--o6B_1AUgdLlDjW3KWwos7Uq1FMEoipxOcxwEdd-V7Wsw78Oeu4kFEXKYwWqXUDSvXMHj8JjfX43Aj-t5Y90q6IzW8MRV1XPJ0euk9I5-2nURrj6HlqacrDBWNexqUb4DBJPJPVFeGDw',
            totalHours: 2,
            totalMinutes: 43,
            dataPoints: [
              ScreenTimeDataPoint(
                timeLabel: '6 AM',
                segments: [
                  ScreenTimeSegment(category: 'blue', percentage: 0.85),
                  ScreenTimeSegment(category: 'teal', percentage: 0.15),
                ],
                heightPercentage: 0.35,
              ),
              ScreenTimeDataPoint(
                timeLabel: '',
                segments: [
                  ScreenTimeSegment(category: 'blue', percentage: 0.60),
                  ScreenTimeSegment(category: 'teal', percentage: 0.10),
                  ScreenTimeSegment(category: 'orange', percentage: 0.05),
                  ScreenTimeSegment(category: 'gray', percentage: 0.25),
                ],
                heightPercentage: 0.45,
              ),
              ScreenTimeDataPoint(
                timeLabel: '12 PM',
                segments: [
                  ScreenTimeSegment(category: 'blue', percentage: 0.40),
                  ScreenTimeSegment(category: 'teal', percentage: 0.20),
                  ScreenTimeSegment(category: 'orange', percentage: 0.15),
                  ScreenTimeSegment(category: 'gray', percentage: 0.25),
                ],
                heightPercentage: 0.80,
              ),
              ScreenTimeDataPoint(
                timeLabel: '',
                segments: [
                  ScreenTimeSegment(category: 'blue', percentage: 0.30),
                  ScreenTimeSegment(category: 'teal', percentage: 0.25),
                  ScreenTimeSegment(category: 'orange', percentage: 0.20),
                  ScreenTimeSegment(category: 'gray', percentage: 0.25),
                ],
                heightPercentage: 0.70,
              ),
              ScreenTimeDataPoint(
                timeLabel: '',
                segments: [
                  ScreenTimeSegment(category: 'blue', percentage: 0.50),
                  ScreenTimeSegment(category: 'teal', percentage: 0.20),
                  ScreenTimeSegment(category: 'orange', percentage: 0.15),
                  ScreenTimeSegment(category: 'gray', percentage: 0.15),
                ],
                heightPercentage: 0.30,
              ),
            ],
          ),
        ),
      ),
    );
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
}

/// 屏幕时间分段
class ScreenTimeSegment {
  final String category;
  final double percentage;

  const ScreenTimeSegment({
    required this.category,
    required this.percentage,
  });
}

/// 屏幕时间统计图表小组件
class ScreenTimeChartWidget extends StatefulWidget {
  final String? avatarUrl;
  final int totalHours;
  final int totalMinutes;
  final List<ScreenTimeDataPoint> dataPoints;

  const ScreenTimeChartWidget({
    super.key,
    this.avatarUrl,
    required this.totalHours,
    required this.totalMinutes,
    required this.dataPoints,
  });

  @override
  State<ScreenTimeChartWidget> createState() => _ScreenTimeChartWidgetState();
}

class _ScreenTimeChartWidgetState extends State<ScreenTimeChartWidget>
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
