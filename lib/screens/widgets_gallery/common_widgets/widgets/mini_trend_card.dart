import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 迷你趋势卡片小组件
///
/// 显示标题、图标、当前数值、单位、副标题、星期标签和趋势折线图
class MiniTrendCardWidget extends StatefulWidget {
  /// 标题
  final String title;

  /// 图标
  final IconData icon;

  /// 当前数值
  final int currentValue;

  /// 单位
  final String unit;

  /// 副标题
  final String subtitle;

  /// 星期标签（7个字符）
  final List<String> weekDays;

  /// 趋势数据（0-100之间）
  final List<double> trendData;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const MiniTrendCardWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.currentValue,
    required this.unit,
    required this.subtitle,
    required this.weekDays,
    required this.trendData,
    this.inline = false,
    this.size = const MediumSize(),
  });

  /// 从 props 创建实例
  factory MiniTrendCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return MiniTrendCardWidget(
      title: props['title'] as String? ?? '',
      icon: _getIcon(props['icon'] as String? ?? 'monitor_heart'),
      currentValue: (props['currentValue'] as num?)?.toInt() ?? 0,
      unit: props['unit'] as String? ?? '',
      subtitle: props['subtitle'] as String? ?? '',
      weekDays: (props['weekDays'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
      trendData: (props['trendData'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  static IconData _getIcon(String iconName) {
    return {
      'monitor_heart': Icons.monitor_heart,
      'favorite': Icons.favorite,
      'fitness_center': Icons.fitness_center,
      'speed': Icons.speed,
      'timeline': Icons.timeline,
    }[iconName] ?? Icons.monitor_heart;
  }

  @override
  State<MiniTrendCardWidget> createState() => _MiniTrendCardWidgetState();
}

class _MiniTrendCardWidgetState extends State<MiniTrendCardWidget>
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
    final backgroundColor = isDark ? const Color(0xFF27272A) : Colors.white;
    final textColor = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final mutedColor = const Color(0xFF9CA3AF);
    final borderColor = isDark ? const Color(0xFF3F3F46) : const Color(0xFFE5E7EB);

    final primaryColor = Theme.of(context).colorScheme.error;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: widget.inline ? double.maxFinite : 380,
              padding: widget.size.getPadding(),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标题栏
                  _buildHeader(context, isDark, primaryColor, textColor, mutedColor),
                  SizedBox(height: widget.size.getTitleSpacing()),

                  // 主要内容
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // 数值显示
                      _buildValueDisplay(textColor, mutedColor),
                      // 趋势迷你图
                      _buildMiniTrendChart(primaryColor),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, Color primaryColor, Color textColor, Color mutedColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              widget.icon,
              color: primaryColor,
              size: widget.size.getIconSize(),
            ),
            SizedBox(width: widget.size.getItemSpacing()),
            Text(
              widget.title,
              style: TextStyle(
                fontSize: widget.size.getTitleFontSize(),
                fontWeight: FontWeight.w600,
                color: textColor,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: () {},
          icon: Icon(
            Icons.chevron_right,
            color: mutedColor,
            size: widget.size.getIconSize() * 0.8,
          ),
          label: Text(
            'Today',
            style: TextStyle(
              fontSize: widget.size.getSubtitleFontSize(),
              fontWeight: FontWeight.w500,
              color: mutedColor,
            ),
          ),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: widget.size.getSmallSpacing(),
              vertical: widget.size.getSmallSpacing(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildValueDisplay(Color textColor, Color mutedColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.size.getLargeFontSize(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedFlipCounter(
                value: widget.currentValue * _animation.value,
                textStyle: TextStyle(
                  fontSize: widget.size.getLargeFontSize(),
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  height: 1.0,
                  letterSpacing: -1,
                ),
              ),
              SizedBox(width: widget.size.getSmallSpacing()),
              Padding(
                padding: EdgeInsets.only(bottom: widget.size.getSmallSpacing()),
                child: Text(
                  widget.unit,
                  style: TextStyle(
                    fontSize: widget.size.getSubtitleFontSize() + 4,
                    fontWeight: FontWeight.w500,
                    color: mutedColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: widget.size.getItemSpacing()),
        Text(
          widget.subtitle,
          style: TextStyle(
            fontSize: widget.size.getSubtitleFontSize(),
            fontWeight: FontWeight.w500,
            color: mutedColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniTrendChart(Color primaryColor) {
    final chartHeight = widget.size.getLargeFontSize();
    final chartWidth = widget.size.getLargeFontSize() * 3;

    return SizedBox(
      width: chartWidth,
      child: Column(
        children: [
          SizedBox(
            height: chartHeight,
            child: _AnimatedTrendLine(
              data: widget.trendData,
              color: primaryColor,
              animation: _animation,
              chartHeight: chartHeight,
              chartWidth: chartWidth,
            ),
          ),
          SizedBox(height: widget.size.getItemSpacing()),
          // 星期标签
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: widget.weekDays.map((day) {
              return Text(
                day,
                style: TextStyle(
                  fontSize: widget.size.getLegendFontSize() - 2,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF9CA3AF),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// 动画趋势折线图组件
class _AnimatedTrendChart extends StatelessWidget {
  final List<double> data;
  final Color color;
  final Animation<double> animation;
  final double chartHeight;
  final double chartWidth;

  const _AnimatedTrendChart({
    required this.data,
    required this.color,
    required this.animation,
    required this.chartHeight,
    required this.chartWidth,
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = data.reduce((a, b) => a > b ? a : b);
    final stepX = chartWidth / (data.length - 1);

    return CustomPaint(
      size: Size(chartWidth, chartHeight),
      painter: _TrendLinePainter(
        data: data,
        color: color,
        progress: animation.value,
        maxHeight: maxHeight,
        chartHeight: chartHeight,
        stepX: stepX,
      ),
    );
  }
}

/// 趋势折线画笔
class _TrendLinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double progress;
  final double maxHeight;
  final double chartHeight;
  final double stepX;

  _TrendLinePainter({
    required this.data,
    required this.color,
    required this.progress,
    required this.maxHeight,
    required this.chartHeight,
    required this.stepX,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // 绘制渐变填充
    final gradientPath = Path();
    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withOpacity(0.2 * progress),
        color.withOpacity(0),
      ],
    );

    gradientPath.moveTo(0, chartHeight);
    for (int i = 0; i < data.length * progress; i++) {
      final x = i * stepX;
      final y = chartHeight - (data[i] / maxHeight) * chartHeight * progress;
      if (i == 0) {
        gradientPath.lineTo(x, y);
      } else {
        gradientPath.lineTo(x, y);
      }
    }
    final lastX = (data.length * progress - 1).clamp(0, data.length - 1).toInt() * stepX;
    gradientPath.lineTo(lastX, chartHeight);
    gradientPath.close();

    final fillPaint = Paint()
      ..shader = fillGradient.createShader(const Rect.fromLTWH(0, 0, 140, 60));
    canvas.drawPath(gradientPath, fillPaint);

    // 绘制折线
    final linePath = Path();
    for (int i = 0; i < data.length * progress; i++) {
      final x = i * stepX;
      final y = chartHeight - (data[i] / maxHeight) * chartHeight * progress;
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _TrendLinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// 动画趋势折线图组件（使用 AnimatedBuilder）
class _AnimatedTrendLine extends StatelessWidget {
  final List<double> data;
  final Color color;
  final Animation<double> animation;
  final double chartHeight;
  final double chartWidth;

  const _AnimatedTrendLine({
    required this.data,
    required this.color,
    required this.animation,
    required this.chartHeight,
    required this.chartWidth,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return _AnimatedTrendChart(
          data: data,
          color: color,
          animation: animation,
          chartHeight: chartHeight,
          chartWidth: chartWidth,
        );
      },
    );
  }
}
