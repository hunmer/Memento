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
      weekDays:
          (props['weekDays'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
      trendData:
          (props['trendData'] as List<dynamic>?)
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
        }[iconName] ??
        Icons.monitor_heart;
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
    final primaryColor = Theme.of(context).colorScheme.primary;
    final surfaceColor =
        isDark ? primaryColor.withOpacity(0.15) : primaryColor.withOpacity(0.1);

    // 判断是否为 wide 类型
    final isWide = widget.size.width == 4;

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
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题栏
                  _buildHeader(
                    context,
                    isDark,
                    primaryColor,
                    surfaceColor,
                  ),
                  SizedBox(height: widget.size.getTitleSpacing()),

                  // 主要内容
                  Expanded(
                    child: isWide
                        ? // wide 类型：数值显示 + 趋势图
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // 数值显示
                              Flexible(
                                flex: 6,
                                child: _buildValueDisplay(isDark),
                              ),
                              const SizedBox(width: 8),
                              // 趋势迷你图靠右
                              Flexible(
                                flex: 7,
                                child: _buildMiniTrendChart(primaryColor),
                              ),
                            ],
                          )
                        : // 非 wide 类型：只显示趋势图（占满宽度）
                        _buildMiniTrendChart(primaryColor),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    bool isDark,
    Color primaryColor,
    Color surfaceColor,
  ) {
    final iconSize = widget.size.getIconSize();
    final containerSize = iconSize * widget.size.iconContainerScale;

    return Row(
      children: [
        // 左侧图标和标题区域
        Expanded(
          child: Row(
            children: [
              Container(
                width: containerSize,
                height: containerSize,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: primaryColor, size: iconSize),
              ),
              SizedBox(width: widget.size.getItemSpacing()),
              Flexible(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: widget.size.getTitleFontSize(),
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey.shade900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        // Today 按钮
        InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.size.getItemSpacing(),
              vertical: widget.size.getItemSpacing() / 2,
            ),
            child: Row(
              children: [
                Text(
                  'Today',
                  style: TextStyle(
                    fontSize: widget.size.getLegendFontSize(),
                    fontWeight: FontWeight.w400,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                SizedBox(width: widget.size.getItemSpacing()),
                Icon(
                  Icons.chevron_right,
                  size: iconSize * 0.8,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildValueDisplay(bool isDark) {
    final scoreFontSize = widget.size.getLargeFontSize() * 0.7;
    final unitFontSize = widget.size.getLargeFontSize() * 0.35;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AnimatedFlipCounter(
              value: widget.currentValue * _animation.value,
              textStyle: TextStyle(
                fontSize: scoreFontSize,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey.shade900,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: widget.size.getItemSpacing()),
              child: Text(
                widget.unit,
                style: TextStyle(
                  fontSize: unitFontSize,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.grey.shade900,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: widget.size.getItemSpacing()),
        Flexible(
          child: Text(
            widget.subtitle,
            style: TextStyle(
              fontSize: widget.size.getSubtitleFontSize(),
              fontWeight: FontWeight.w400,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniTrendChart(Color primaryColor) {
    final chartHeight = widget.size.getLargeFontSize() * 1.15;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Expanded(
          child: _AnimatedTrendLine(
            data: widget.trendData,
            color: primaryColor,
            animation: _animation,
            chartHeight: chartHeight,
          ),
        ),
        SizedBox(height: widget.size.getItemSpacing()),
        // 星期标签
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children:
              widget.weekDays.map((day) {
                return Text(
                  day,
                  style: TextStyle(
                    fontSize: widget.size.getLegendFontSize(),
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}

/// 动画趋势折线图组件
class _AnimatedTrendChart extends StatelessWidget {
  final List<double> data;
  final Color color;
  final Animation<double> animation;
  final double chartHeight;

  const _AnimatedTrendChart({
    required this.data,
    required this.color,
    required this.animation,
    required this.chartHeight,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(
        painter: _TrendLinePainter(
          data: data,
          color: color,
          progress: animation.value,
          chartHeight: chartHeight,
        ),
      ),
    );
  }
}

/// 趋势折线画笔
class _TrendLinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double progress;
  final double chartHeight;

  _TrendLinePainter({
    required this.data,
    required this.color,
    required this.progress,
    required this.chartHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final chartWidth = size.width;
    final maxHeight = data.isEmpty ? 1.0 : data.reduce((a, b) => a > b ? a : b).toDouble();
    final stepX = data.length > 1 ? chartWidth / (data.length - 1) : chartWidth;

    // 绘制渐变填充
    final gradientPath = Path();
    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [color.withOpacity(0.2 * progress), color.withOpacity(0)],
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
    final lastX =
        (data.length * progress - 1).clamp(0, data.length - 1).toInt() * stepX;
    gradientPath.lineTo(lastX, chartHeight);
    gradientPath.close();

    final fillPaint =
        Paint()
          ..shader = fillGradient.createShader(
            Rect.fromLTWH(0, 0, chartWidth, chartHeight),
          );
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

    final linePaint =
        Paint()
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

  const _AnimatedTrendLine({
    required this.data,
    required this.color,
    required this.animation,
    required this.chartHeight,
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
        );
      },
    );
  }
}
