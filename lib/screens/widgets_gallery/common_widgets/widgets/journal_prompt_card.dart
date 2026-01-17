import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'dart:ui' as ui;
import '../models/journal_prompt_card_data.dart';

/// 日记提示卡片小组件
/// 显示星期、提示问题和操作按钮（新建、同步），支持动画效果
class JournalPromptCardWidget extends StatefulWidget {
  /// 星期几
  final String weekday;

  /// 提示问题
  final String prompt;

  /// 新建按钮回调（在通用小组件中使用空实现）
  final VoidCallback onNewPressed;

  /// 同步按钮回调（在通用小组件中使用空实现）
  final VoidCallback onSyncPressed;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const JournalPromptCardWidget({
    super.key,
    required this.weekday,
    required this.prompt,
    required this.onNewPressed,
    required this.onSyncPressed,
    this.inline = false,
    this.size = HomeWidgetSize.medium,
  });

  /// 从属性创建（用于动态渲染）
  factory JournalPromptCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final data = JournalPromptCardData.fromJson(props);
    return JournalPromptCardWidget(
      weekday: data.weekday,
      prompt: data.prompt,
      onNewPressed: () {}, // 通用小组件中不执行实际操作
      onSyncPressed: () {}, // 通用小组件中不执行实际操作
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<JournalPromptCardWidget> createState() =>
      _JournalPromptCardWidgetState();
}

class _JournalPromptCardWidgetState extends State<JournalPromptCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = CurvedAnimation(
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
    final backgroundColor = isDark ? const Color(0xFF1F2937) : const Color(0xFF2A2D45);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _slideAnimation.value)),
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // 背景装饰
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF8E9AFF).withOpacity(0.1),
                        backgroundColor.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),

              // 主内容
              Padding(
                padding: widget.size.getPadding(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 顶部栏:星期 + 蝴蝶图标
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.weekday,
                          style: TextStyle(
                            color: const Color(0xFFD1D5DB),
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        _ButterflyIcon(animation: _animationController),
                      ],
                    ),

                    SizedBox(height: widget.size.getTitleSpacing()),

                    // 提示问题
                    Expanded(
                      child: Center(
                        child: Text(
                          widget.prompt,
                          style: TextStyle(
                            color: const Color(0xFF9FA8DA),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),

                    SizedBox(height: widget.size.getTitleSpacing()),

                    // 按钮组
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.edit_note,
                            label: 'New',
                            onPressed: widget.onNewPressed,
                            animation: _animationController,
                            size: widget.size,
                          ),
                        ),
                        SizedBox(width: widget.size.getItemSpacing()),
                        _SyncButton(
                          onPressed: widget.onSyncPressed,
                          animation: _animationController,
                          size: widget.size,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 蝴蝶图标
class _ButterflyIcon extends StatelessWidget {
  final Animation<double> animation;

  const _ButterflyIcon({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final scale = 0.8 + 0.2 * animation.value;
        return Transform.scale(
          scale: scale,
          child: SizedBox(
            width: 32,
            height: 32,
            child: CustomPaint(painter: _ButterflyPainter()),
          ),
        );
      },
    );
  }
}

/// 蝴蝶绘制器
class _ButterflyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 左翅膀渐变
    final leftWingGradient = ui.Gradient.linear(
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.5, size.height * 0.7),
      [const Color(0xFF818CF8), const Color(0xFFC084FC)],
    );

    // 右翅膀渐变
    final rightWingGradient = ui.Gradient.linear(
      Offset(size.width * 0.8, size.height * 0.3),
      Offset(size.width * 0.5, size.height * 0.7),
      [const Color(0xFFF87171), const Color(0xFFFB923C)],
    );

    // 绘制左翅膀
    final leftWingPath = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(center.dx - 8, center.dy - 6)
      ..quadraticBezierTo(
        center.dx - 12,
        center.dy,
        center.dx - 8,
        center.dy + 4,
      )
      ..lineTo(center.dx, center.dy + 2)
      ..close();

    final leftWingPaint = Paint()
      ..shader = leftWingGradient
      ..style = PaintingStyle.fill;

    canvas.drawPath(leftWingPath, leftWingPaint);

    // 绘制右翅膀
    final rightWingPath = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(center.dx + 8, center.dy - 6)
      ..quadraticBezierTo(
        center.dx + 12,
        center.dy,
        center.dx + 8,
        center.dy + 4,
      )
      ..lineTo(center.dx, center.dy + 2)
      ..close();

    final rightWingPaint = Paint()
      ..shader = rightWingGradient
      ..style = PaintingStyle.fill;

    canvas.drawPath(rightWingPath, rightWingPaint);

    // 绘制左下翅膀
    final leftBottomPath = Path()
      ..moveTo(center.dx, center.dy + 2)
      ..lineTo(center.dx - 6, center.dy + 6)
      ..quadraticBezierTo(
        center.dx - 3,
        center.dy + 8,
        center.dx,
        center.dy + 6,
      )
      ..close();

    final leftBottomPaint = Paint()
      ..color = const Color(0xFFA5B4FC)
      ..style = PaintingStyle.fill;

    canvas.drawPath(leftBottomPath, leftBottomPaint);

    // 绘制右下翅膀
    final rightBottomPath = Path()
      ..moveTo(center.dx, center.dy + 2)
      ..lineTo(center.dx + 6, center.dy + 6)
      ..quadraticBezierTo(
        center.dx + 3,
        center.dy + 8,
        center.dx,
        center.dy + 6,
      )
      ..close();

    final rightBottomPaint = Paint()
      ..color = const Color(0xFFFCA5A5)
      ..style = PaintingStyle.fill;

    canvas.drawPath(rightBottomPath, rightBottomPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 操作按钮
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Animation<double> animation;
  final HomeWidgetSize size;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.animation,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final delay = 0.15;
        final localAnimation = CurvedAnimation(
          parent: animation,
          curve: Interval(delay, 0.6 + delay, curve: Curves.easeOutCubic),
        );

        return Opacity(
          opacity: localAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - localAnimation.value)),
            child: child,
          ),
        );
      },
      child: Material(
        color: const Color(0xFF626D9E),
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            height: 56,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                SizedBox(width: size.getItemSpacing()),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 同步按钮
class _SyncButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Animation<double> animation;
  final HomeWidgetSize size;

  const _SyncButton({
    required this.onPressed,
    required this.animation,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final delay = 0.3;
        final localAnimation = CurvedAnimation(
          parent: animation,
          curve: Interval(delay, 0.6 + delay, curve: Curves.easeOutCubic),
        );

        return Opacity(
          opacity: localAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - localAnimation.value)),
            child: child,
          ),
        );
      },
      child: SizedBox(
        width: 56,
        height: 56,
        child: Material(
          color: const Color(0xFF626D9E),
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(28),
            child: const Icon(Icons.sync, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}
