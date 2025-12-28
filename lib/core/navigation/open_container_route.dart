import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// OpenContainer 风格的页面过渡路由
///
/// 实现从源 widget 位置放大展开到全屏的动画效果，类似 animations 包的 OpenContainer。
///
/// 特性：
/// - 从源 widget 位置和大小开始，放大过渡到全屏
/// - 支持背景色和形状过渡动画
/// - 支持 iOS 左滑返回手势
/// - 关闭时从全屏收缩回源位置
class OpenContainerRoute<T> extends PageRoute<T> {
  OpenContainerRoute({
    required this.sourceRect,
    required this.closedBuilder,
    required this.openBuilder,
    this.closedColor,
    this.openColor,
    this.closedElevation = 1.0,
    this.openElevation = 0.0,
    this.closedShape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12.0)),
    ),
    this.openShape = const RoundedRectangleBorder(),
    this.transitionDuration = const Duration(milliseconds: 300),
    this.reverseTransitionDuration = const Duration(milliseconds: 300),
    this.routeColor,
    this.useRootNavigator = false,
    super.settings,
  });

  /// 源 widget 的位置和大小（全局坐标）
  final Rect sourceRect;

  /// 关闭状态的构建器（用于过渡动画中显示）
  final WidgetBuilder closedBuilder;

  /// 打开状态的构建器（新页面）
  final WidgetBuilder openBuilder;

  /// 关闭状态的背景色
  final Color? closedColor;

  /// 打开状态的背景色
  final Color? openColor;

  /// 关闭状态的阴影高度
  final double closedElevation;

  /// 打开状态的阴影高度
  final double openElevation;

  /// 关闭状态的形状
  final ShapeBorder closedShape;

  /// 打开状态的形状
  final ShapeBorder openShape;

  /// 路由遮罩颜色
  final Color? routeColor;

  /// 是否使用根导航器
  final bool useRootNavigator;

  @override
  final Duration transitionDuration;

  @override
  final Duration reverseTransitionDuration;

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => routeColor;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  /// iOS 平台检测
  static bool get _isIOS => Platform.isIOS;

  /// 是否启用左滑返回手势（仅 iOS）
  @override
  bool get popGestureEnabled =>
      _isIOS &&
      !isFirst &&
      controller!.status == AnimationStatus.completed &&
      !navigator!.userGestureInProgress;

  /// 是否正在进行手势返回
  @override
  bool get popGestureInProgress => navigator!.userGestureInProgress;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _OpenContainerPage<T>(
      route: this,
      animation: animation,
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // iOS 平台添加左滑返回手势
    if (_isIOS) {
      return _IOSBackGestureDetector<T>(
        enabledCallback: () => popGestureEnabled,
        onStartPopGesture: () => _startPopGesture(this),
        child: child,
      );
    }
    return child;
  }

  /// 开始手势返回
  static _IOSBackGestureController<T> _startPopGesture<T>(
    OpenContainerRoute<T> route,
  ) {
    return _IOSBackGestureController<T>(
      navigator: route.navigator!,
      controller: route.controller!,
    );
  }
}

class _OpenContainerPage<T> extends StatefulWidget {
  const _OpenContainerPage({
    required this.route,
    required this.animation,
  });

  final OpenContainerRoute<T> route;
  final Animation<double> animation;

  @override
  State<_OpenContainerPage<T>> createState() => _OpenContainerPageState<T>();
}

