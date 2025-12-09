import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:flutter/gestures.dart';
import 'package:Memento/core/plugin_base.dart';
import 'package:get/get.dart';

/// 插件覆盖层窗口组件
/// 用于在应用内显示插件的独立小窗口，支持路由隔离、拖动和最小化
class PluginOverlayWidget extends StatefulWidget {
  final PluginBase plugin;
  final VoidCallback? onClose;
  final VoidCallback? onMinimize;

  const PluginOverlayWidget({
    super.key,
    required this.plugin,
    this.onClose,
    this.onMinimize,
  });

  @override
  State<PluginOverlayWidget> createState() => _PluginOverlayWidgetState();
}

class _PluginOverlayWidgetState extends State<PluginOverlayWidget>
    with SingleTickerProviderStateMixin {
  static const double _minSize = 300;
  static const double _maxSize = 600;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // 窗口尺寸和位置
  late double _windowWidth;
  late double _windowHeight;
  Offset _position = Offset.zero;

  // 拖动相关
  bool _isHeaderDragging = false; // header拖动状态
  bool _canDrag = false; // 是否可以拖动
  Offset? _lastHeaderDragUpdate; // 最后一次header拖动更新的位置

  // 初始化状态标记
  bool _isInitialized = false;

  /// 获取当前窗口宽度，如果未初始化则返回默认值
  double get _currentWindowWidth {
    if (_isInitialized) return _windowWidth;
    return MediaQuery.of(context).size.width * 0.8;
  }

  /// 获取当前窗口高度，如果未初始化则返回默认值
  double get _currentWindowHeight {
    if (_isInitialized) return _windowHeight;
    return MediaQuery.of(context).size.height * 0.8;
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    // 延迟到下一帧调用，确保context已经准备好
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeWindow();
        _animationController.forward();
      }
    });
  }

  void _initializeWindow() {
    if (_isInitialized) return; // 避免重复初始化

    final screenSize = MediaQuery.of(context).size;
    _windowWidth = (screenSize.width * 0.8).clamp(_minSize, _maxSize);
    _windowHeight = (screenSize.height * 0.8).clamp(_minSize, _maxSize);

    // 初始位置居中
    _position = Offset(
      (screenSize.width - _windowWidth) / 2,
      (screenSize.height - _windowHeight) / 2,
    );

    _isInitialized = true;

    // 强制更新UI
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleClose() {
    _animationController.reverse().then((_) {
      if (mounted) {
        widget.onClose?.call();
      }
    });
  }

  /// Header长按开始（桌面端拖动支持）
  void _handleHeaderLongPressDown(LongPressDownDetails details) {
    _isHeaderDragging = true;
    _canDrag = true;
    _lastHeaderDragUpdate = details.globalPosition;
  }

  /// Header长按拖动更新（桌面端拖动支持）
  void _handleHeaderLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!_canDrag || !_isHeaderDragging) return;

    // 计算拖动的偏移量
    final delta = details.globalPosition - (_lastHeaderDragUpdate ?? details.globalPosition);
    _lastHeaderDragUpdate = details.globalPosition;

    // 获取屏幕大小
    final screenSize = MediaQuery.of(context).size;

    // 计算新位置，并确保在屏幕范围内
    final newPosition = Offset(
      (_position.dx + delta.dx).clamp(0, screenSize.width - _currentWindowWidth),
      (_position.dy + delta.dy).clamp(0, screenSize.height - _currentWindowHeight),
    );

    setState(() {
      _position = newPosition;
    });
  }

  /// Header长按拖动结束（桌面端拖动支持）
  void _handleHeaderLongPressEnd(LongPressEndDetails details) {
    _isHeaderDragging = false;
    _canDrag = false;
    _lastHeaderDragUpdate = null;
  }

  /// 处理最小化
  void _handleMinimize() {
    _animationController.reverse().then((_) {
      if (mounted) {
        widget.onMinimize?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          children: [
            // 半透明背景
            Positioned.fill(
              child: Container(
                color: Colors.black54,
              ),
            ),
            // 可拖动的窗口
            Positioned(
              left: _position.dx,
              top: _position.dy,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Container(
                    width: _currentWindowWidth,
                    height: _currentWindowHeight,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        children: [
                          _buildHeader(),
                          _buildContent(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.plugin.icon ?? Icons.extension,
            size: 20,
            color: widget.plugin.color ?? Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          // 可拖拽的标题区域
          Expanded(
            child: GestureDetector(
              // 桌面端和移动端都使用长按拖动
              onLongPressDown: _handleHeaderLongPressDown,
              onLongPressMoveUpdate: _handleHeaderLongPressMoveUpdate,
              onLongPressEnd: _handleHeaderLongPressEnd,
              behavior: HitTestBehavior.translucent, // 确保能接收手势事件
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.transparent, // 添加透明边框增大点击区域
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    // 拖动图标提示
                    Icon(
                      Icons.drag_indicator,
                      size: 16,
                      color: Theme.of(context).primaryColor.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.plugin.getPluginName(context) ?? widget.plugin.id,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 最小化按钮
          IconButton(
            onPressed: _handleMinimize,
            icon: const Icon(Icons.minimize),
            iconSize: 20,
            tooltip: '最小化',
          ),
          // 关闭按钮
          IconButton(
            onPressed: _handleClose,
            icon: const Icon(Icons.close),
            iconSize: 20,
            tooltip: '关闭',
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Expanded(
      child: Navigator(
        onGenerateRoute: _onGenerateRoute,
        observers: [_navigationObserver],
      ),
    );
  }

  /// 路由生成器
  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
      case null:
        return NavigationHelper.createRoute(
          _PluginMainView(plugin: widget.plugin),
        );
      default:
        // 如果是插件内部的路由，返回错误页面
        return NavigationHelper.createRoute(Scaffold(
            appBar: AppBar(title: Text('core_routeError'.tr)),
            body: Center(
              child: Text('core_routeNotFound'.trParams({'route': settings.name ?? ''})),
            ),
          ),);
    }
  }

  /// 导航观察器，用于跟踪插件内的路由变化
  final _navigationObserver = _PluginNavigatorObserver();
}

/// 插件小窗口导航观察器
/// 用于监控插件内的路由变化，确保路由隔离
class _PluginNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    debugPrint('Plugin小窗口路由入栈: ${route.settings.name}');
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    debugPrint('Plugin小窗口路由出栈: ${route.settings.name}');
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    debugPrint('Plugin小窗口路由替换: ${oldRoute?.settings.name} -> ${newRoute?.settings.name}');
  }
}

/// 插件主视图组件
/// 用于在小窗口内显示插件的主要内容
/// 注意：这个组件在小窗口的独立Navigator中运行
class _PluginMainView extends StatelessWidget {
  final PluginBase plugin;

  const _PluginMainView({
    required this.plugin,
  });

  @override
  Widget build(BuildContext context) {
    // 确保插件内容在小窗口的Navigator上下文中运行
    return Scaffold(
      body: plugin.buildMainView(context),
    );
  }
}