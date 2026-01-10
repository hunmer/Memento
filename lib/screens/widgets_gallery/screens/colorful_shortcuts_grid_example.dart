import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 彩色快捷方式网格示例
class ColorfulShortcutsGridExample extends StatelessWidget {
  const ColorfulShortcutsGridExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('彩色快捷方式网格')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: Center(
          child: ColorfulShortcutsGridWidget(
            shortcuts: [
              ShortcutItem(
                icon: Icons.event_available,
                label: 'Block Off an Hour',
                color: const Color(0xFFFF5E63),
              ),
           
              ShortcutItem(
                icon: Icons.collections,
                label: 'Make GIF',
                color: const Color(0xFFFFB74D),
              ),
              ShortcutItem(
                icon: Icons.note_add,
                label: 'New Note with Date',
                color: const Color(0xFFEBCB0E),
              ),
              ShortcutItem(
                icon: Icons.add_comment,
                label: 'Text Last Image',
                color: const Color(0xFF4CD964),
              ),
              ShortcutItem(
                icon: Icons.chat_bubble,
                label: 'Text Running Late',
                color: const Color(0xFF00C7BE),
              ),
              ShortcutItem(
                icon: Icons.mail,
                label: 'Email Running Late',
                color: const Color(0xFF00D1F3),
              ),
              ShortcutItem(
                icon: Icons.send,
                label: 'Email Last Image',
                color: const Color(0xFF00B0FF),
                iconTransform: _createSendIconTransform(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Matrix4 _createSendIconTransform() {
    return Matrix4.rotationZ(-0.785)..translate(0.05, 0.05);
  }
}

/// 快捷方式数据模型
class ShortcutItem {
  final IconData icon;
  final String label;
  final Color color;
  final Matrix4? iconTransform;

  const ShortcutItem({
    required this.icon,
    required this.label,
    required this.color,
    this.iconTransform,
  });
}

/// 彩色快捷方式网格小组件
class ColorfulShortcutsGridWidget extends StatefulWidget {
  final List<ShortcutItem> shortcuts;
  final int columns;
  final double itemHeight;
  final double spacing;
  final double borderRadius;

  const ColorfulShortcutsGridWidget({
    super.key,
    required this.shortcuts,
    this.columns = 2,
    this.itemHeight = 100,
    this.spacing = 14,
    this.borderRadius = 40,
  });

  @override
  State<ColorfulShortcutsGridWidget> createState() =>
      _ColorfulShortcutsGridWidgetState();
}

class _ColorfulShortcutsGridWidgetState
    extends State<ColorfulShortcutsGridWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
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
    final backgroundColor = isDark
        ? const Color(0xFF282828).withOpacity(0.8)
        : Colors.white.withOpacity(0.8);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0,
                MediaQuery.of(context).size.height * _slideAnimation.value.dy),
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.white.withOpacity(0.4),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: _buildGrid(context),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.columns,
        crossAxisSpacing: widget.spacing,
        mainAxisSpacing: widget.spacing,
        childAspectRatio: 1.0,
      ),
      itemCount: widget.shortcuts.length,
      itemBuilder: (context, index) {
        return _ShortcutItemWidget(
          shortcut: widget.shortcuts[index],
          index: index,
          animationController: _animationController,
        );
      },
    );
  }
}

/// 单个快捷方式项
class _ShortcutItemWidget extends StatelessWidget {
  final ShortcutItem shortcut;
  final int index;
  final AnimationController animationController;

  const _ShortcutItemWidget({
    required this.shortcut,
    required this.index,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    // 使用更小的 step 确保 end <= 1.0
    // 8个元素：0.05 * 7 = 0.35，最大 end = 0.6 + 0.35 = 0.95
    const safeStep = 0.05;

    final itemAnimation = CurvedAnimation(
      parent: animationController,
      curve: Interval(
        index * safeStep,
        0.6 + index * safeStep,
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: itemAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * itemAnimation.value),
          child: Opacity(
            opacity: itemAnimation.value,
            child: _buildButton(context),
          ),
        );
      },
    );
  }

  Widget _buildButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // 处理点击事件
          HapticFeedback.lightImpact();
        },
        onLongPress: () {
          // 处理长按事件
          HapticFeedback.mediumImpact();
        },
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.white.withOpacity(0.3),
        highlightColor: Colors.white.withOpacity(0.2),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: shortcut.color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: shortcut.color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (shortcut.iconTransform != null)
                  Transform(
                    transform: shortcut.iconTransform!,
                    alignment: Alignment.center,
                    child: Icon(
                      shortcut.icon,
                      color: Colors.white,
                      size: 24,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  )
                else
                  Icon(
                    shortcut.icon,
                    color: Colors.white.withOpacity(0.9),
                    size: 24,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                Text(
                  shortcut.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    shadows: [
                      Shadow(
                        color: Color(0x10000000),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