class _OpenContainerPageState<T> extends State<_OpenContainerPage<T>>
    with SingleTickerProviderStateMixin {
  // 动画曲线
  static const Curve _curveForward = Curves.easeOutCubic;
  static const Curve _curveReverse = Curves.easeInCubic;

  // 动画区间
  // 展开时：0.0 - 0.35 容器展开，0.3 - 1.0 内容淡入
  // 收缩时：先内容淡出遮罩淡入（150ms），再容器收缩
  static const double _containerExpandEnd = 0.35;
  static const double _contentFadeStart = 0.3;

  late Animation<double> _containerAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<double> _closedFadeAnimation;

  /// 是否正在收缩（反向动画）
  bool _isClosing = false;

  /// 缓存的打开页面内容（用于展开完成后显示）
  Widget? _cachedOpenContent;

  /// 收缩遮罩动画控制器
  late AnimationController _closingMaskController;
  late Animation<double> _closingMaskAnimation;

  @override
  void initState() {
    super.initState();
    _closingMaskController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _closingMaskAnimation = CurvedAnimation(
      parent: _closingMaskController,
      curve: Curves.easeOut,
    );
    _setupAnimations();
    widget.animation.addStatusListener(_onAnimationStatusChanged);
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_onAnimationStatusChanged);
    _closingMaskController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _OpenContainerPage<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      oldWidget.animation.removeStatusListener(_onAnimationStatusChanged);
      widget.animation.addStatusListener(_onAnimationStatusChanged);
      _setupAnimations();
    }
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    final wasClosing = _isClosing;
    _isClosing = status == AnimationStatus.reverse;

    // 当开始收缩时，启动遮罩淡入动画
    if (_isClosing && !wasClosing) {
      _closingMaskController.forward();
    }
    // 当收缩结束或取消时，重置遮罩
    if (!_isClosing && wasClosing) {
      _closingMaskController.reset();
      _cachedOpenContent = null;
    }
  }

  void _setupAnimations() {
    // 容器展开动画（位置、大小）
    _containerAnimation = CurvedAnimation(
      parent: widget.animation,
      curve: _curveForward,
      reverseCurve: _curveReverse,
    );

    // 新内容淡入动画
    _contentFadeAnimation = CurvedAnimation(
      parent: widget.animation,
      curve: const Interval(_contentFadeStart, 1.0, curve: Curves.easeIn),
      reverseCurve: const Interval(0.0, _contentFadeStart, curve: Curves.easeOut),
    );

    // 关闭内容淡出动画
    _closedFadeAnimation = CurvedAnimation(
      parent: widget.animation,
      curve: const Interval(0.0, _containerExpandEnd, curve: Curves.easeOut),
      reverseCurve: const Interval(
        1.0 - _containerExpandEnd,
        1.0,
        curve: Curves.easeIn,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    final screenSize = MediaQuery.of(context).size;
    final sourceRect = route.sourceRect;

    // 获取主题颜色
    final theme = Theme.of(context);
    final closedColor = route.closedColor ?? theme.cardColor;
    final openColor = route.openColor ?? theme.scaffoldBackgroundColor;

    return AnimatedBuilder(
      animation: Listenable.merge([_containerAnimation, _closingMaskAnimation]),
      builder: (context, child) {
        final t = _containerAnimation.value;
        final maskOpacity = _closingMaskAnimation.value;

        // 计算当前位置和大小
        final currentRect = Rect.lerp(
          sourceRect,
          Rect.fromLTWH(0, 0, screenSize.width, screenSize.height),
          t,
        )!;

        // 计算当前背景色
        final currentColor = Color.lerp(closedColor, openColor, t)!;

        // 计算当前阴影
        final currentElevation = lerpDouble(
          route.closedElevation,
          route.openElevation,
          t,
        );

        // 计算当前形状（圆角）
        final currentShape = ShapeBorder.lerp(
          route.closedShape,
          route.openShape,
          t,
        )!;

        // 构建打开状态的内容
        Widget? openContent;
        if (_contentFadeAnimation.value > 0) {
          // 展开动画进行中或完成，显示实际内容
          _cachedOpenContent ??= route.openBuilder(context);
          // 收缩时内容透明度随遮罩反向变化（遮罩越不透明，内容越透明）
          final contentOpacity = _isClosing
              ? (1.0 - maskOpacity) * _contentFadeAnimation.value
              : _contentFadeAnimation.value;
          if (contentOpacity > 0) {
            openContent = Opacity(
              opacity: contentOpacity.clamp(0.0, 1.0),
              child: _cachedOpenContent,
            );
          }
        }

        return Stack(
          children: [
            // 背景遮罩（整个屏幕的半透明黑色）
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.black.withOpacity(0.3 * t),
                ),
              ),
            ),
            // 容器 - 使用 ClipPath 确保圆角在整个动画过程中清晰可见
            Positioned(
              left: currentRect.left,
              top: currentRect.top,
              width: currentRect.width,
              height: currentRect.height,
              child: PhysicalShape(
                color: currentColor,
                elevation: currentElevation ?? 0,
                shadowColor: Colors.black,
                clipper: ShapeBorderClipper(
                  shape: currentShape,
                  textDirection: Directionality.of(context),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 关闭状态内容（淡出）- 仅在展开时显示
                    if (!_isClosing && _closedFadeAnimation.value > 0)
                      FadeTransition(
                        opacity: ReverseAnimation(_closedFadeAnimation),
                        child: IgnorePointer(
                          child: route.closedBuilder(context),
                        ),
                      ),
                    // 打开状态内容
                    if (openContent != null) openContent,
                    // 收缩遮罩层（渐显覆盖内容）
                    if (_isClosing && maskOpacity > 0)
                      Positioned.fill(
                        child: Container(
                          color: openColor.withOpacity(maskOpacity),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 线性插值辅助函数
double? lerpDouble(double a, double b, double t) {
  return a + (b - a) * t;
}

/// OpenContainer 组件
///
/// 类似 animations 包的 OpenContainer，提供展开/收缩过渡动画。
///
/// 使用示例:
/// ```dart
/// OpenContainer(
///   closedBuilder: (context, openContainer) {
///     return Card(
///       child: ListTile(
///         title: Text('点击展开'),
///         onTap: openContainer,
///       ),
///     );
///   },
///   openBuilder: (context) {
///     return DetailPage();
///   },
/// )
/// ```
class OpenContainer extends StatefulWidget {
  const OpenContainer({
    super.key,
    required this.closedBuilder,
    required this.openBuilder,
    this.closedColor,
    this.openColor,
    this.closedElevation = 1.0,
    this.openElevation = 0.0,
    this.closedShape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12.0)),
    ),
    this.openShape = const RoundedRectangleBorder(),
    this.transitionDuration = const Duration(milliseconds: 300),
    this.onClosed,
    this.useRootNavigator = false,
    this.routeSettings,
  });

  /// 关闭状态的构建器
  ///
  /// [openContainer] 是一个回调函数，调用它可以打开容器
  final Widget Function(BuildContext context, VoidCallback openContainer)
      closedBuilder;

  /// 打开状态的构建器（新页面）
  final WidgetBuilder openBuilder;

  /// 关闭状态的背景色
  final Color? closedColor;

  /// 打开状态的背景色
  final Color? openColor;

  /// 关闭状态的阴影高度
  final double closedElevation;

  /// 打开状态的阴影高度
  final double openElevation;

  /// 关闭状态的形状
  final ShapeBorder closedShape;

  /// 打开状态的形状
  final ShapeBorder openShape;

  /// 过渡动画时长
  final Duration transitionDuration;

  /// 容器关闭时的回调
  final VoidCallback? onClosed;

  /// 是否使用根导航器
  final bool useRootNavigator;

  /// 路由设置
  final RouteSettings? routeSettings;

  @override
  State<OpenContainer> createState() => _OpenContainerState();
}

class _OpenContainerState extends State<OpenContainer> {
  final GlobalKey _closedBuilderKey = GlobalKey();

  /// 获取关闭状态 widget 的全局位置和大小
  Rect _getSourceRect() {
    final renderBox =
        _closedBuilderKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return Rect.zero;
    }
    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);
    return Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
  }

  /// 打开容器
  Future<void> _openContainer() async {
    final sourceRect = _getSourceRect();
    if (sourceRect == Rect.zero) return;

    await Navigator.of(
      context,
      rootNavigator: widget.useRootNavigator,
    ).push<void>(
      OpenContainerRoute<void>(
        sourceRect: sourceRect,
        closedBuilder: (context) => widget.closedBuilder(context, () {}),
        openBuilder: widget.openBuilder,
        closedColor: widget.closedColor,
        openColor: widget.openColor,
        closedElevation: widget.closedElevation,
        openElevation: widget.openElevation,
        closedShape: widget.closedShape,
        openShape: widget.openShape,
        transitionDuration: widget.transitionDuration,
        reverseTransitionDuration: widget.transitionDuration,
        settings: widget.routeSettings,
      ),
    );

    widget.onClosed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _closedBuilderKey,
      child: Material(
        color: widget.closedColor ?? Theme.of(context).cardColor,
        elevation: widget.closedElevation,
        shape: widget.closedShape,
        clipBehavior: Clip.antiAlias,
        child: widget.closedBuilder(context, _openContainer),
      ),
    );
  }
}

/// 用于从外部触发 OpenContainer 动画的辅助方法
///
/// 当无法使用 [OpenContainer] 组件时（例如使用已有的 widget），
/// 可以使用此方法通过 GlobalKey 获取位置并导航。
///
/// 使用示例:
/// ```dart
/// final cardKey = GlobalKey();
///
/// // 在 widget 中
/// Card(
///   key: cardKey,
///   child: Text('点击'),
///   onTap: () => openContainerFromKey(
///     context: context,
///     sourceKey: cardKey,
///     openBuilder: (context) => DetailPage(),
///   ),
/// )
/// ```
Future<T?> openContainerFromKey<T>({
  required BuildContext context,
  required GlobalKey sourceKey,
  required WidgetBuilder openBuilder,
  WidgetBuilder? closedBuilder,
  Color? closedColor,
  Color? openColor,
  double closedElevation = 1.0,
  double openElevation = 0.0,
  ShapeBorder closedShape = const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(12.0)),
  ),
  ShapeBorder openShape = const RoundedRectangleBorder(),
  Duration transitionDuration = const Duration(milliseconds: 300),
  bool useRootNavigator = false,
  RouteSettings? routeSettings,
}) {
  final renderBox =
      sourceKey.currentContext?.findRenderObject() as RenderBox?;
  if (renderBox == null) {
    // 降级为普通导航
    return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
      MaterialPageRoute(builder: openBuilder),
    );
  }

  final size = renderBox.size;
  final position = renderBox.localToGlobal(Offset.zero);
  final sourceRect = Rect.fromLTWH(
    position.dx,
    position.dy,
    size.width,
    size.height,
  );

  return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
    OpenContainerRoute<T>(
      sourceRect: sourceRect,
      closedBuilder: closedBuilder ?? (_) => const SizedBox.shrink(),
      openBuilder: openBuilder,
      closedColor: closedColor,
      openColor: openColor,
      closedElevation: closedElevation,
      openElevation: openElevation,
      closedShape: closedShape,
      openShape: openShape,
      transitionDuration: transitionDuration,
      reverseTransitionDuration: transitionDuration,
      settings: routeSettings,
    ),
  );
}

