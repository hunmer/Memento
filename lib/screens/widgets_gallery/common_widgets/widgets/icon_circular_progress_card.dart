import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 图标圆形进度小组件
///
/// 显示带圆形进度条的卡片，支持图标、通知点、标题和副标题
class IconCircularProgressCardWidget extends StatefulWidget {
  /// 进度值 (0.0 - 1.0)
  final double progress;

  /// 中心图标
  final IconData icon;

  /// 标题
  final String title;

  /// 副标题
  final String subtitle;

  /// 是否显示通知点
  final bool showNotification;

  /// 进度颜色（可选）
  final Color? progressColor;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const IconCircularProgressCardWidget({
    super.key,
    required this.progress,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.showNotification = false,
    this.progressColor,
    this.inline = false,
    this.size = HomeWidgetSize.medium,
  });

  /// 从 props 创建实例
  factory IconCircularProgressCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return IconCircularProgressCardWidget(
      progress: (props['progress'] as num?)?.toDouble() ?? 0.0,
      icon: props['icon'] is IconData
          ? props['icon'] as IconData
          : Icons.circle_outlined,
      title: props['title'] as String? ?? '',
      subtitle: props['subtitle'] as String? ?? '',
      showNotification: props['showNotification'] as bool? ?? false,
      progressColor: props['progressColor'] != null
          ? Color(props['progressColor'] as int)
          : null,
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<IconCircularProgressCardWidget> createState() =>
      _IconCircularProgressCardWidgetState();
}

class _IconCircularProgressCardWidgetState
    extends State<IconCircularProgressCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    );

    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    );

    _progressAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
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
    final backgroundColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final primaryColor = widget.progressColor ??
        Theme.of(context).colorScheme.primary;
    final trackColor = isDark
        ? const Color(0xFF374151)
        : const Color(0xFFEBF8FF);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _slideAnimation.value)),
            child: Container(
              width: widget.inline ? double.maxFinite : 160,
              height: widget.inline ? double.maxFinite : 160,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Container(
                padding: widget.size.getPadding(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 圆形进度条
                    _buildCircularProgress(
                      primaryColor,
                      trackColor,
                      isDark,
                    ),
                    // 标题和副标题
                    _buildTextInfo(isDark),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建圆形进度条
  Widget _buildCircularProgress(
    Color primaryColor,
    Color trackColor,
    bool isDark,
  ) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        children: [
          // 进度圆环
          Transform.rotate(
            angle: -90 * math.pi / 180,
            child: CustomPaint(
              size: const Size(60, 60),
              painter: _IconCircularProgressPainter(
                progress: widget.progress * _progressAnimation.value,
                progressColor: primaryColor,
                trackColor: trackColor,
                strokeWidth: 10,
              ),
            ),
          ),
          // 中心图标
          Center(
            child: _buildIconWithNotification(isDark),
          ),
        ],
      ),
    );
  }

  /// 构建带通知点的图标
  Widget _buildIconWithNotification(bool isDark) {
    final borderColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return SizedBox(
      width: 22,
      height: 22,
      child: Stack(
        children: [
          // 图标
          Icon(
            widget.icon,
            size: 22,
            color: widget.progressColor ??
                Theme.of(context).colorScheme.primary,
          ),
          // 通知点
          if (widget.showNotification)
            Positioned(
              top: 0,
              right: -2,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: borderColor,
                    width: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建文本信息区域
  Widget _buildTextInfo(bool isDark) {
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtitleColor = isDark
        ? const Color(0xFF6B7280)
        : const Color(0xFF9CA3AF);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Text(
          widget.title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: titleColor,
            height: 1.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: widget.size.getItemSpacing()),
        // 副标题
        Text(
          widget.subtitle,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: subtitleColor,
            height: 1.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// 图标圆形进度条绘制器
class _IconCircularProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color trackColor;
  final double strokeWidth;

  _IconCircularProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 绘制轨道
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // 绘制进度
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        0,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _IconCircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}
