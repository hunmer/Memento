import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

/// CustomBottomBar - 封装 flutter_floating_bottom_bar 的 BottomBar 组件
///
/// 提供预设的默认参数，减少重复代码，支持动态颜色主题
///
/// ## 常用参数说明
/// - [colors]: 每个 Tab 对应的颜色列表
/// - [currentIndex]: 当前选中的 Tab 索引
/// - [tabController]: Tab 控制器
/// - [body]: 底部栏上方的内容（通常是 TabBarView）
/// - [children]: TabBar 的子项（Tabs）
/// - [fab]: 悬浮按钮（可选）
/// - [fabLocation]: FAB 位置，默认顶部居中
class CustomBottomBar extends StatefulWidget {
  /// 每个 Tab 对应的颜色列表，用于动态主题
  final List<Color> colors;

  /// 当前选中的 Tab 索引
  final int currentIndex;

  /// Tab 控制器
  final TabController tabController;

  /// 底部栏上方的内容（通常是 TabBarView）
  final Widget Function(BuildContext context, ScrollController controller) body;

  /// TabBar 的子项
  final List<Widget> children;

  /// 悬浮按钮（可选）
  final Widget? fab;

  /// FAB 位置，默认顶部居中
  final AlignmentGeometry fabLocation;

  /// 底部栏宽度占屏幕宽度的比例，默认 0.85
  final double widthRatio;

  /// 底部栏偏移量，默认 12
  final double offset;

  /// 底部栏高度测量键（用于外部获取高度）
  final GlobalKey? bottomBarKey;

  /// 是否启用滚动隐藏，默认 true
  final bool hideOnScroll;

  /// 额外的 TabBar 配置
  final TabBarTheme? tabBarTheme;

  /// TabBar indicator padding
  final EdgeInsetsDirectional? indicatorPadding;

  /// 自定义 indicator
  final Decoration? indicator;

  /// 额外的 children（在 TabBar 后面）
  final List<Widget> Function(BuildContext context, int currentIndex)? extraChildren;

  const CustomBottomBar({
    super.key,
    required this.colors,
    required this.currentIndex,
    required this.tabController,
    required this.body,
    required this.children,
    this.fab,
    this.fabLocation = Alignment.topCenter,
    this.widthRatio = 0.85,
    this.offset = 12,
    this.bottomBarKey,
    this.hideOnScroll = true,
    this.tabBarTheme,
    this.indicatorPadding,
    this.indicator,
    this.extraChildren,
  });

  @override
  State<CustomBottomBar> createState() => _CustomBottomBarState();
}

class _CustomBottomBarState extends State<CustomBottomBar> {
  double _bottomBarHeight = 60;

  @override
  void initState() {
    super.initState();
    widget.tabController.animation?.addListener(_onTabAnimation);
  }

  @override
  void dispose() {
    widget.tabController.animation?.removeListener(_onTabAnimation);
    super.dispose();
  }

  void _onTabAnimation() {
    // 保持状态同步，无需额外逻辑
  }

  /// 调度底部栏高度测量
  void _scheduleBottomBarHeightMeasurement() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.bottomBarKey?.currentContext != null) {
        final renderBox = widget.bottomBarKey!.currentContext!.findRenderObject() as RenderBox;
        final newHeight = renderBox.size.height;
        if (_bottomBarHeight != newHeight) {
          setState(() {
            _bottomBarHeight = newHeight;
          });
        }
      }
    });
  }

  /// 构建向上箭头图标（滚动到顶部功能）
  Widget _buildScrollToTopIcon(double width, double height) {
    return Center(
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          if (widget.tabController.indexIsChanging) return;
          if (widget.currentIndex != 0) {
            widget.tabController.animateTo(0);
          }
        },
        icon: Icon(
          Icons.keyboard_arrow_up,
          color: widget.colors[widget.currentIndex % widget.colors.length],
          size: width,
        ),
      ),
    );
  }

  /// 构建底部栏装饰
  BoxDecoration _buildBarDecoration() {
    final color = widget.colors[widget.currentIndex % widget.colors.length];
    return BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(25),
      border: Border.all(
        color: color.withOpacity(0.3),
        width: 1,
      ),
    );
  }

  /// 构建图标装饰
  BoxDecoration _buildIconDecoration() {
    final color = widget.colors[widget.currentIndex % widget.colors.length];
    return BoxDecoration(
      color: color.withOpacity(0.8),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// 构建 TabBar
  Widget _buildTabBar() {
    final colorScheme = Theme.of(context).colorScheme;
    final unselectedColor = colorScheme.onSurface.withOpacity(0.6);
    final color = widget.colors[widget.currentIndex % widget.colors.length];

    return TabBar(
      controller: widget.tabController,
      dividerColor: Colors.transparent,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      indicatorPadding: widget.indicatorPadding ?? const EdgeInsets.fromLTRB(6, 0, 6, 0),
      indicator: widget.indicator ??
          UnderlineTabIndicator(
            borderSide: BorderSide(
              color: color,
              width: 4,
            ),
            insets: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          ),
      labelColor: color,
      unselectedLabelColor: unselectedColor,
      tabs: widget.children,
    );
  }

  @override
  Widget build(BuildContext context) {
    _scheduleBottomBarHeightMeasurement();
    final colorScheme = Theme.of(context).colorScheme;
    final mediaQuery = MediaQuery.of(context);

    return BottomBar(
      fit: StackFit.expand,
      icon: _buildScrollToTopIcon,
      borderRadius: BorderRadius.circular(25),
      duration: const Duration(milliseconds: 300),
      curve: Curves.decelerate,
      showIcon: true,
      width: mediaQuery.size.width * widget.widthRatio,
      barColor: colorScheme.surface,
      start: 2,
      end: 0,
      offset: widget.offset,
      barAlignment: Alignment.bottomCenter,
      iconHeight: 35,
      iconWidth: 35,
      reverse: false,
      barDecoration: _buildBarDecoration(),
      iconDecoration: _buildIconDecoration(),
      hideOnScroll: widget.hideOnScroll &&
          !kIsWeb &&
          defaultTargetPlatform != TargetPlatform.macOS &&
          defaultTargetPlatform != TargetPlatform.windows &&
          defaultTargetPlatform != TargetPlatform.linux,
      scrollOpposite: false,
      onBottomBarHidden: () {},
      onBottomBarShown: () {},
      body: (context, controller) => Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(bottom: _bottomBarHeight),
              child: widget.body(context, controller),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: _bottomBarHeight,
              color: colorScheme.surface,
            ),
          ),
        ],
      ),
      child: Stack(
        key: widget.bottomBarKey,
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          _buildTabBar(),
          if (widget.fab != null)
            Positioned(
              top: -25,
              child: widget.fab!,
            ),
          if (widget.extraChildren != null)
            ...widget.extraChildren!(context, widget.currentIndex),
        ],
      ),
    );
  }
}

/// 简单的 CustomBottomBar 快捷构造函数（无 FAB）
///
/// 适用于不需要悬浮按钮的场景
class SimpleCustomBottomBar extends CustomBottomBar {
  const SimpleCustomBottomBar({
    super.key,
    required super.colors,
    required super.currentIndex,
    required super.tabController,
    required super.body,
    required super.children,
    super.widthRatio,
    super.offset,
    super.bottomBarKey,
    super.hideOnScroll,
    super.indicatorPadding,
    super.extraChildren,
  });
}