/// 通过 Rect 直接触发 OpenContainer 动画
///
/// 当已知源位置时使用此方法。
Future<T?> openContainerFromRect<T>({
  required BuildContext context,
  required Rect sourceRect,
  required WidgetBuilder openBuilder,
  WidgetBuilder? closedBuilder,
  Color? closedColor,
  Color? openColor,
  double closedElevation = 1.0,
  double openElevation = 0.0,
  ShapeBorder closedShape = const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(12.0)),
  ),
  ShapeBorder openShape = const RoundedRectangleBorder(),
  Duration transitionDuration = const Duration(milliseconds: 300),
  bool useRootNavigator = false,
  RouteSettings? routeSettings,
}) {
  return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
    OpenContainerRoute<T>(
      sourceRect: sourceRect,
      closedBuilder: closedBuilder ?? (_) => const SizedBox.shrink(),
      openBuilder: openBuilder,
      closedColor: closedColor,
      openColor: openColor,
      closedElevation: closedElevation,
      openElevation: openElevation,
      closedShape: closedShape,
      openShape: openShape,
      transitionDuration: transitionDuration,
      reverseTransitionDuration: transitionDuration,
      settings: routeSettings,
    ),
  );
}

// ==================== iOS 左滑返回手势支持 ====================

/// iOS 左滑返回手势宽度
const double _kBackGestureWidth = 20.0;

