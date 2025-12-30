import 'package:flutter/material.dart';
import 'package:Memento/core/global_flags.dart';
import 'home_screen_controller.dart';
import 'home_screen_view.dart';

/// 主屏幕入口
///
/// 组合控制器和视图，遵循分离关注点原则
/// - HomeScreenController: 状态管理和业务逻辑
/// - HomeScreenView: UI 构建
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware, TickerProviderStateMixin {
  final HomeScreenController _controller = HomeScreenController();
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _controller.init(_onStateChanged);

    // 等待布局加载完成后创建 TabController
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _controller.initializeLayout();
      if (!mounted) return;

      // 创建 TabController
      if (_controller.savedLayouts.isNotEmpty) {
        _tabController = TabController(
          length: _controller.savedLayouts.length,
          vsync: this,
          initialIndex: _controller.currentPageIndex,
        );
        _tabController!.addListener(() => _onTabChanged());
      }

      // 显示悬浮球
      // FloatingBallService().show(context);

      // 首次加载时打开最后使用的插件
      if (!_controller.triedToOpenPlugin && !_controller.launchedWithParameters) {
        _controller.tryOpenLastUsedPlugin();
      }
    });
  }

  void _onTabChanged() {
    if (_tabController != null && _tabController!.index != _controller.currentPageIndex) {
      _controller.onPageChanged(_tabController!.index, _onStateChanged);
    }
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
      // TabController 索引同步
      if (_tabController != null && _tabController!.index != _controller.currentPageIndex) {
        _tabController!.animateTo(_controller.currentPageIndex);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_controller.launchedWithParameters) {
      _controller.checkLaunchParameters();
    }
    if (isLaunchedFromWidget) {
      isLaunchedFromWidget = false;
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _controller.cleanup(_onStateChanged);
    super.dispose();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    _onStateChanged();
  }

  @override
  Widget build(BuildContext context) {
    return HomeScreenView(
      controller: _controller,
      tabController: _tabController,
    );
  }
}
