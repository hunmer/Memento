import 'package:flutter/material.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/models/sleep_tracking_card_data.dart';

/// 睡眠追踪卡片公共小组件
///
/// 用于展示每日睡眠时长和周进度追踪的卡片组件，支持动画效果和主题适配。
/// 适用于健康追踪、睡眠管理等场景。
///
/// 支持序列化的数据模型，可从 JSON 字符串配置。
///
/// 使用示例：
/// ```dart
/// SleepTrackingCardWidget(
///   data: SleepTrackingCardData(
///     sleepHours: 7.5,
///     sleepLabel: 'Good Sleep',
///     weeklyProgress: [
///       DaySleepData(day: 'M', achieved: true, progress: 1.0),
///       // ... 其他6天
///     ],
///   ),
///   size: HomeWidgetSize.large,
/// )
/// ```
class SleepTrackingCardWidget extends StatefulWidget {
  /// 数据模型
  final SleepTrackingCardData data;

  /// 小组件尺寸
  final HomeWidgetSize size;

  /// 卡片图标，默认为 Icons.bedtime_rounded
  final IconData? icon;

  /// 卡片宽度，默认根据尺寸自适应
  final double? width;

  /// 卡片内边距，默认24
  final EdgeInsetsGeometry? padding;

  /// 圆角半径，默认28
  final double? borderRadius;

  /// 是否显示阴影，默认true（浅色模式）
  final bool? showShadow;

  /// 动画时长，默认1200ms
  final Duration? animationDuration;

  /// 点击右侧操作的回调
  final VoidCallback? onActionTap;

  const SleepTrackingCardWidget({
    super.key,
    required this.data,
    required this.size,
    this.icon,
    this.width,
    this.padding,
    this.borderRadius,
    this.showShadow,
    this.animationDuration,
    this.onActionTap,
  });

  /// 从属性映射创建组件（用于动态渲染）
  static SleepTrackingCardWidget fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    // 尝试从 props 中解析 data
    SleepTrackingCardData? data;

    if (props.containsKey('data')) {
      // 如果 data 是字符串，尝试解析
      final dataValue = props['data'];
      if (dataValue is String) {
        try {
          data = SleepTrackingCardData.fromJsonString(dataValue);
        } catch (e) {
          debugPrint('Failed to parse SleepTrackingCardData: $e');
        }
      } else if (dataValue is Map<String, dynamic>) {
        data = SleepTrackingCardData.fromJson(dataValue);
      }
    }

    // 如果解析失败，使用默认值
    data ??= SleepTrackingCardData.createDefault();

    return SleepTrackingCardWidget(
      data: data,
      size: size,
      icon: props['icon'] as IconData?,
      width: props['width'] as double?,
      padding: props['padding'] as EdgeInsetsGeometry?,
      borderRadius: props['borderRadius'] as double?,
      showShadow: props['showShadow'] as bool?,
      animationDuration: props['animationDuration'] != null
          ? Duration(
              milliseconds:
                  props['animationDuration'] as int? ?? 1200,
            )
          : null,
      onActionTap: props['onActionTap'] as VoidCallback?,
    );
  }

  /// 将组件配置转换为属性映射（用于保存配置）
  static Map<String, dynamic> toProps(SleepTrackingCardData data,
      {HomeWidgetSize? size}) {
    return {
      'data': data.toJsonString(),
      if (size != null) 'size': size.name,
    };
  }

  @override
  State<SleepTrackingCardWidget> createState() =>
      _SleepTrackingCardWidgetState();
}

class _SleepTrackingCardWidgetState extends State<SleepTrackingCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration ?? const Duration(milliseconds: 1200),
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
    final primaryColor = _getPrimaryColor(isDark);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: widget.width ?? _getDefaultWidth(),
              padding: widget.padding ?? const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                borderRadius:
                    BorderRadius.circular(widget.borderRadius ?? 28),
                boxShadow:
                    (widget.showShadow ?? (!isDark))
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标题栏
                  _buildHeader(context, isDark, primaryColor),
                  const SizedBox(height: 24),
                  // 主内容区
                  _buildContent(context, isDark, primaryColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getPrimaryColor(bool isDark) {
    if (widget.data.primaryColor != null) {
      try {
        return Color(
          int.parse(widget.data.primaryColor!, radix: 16),
        );
      } catch (e) {
        debugPrint('Failed to parse primaryColor: ${widget.data.primaryColor}');
      }
    }
    return isDark
        ? const Color(0xFFF36E24)
        : Theme.of(context).colorScheme.primary;
  }

  double _getDefaultWidth() {
    switch (widget.size) {
      case HomeWidgetSize.small:
        return 300;
      case HomeWidgetSize.medium:
        return 350;
      case HomeWidgetSize.large:
      case HomeWidgetSize.large3:
        return 400;
      case HomeWidgetSize.wide:
        return 600;
      case HomeWidgetSize.wide2:
        return 600;
      case HomeWidgetSize.wide3:
        return 600;
      case HomeWidgetSize.custom:
        return 400;
    }
  }

  Widget _buildHeader(BuildContext context, bool isDark, Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                widget.icon ?? Icons.bedtime_rounded,
                color: primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              widget.data.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
          ],
        ),
        InkWell(
          onTap: widget.onActionTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Text(
                  widget.data.actionLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: isDark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, bool isDark, Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 左侧：睡眠时长
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 48,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 90,
                    height: 48,
                    child: AnimatedFlipCounter(
                      value: widget.data.sleepHours * _animation.value,
                      fractionDigits: 2,
                      textStyle: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    height: 20,
                    child: Text(
                      'hr',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280),
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.data.sleepLabel,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        // 右侧：周日程进度
        Row(
          children:
              widget.data.weeklyProgress.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;

                // 计算动画延迟
                final itemAnimation = CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    index * 0.08,
                    0.5 + index * 0.08,
                    curve: Curves.easeOutCubic,
                  ),
                );

                return Padding(
                  padding: EdgeInsets.only(left: index == 0 ? 0 : 8),
                  child: _DaySleepIndicator(
                    dayData: data,
                    primaryColor: primaryColor,
                    isDark: isDark,
                    animation: itemAnimation,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}

/// 日睡眠进度指示器
class _DaySleepIndicator extends StatelessWidget {
  final DaySleepData dayData;
  final Color primaryColor;
  final bool isDark;
  final Animation<double> animation;

  const _DaySleepIndicator({
    required this.dayData,
    required this.primaryColor,
    required this.isDark,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final animatedProgress = dayData.progress * animation.value;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              dayData.achieved ? Icons.check_rounded : Icons.close_rounded,
              size: 16,
              color: dayData.achieved
                  ? (isDark ? Colors.white : const Color(0xFF111827))
                  : (isDark
                      ? const Color(0xFF4B5563)
                      : const Color(0xFFD1D5DB)),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 24,
              height: 24,
              child: CustomPaint(
                painter: _CircleProgressPainter(
                  progress: animatedProgress,
                  primaryColor: primaryColor,
                  backgroundColor:
                      isDark
                          ? const Color(0xFF4B5563)
                          : const Color(0xFFE5E7EB),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dayData.day,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 圆形进度绘制器
class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color backgroundColor;

  _CircleProgressPainter({
    required this.progress,
    required this.primaryColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2.5; // 减去描边宽度的一半
    final strokeWidth = 2.5;

    // 绘制背景圆环
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // 绘制进度圆弧
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      const startAngle = -3.141592653589793238 / 2; // 从顶部开始
      final sweepAngle = 2 * 3.141592653589793238 * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