/// iOS 左滑返回手势检测器
class _IOSBackGestureDetector<T> extends StatefulWidget {
  const _IOSBackGestureDetector({
    super.key,
    required this.enabledCallback,
    required this.onStartPopGesture,
    required this.child,
  });

  final Widget child;
  final ValueGetter<bool> enabledCallback;
  final ValueGetter<_IOSBackGestureController<T>> onStartPopGesture;

  @override
  State<_IOSBackGestureDetector<T>> createState() =>
      _IOSBackGestureDetectorState<T>();
}

class _IOSBackGestureDetectorState<T>
    extends State<_IOSBackGestureDetector<T>> {
  _IOSBackGestureController<T>? _backGestureController;

  late HorizontalDragGestureRecognizer _recognizer;

  @override
  void initState() {
    super.initState();
    _recognizer = HorizontalDragGestureRecognizer(debugOwner: this)
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _handleDragCancel;
  }

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    _backGestureController = widget.onStartPopGesture();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _backGestureController?.dragUpdate(
      _convertToLogical(details.primaryDelta! / context.size!.width),
    );
  }

  void _handleDragEnd(DragEndDetails details) {
    _backGestureController?.dragEnd(
      _convertToLogical(
        details.velocity.pixelsPerSecond.dx / context.size!.width,
      ),
    );
    _backGestureController = null;
  }

  void _handleDragCancel() {
    _backGestureController?.dragEnd(0.0);
    _backGestureController = null;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (widget.enabledCallback()) {
      _recognizer.addPointer(event);
    }
  }

  double _convertToLogical(double value) {
    switch (Directionality.of(context)) {
      case TextDirection.rtl:
        return -value;
      case TextDirection.ltr:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 检测从左边缘开始的滑动
    double dragAreaWidth = Directionality.of(context) == TextDirection.ltr
        ? MediaQuery.paddingOf(context).left
        : MediaQuery.paddingOf(context).right;
    dragAreaWidth = dragAreaWidth.clamp(_kBackGestureWidth, double.infinity);

    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        widget.child,
        PositionedDirectional(
          start: 0.0,
          width: dragAreaWidth,
          top: 0.0,
          bottom: 0.0,
          child: Listener(
            onPointerDown: _handlePointerDown,
            behavior: HitTestBehavior.translucent,
          ),
        ),
      ],
    );
  }
}

/// iOS 左滑返回手势控制器
class _IOSBackGestureController<T> {
  _IOSBackGestureController({
    required this.navigator,
    required this.controller,
  }) {
    navigator.didStartUserGesture();
  }

  final AnimationController controller;
  final NavigatorState navigator;

  /// 手势拖动更新
  void dragUpdate(double delta) {
    controller.value -= delta;
  }

  /// 手势拖动结束
  void dragEnd(double velocity) {
    // 参考 CupertinoPageRoute 的行为
    const Curve animationCurve = Curves.linearToEaseOut;
    final bool animateForward;

    // 根据速度或位置决定是否完成返回
    if (velocity.abs() >= 1.0) {
      animateForward = velocity <= 0;
    } else {
      animateForward = controller.value > 0.5;
    }

    if (animateForward) {
      // 取消返回，恢复到完全展开状态
      final int droppedPageForwardAnimationTime = lerpDouble(
        0,
        300,
        controller.value,
      )!.floor();
      controller.animateTo(
        1.0,
        duration: Duration(milliseconds: droppedPageForwardAnimationTime),
        curve: animationCurve,
      );
    } else {
      // 完成返回
      navigator.pop();
    }

    navigator.didStopUserGesture();
  }
}
