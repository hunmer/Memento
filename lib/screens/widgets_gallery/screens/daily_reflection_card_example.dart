import 'package:flutter/material.dart';

/// 每日反思卡片示例
class DailyReflectionCardExample extends StatelessWidget {
  const DailyReflectionCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('每日反思卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: DailyReflectionCardWidget(
            dayOfWeek: 'Monday',
            question: 'How will you make tomorrow meaningful?',
          ),
        ),
      ),
    );
  }
}

/// 每日反思卡片小组件
///
/// 一个引导用户每日思考和记录的卡片组件，包含：
/// - 星期几显示
/// - 引导性问题文本
/// - 新建和同步操作按钮
/// - 蝴蝶装饰图标
class DailyReflectionCardWidget extends StatefulWidget {
  /// 星期几标签
  final String dayOfWeek;

  /// 引导性问题
  final String question;

  /// 卡片背景色（深色模式）
  final Color? darkBackgroundColor;

  /// 主色调（按钮颜色）
  final Color? primaryColor;

  const DailyReflectionCardWidget({
    super.key,
    required this.dayOfWeek,
    required this.question,
    this.darkBackgroundColor,
    this.primaryColor,
  });

  @override
  State<DailyReflectionCardWidget> createState() =>
      _DailyReflectionCardWidgetState();
}

class _DailyReflectionCardWidgetState extends State<DailyReflectionCardWidget>
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
    // 根据原型使用深色背景
    final backgroundColor =
        widget.darkBackgroundColor ?? const Color(0xFF2A2D45);

    // 主色调
    final primaryColor = widget.primaryColor ?? const Color(0xFF626D9E);

    // 悬停颜色
    final hoverColor = primaryColor.withOpacity(0.8);

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
        width: 340,
        height: 340,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // 背景装饰（可选的渐变叠加）
            Positioned.fill(
              child: Opacity(
                opacity: 0.03,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF8E9AFF),
                        const Color(0xFFFF8EA9),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // 主要内容
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部行：星期几 + 蝴蝶图标
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.dayOfWeek,
                        style: TextStyle(
                          color: const Color(0xFFD1D5DB),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      _ButterflyIcon(animation: _animation, size: 32),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 中间：引导性问题
                  Expanded(
                    child: Center(
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 800),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 10 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          widget.question,
                          style: TextStyle(
                            color: const Color(0xFF9FA8DA),
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 底部：按钮组
                  _ButtonGroup(
                    animation: _animation,
                    primaryColor: primaryColor,
                    hoverColor: hoverColor,
                  ),
                ],
              ),
            ),
            // 底部标签（在卡片外层显示）
          ],
        ),
      ),
    );
  }
}

/// 蝴蝶装饰图标
class _ButterflyIcon extends StatelessWidget {
  final Animation<double> animation;
  final double size;

  const _ButterflyIcon({required this.animation, required this.size});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _ButterflyPainter()),
      ),
    );
  }
}

/// 蝴蝶绘制器
class _ButterflyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.width / 24;

    // 左翅膀（紫色渐变）
    final leftWingPath =
        Path()
          ..moveTo(center.dx, center.dy)
          ..lineTo(center.dx - 8 * scale, center.dy - 4 * scale)
          ..lineTo(center.dx - 7 * scale, center.dy)
          ..lineTo(center.dx - 7 * scale, center.dy + 3 * scale)
          ..close();

    final leftWingGradient = LinearGradient(
      colors: [const Color(0xFF818CF8), const Color(0xFFC084FC)],
    ).createShader(Rect.fromCircle(center: center, radius: size.width / 2));

    canvas.drawPath(leftWingPath, Paint()..shader = leftWingGradient);

    // 右翅膀（橙红色渐变）
    final rightWingPath =
        Path()
          ..moveTo(center.dx, center.dy)
          ..lineTo(center.dx + 8 * scale, center.dy - 4 * scale)
          ..lineTo(center.dx + 7 * scale, center.dy)
          ..lineTo(center.dx + 7 * scale, center.dy + 3 * scale)
          ..close();

    final rightWingGradient = LinearGradient(
      colors: [const Color(0xFFF87171), const Color(0xFFFB923C)],
    ).createShader(Rect.fromCircle(center: center, radius: size.width / 2));

    canvas.drawPath(rightWingPath, Paint()..shader = rightWingGradient);

    // 左下翼（浅紫色）
    final leftLowerPath =
        Path()
          ..moveTo(center.dx, center.dy)
          ..lineTo(center.dx - 7 * scale, center.dy + 5 * scale)
          ..lineTo(center.dx - 6 * scale, center.dy + 3 * scale)
          ..close();

    canvas.drawPath(leftLowerPath, Paint()..color = const Color(0xFFA5B4FC));

    // 右下翼（浅粉色）
    final rightLowerPath =
        Path()
          ..moveTo(center.dx, center.dy)
          ..lineTo(center.dx + 7 * scale, center.dy + 5 * scale)
          ..lineTo(center.dx + 6 * scale, center.dy + 3 * scale)
          ..close();

    canvas.drawPath(rightLowerPath, Paint()..color = const Color(0xFFFCA5A5));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 按钮组
class _ButtonGroup extends StatelessWidget {
  final Animation<double> animation;
  final Color primaryColor;
  final Color hoverColor;

  const _ButtonGroup({
    required this.animation,
    required this.primaryColor,
    required this.hoverColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // New 按钮
        Expanded(
          child: _AnimatedButton(
            animation: animation,
            index: 0,
            color: primaryColor,
            hoverColor: hoverColor,
            icon: Icons.edit_note,
            label: 'New',
            onTap: () {
              // TODO: 处理新建操作
            },
          ),
        ),
        const SizedBox(width: 12),
        // Sync 按钮
        _AnimatedButton(
          animation: animation,
          index: 1,
          color: primaryColor,
          hoverColor: hoverColor,
          icon: Icons.sync,
          isIconOnly: true,
          onTap: () {
            // TODO: 处理同步操作
          },
        ),
      ],
    );
  }
}

/// 动画按钮
class _AnimatedButton extends StatefulWidget {
  final Animation<double> animation;
  final int index;
  final Color color;
  final Color hoverColor;
  final IconData icon;
  final String? label;
  final bool isIconOnly;
  final VoidCallback onTap;

  const _AnimatedButton({
    required this.animation,
    required this.index,
    required this.color,
    required this.hoverColor,
    required this.icon,
    this.label,
    this.isIconOnly = false,
    required this.onTap,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // 计算延迟动画
    final step = 0.1;
    final itemAnimation = CurvedAnimation(
      parent: widget.animation,
      curve: Interval(
        widget.index * step,
        0.6 + widget.index * step,
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: itemAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + 0.2 * itemAnimation.value,
          child: Opacity(opacity: itemAnimation.value, child: child),
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56,
            width: 80,
            decoration: BoxDecoration(
              color: _isHovered ? widget.hoverColor : widget.color,
              borderRadius: BorderRadius.circular(28),
            ),
            child:
                widget.isIconOnly
                    ? Center(
                      child: Icon(widget.icon, color: Colors.white, size: 24),
                    )
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(widget.icon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          widget.label!,
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
