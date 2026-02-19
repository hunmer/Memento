import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import '../models/colorful_shortcuts_grid_data.dart';

/// 彩色快捷方式网格小组件
/// 用于显示带颜色背景的快捷方式网格，支持动画效果
class ColorfulShortcutsGridWidget extends StatefulWidget {
  /// 卡片数据
  final ColorfulShortcutsGridData data;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const ColorfulShortcutsGridWidget({
    super.key,
    required this.data,
    this.inline = false,
    this.size = const MediumSize(),
  });

  /// 从 props 创建实例
  factory ColorfulShortcutsGridWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return ColorfulShortcutsGridWidget(
      data: ColorfulShortcutsGridData.fromJson(props),
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

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
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
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
    final backgroundColor =
        isDark
            ? const Color(0xFF282828).withOpacity(0.8)
            : Colors.white.withOpacity(0.8);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(
              0,
              MediaQuery.of(context).size.height * _slideAnimation.value.dy,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color:
                      isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.white.withOpacity(0.4),
                  width: 1,
                ),
              ),
              padding: widget.size.getPadding(),
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
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.data.columns,
        crossAxisSpacing: widget.size.getSmallSpacing() * 3,
        mainAxisSpacing: widget.size.getSmallSpacing() * 3,
        childAspectRatio: 1.0,
      ),
      itemCount: widget.data.shortcuts.length,
      itemBuilder: (context, index) {
        return _ShortcutItemWidget(
          shortcut: widget.data.shortcuts[index],
          index: index,
          animationController: _animationController,
          size: widget.size,
        );
      },
    );
  }
}

/// 单个快捷方式项组件
class _ShortcutItemWidget extends StatelessWidget {
  final ShortcutItemData shortcut;
  final int index;
  final AnimationController animationController;
  final HomeWidgetSize size;

  const _ShortcutItemWidget({
    required this.shortcut,
    required this.index,
    required this.animationController,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    // 使用更小的 step 确保 end <= 1.0
    const safeStep = 0.05;
    final start = index * safeStep;
    final end = (0.6 + index * safeStep).clamp(0.0, 1.0);

    final itemAnimation = CurvedAnimation(
      parent: animationController,
      curve: Interval(
        start,
        end,
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
    // 计算按钮高度：基于图标大小
    final iconSize = size.getIconSize();
    final buttonHeight = iconSize * size.iconContainerScale;

    // 计算边框圆角：基于按钮高度的一半
    final buttonRadius = buttonHeight * 0.5;

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
        borderRadius: BorderRadius.circular(buttonRadius),
        splashColor: Colors.white.withOpacity(0.3),
        highlightColor: Colors.white.withOpacity(0.2),
        child: Container(
          height: buttonHeight,
          decoration: BoxDecoration(
            color: Color(shortcut.color),
            borderRadius: BorderRadius.circular(buttonRadius),
            boxShadow: [
              BoxShadow(
                color: Color(shortcut.color).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Container(
            padding: size.getPadding(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (shortcut.iconTransform != null &&
                    shortcut.iconTransform!.length == 16)
                  Transform(
                    transform: Matrix4.fromList(shortcut.iconTransform!),
                    alignment: Alignment.center,
                    child: Icon(
                      _getIconData(shortcut.iconName),
                      color: Colors.white,
                      size: size.getIconSize(),
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
                    _getIconData(shortcut.iconName),
                    color: Colors.white.withOpacity(0.9),
                    size: size.getIconSize(),
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                Text(
                  shortcut.label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size.getSubtitleFontSize(),
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    shadows: [Shadow(color: Color(0x10000000), blurRadius: 4)],
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

  /// 根据图标名称获取图标数据
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'event_available':
        return Icons.event_available;
      case 'collections':
        return Icons.collections;
      case 'note_add':
        return Icons.note_add;
      case 'add_comment':
        return Icons.add_comment;
      case 'chat_bubble':
        return Icons.chat_bubble;
      case 'mail':
        return Icons.mail;
      case 'send':
        return Icons.send;
      case 'home':
        return Icons.home;
      case 'favorite':
        return Icons.favorite;
      case 'settings':
        return Icons.settings;
      case 'search':
        return Icons.search;
      case 'add':
        return Icons.add;
      case 'check':
        return Icons.check;
      case 'close':
        return Icons.close;
      case 'delete':
        return Icons.delete;
      case 'edit':
        return Icons.edit;
      case 'star':
        return Icons.star;
      default:
        return Icons.star;
    }
  }
}
