import 'package:Memento/plugins/habits/controllers/completion_record_controller.dart';
import 'package:Memento/plugins/habits/controllers/habit_controller.dart';
import 'package:Memento/plugins/habits/controllers/skill_controller.dart';
import 'package:Memento/plugins/habits/widgets/habits_list/habits_view.dart';
import 'package:Memento/plugins/habits/widgets/skills_list.dart';
import 'package:Memento/plugins/habits/widgets/habit_form.dart';
import 'package:Memento/plugins/habits/widgets/skill_form.dart';
import 'package:Memento/plugins/habits/l10n/habits_localizations.dart';
import 'package:Memento/plugins/habits/habits_plugin.dart';
import 'package:Memento/core/widgets/keep_alive_wrapper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

/// Habits 插件的底部栏组件
/// 提供习惯列表和技能列表两个 Tab 的切换功能
class HabitsBottomBar extends StatefulWidget {
  final HabitsPlugin plugin;

  const HabitsBottomBar({super.key, required this.plugin});

  @override
  State<HabitsBottomBar> createState() => _HabitsBottomBarState();
}

class _HabitsBottomBarState extends State<HabitsBottomBar>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _currentPage;
  double _bottomBarHeight = 60; // 默认底部栏高度
  final GlobalKey _bottomBarKey = GlobalKey();

  // 使用插件主题色和辅助色
  final List<Color> _colors = [
    Colors.amber, // Tab0 - 习惯列表 (插件主色)
    Colors.orange.shade600, // Tab1 - 技能列表
  ];

  late final HabitController _habitController;
  late final SkillController _skillController;
  late final CompletionRecordController _recordController;

  @override
  void initState() {
    super.initState();
    _currentPage = 0;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.animation?.addListener(() {
      final value = _tabController.animation!.value.round();
      if (value != _currentPage && mounted) {
        setState(() {
          _currentPage = value;
        });
      }
    });

    // 获取控制器
    _habitController = widget.plugin.getHabitController();
    _skillController = widget.plugin.getSkillController();
    _recordController = widget.plugin.getRecordController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 调度底部栏高度测量
  void _scheduleBottomBarHeightMeasurement() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _bottomBarKey.currentContext != null) {
        final RenderBox renderBox =
            _bottomBarKey.currentContext!.findRenderObject() as RenderBox;
        final newHeight = renderBox.size.height;
        if (_bottomBarHeight != newHeight) {
          setState(() {
            _bottomBarHeight = newHeight;
          });
        }
      }
    });
  }

  /// 添加习惯
  Future<void> _addHabit() async {
    final l10n = HabitsLocalizations.of(context);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              appBar: AppBar(
                title: Text(l10n.newHabit),
                backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              ),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: HabitForm(
                onSave: (habit) async {
                  await _habitController.saveHabit(habit);
                },
              ),
            ),
      ),
    );
  }

  /// 添加技能
  Future<void> _addSkill() async {
    final l10n = HabitsLocalizations.of(context);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              appBar: AppBar(
                title: Text(l10n.createSkill),
                backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              ),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: SkillForm(
                onSave: (skill) async {
                  await _skillController.saveSkill(skill);
                },
              ),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _scheduleBottomBarHeightMeasurement();
    final theme = Theme.of(context);
    final Color unselectedColor =
        theme.brightness == Brightness.dark
            ? Colors.white.withOpacity(0.6)
            : Colors.black.withOpacity(0.6);
    final Color bottomAreaColor = Theme.of(context).scaffoldBackgroundColor;

    return BottomBar(
      fit: StackFit.expand,
      icon:
          (width, height) => Center(
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                // 滚动到顶部功能
                if (_tabController.indexIsChanging) return;

                // 切换到第一个tab
                if (_currentPage != 0) {
                  _tabController.animateTo(0);
                }
              },
              icon: Icon(
                Icons.keyboard_arrow_up,
                color: _colors[_currentPage],
                size: width,
              ),
            ),
          ),
      borderRadius: BorderRadius.circular(25),
      duration: const Duration(milliseconds: 300),
      curve: Curves.decelerate,
      showIcon: true,
      width: MediaQuery.of(context).size.width * 0.85,
      barColor:
          Theme.of(context).bottomAppBarTheme.color ??
          Theme.of(context).scaffoldBackgroundColor,
      start: 2,
      end: 0,
      offset: 12,
      barAlignment: Alignment.bottomCenter,
      iconHeight: 35,
      iconWidth: 35,
      reverse: false,
      barDecoration: BoxDecoration(
        color: _colors[_currentPage].withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: _colors[_currentPage].withOpacity(0.3),
          width: 1,
        ),
      ),
      iconDecoration: BoxDecoration(
        color: _colors[_currentPage].withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _colors[_currentPage].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      hideOnScroll:
          !kIsWeb &&
          defaultTargetPlatform != TargetPlatform.macOS &&
          defaultTargetPlatform != TargetPlatform.windows &&
          defaultTargetPlatform != TargetPlatform.linux,
      scrollOpposite: false,
      onBottomBarHidden: () {},
      onBottomBarShown: () {},
      body:
          (context, controller) => Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(bottom: _bottomBarHeight),
                  child: TabBarView(
                    controller: _tabController,
                    dragStartBehavior: DragStartBehavior.start,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // Tab0: 习惯列表
                      KeepAliveWrapper(
                        child: CombinedHabitsView(controller: _habitController),
                      ),
                      // Tab1: 技能列表
                      KeepAliveWrapper(
                        child: SkillsList(
                          skillController: _skillController,
                          recordController: _recordController,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: _bottomBarHeight,
                  color: bottomAreaColor,
                ),
              )
            ],
          ),
      child: Stack(
        key: _bottomBarKey,
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          TabBar(
            controller: _tabController,
            dividerColor: Colors.transparent,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            indicatorPadding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(
                color:
                    _currentPage < 2 ? _colors[_currentPage] : unselectedColor,
                width: 4,
              ),
              insets: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            ),
            labelColor:
                _currentPage < 2 ? _colors[_currentPage] : unselectedColor,
            unselectedLabelColor: unselectedColor,
            tabs: [
              Tab(
                icon: Icon(Icons.check_circle),
                text: HabitsLocalizations.of(context).habits,
              ),
              Tab(
                icon: Icon(Icons.star),
                text: HabitsLocalizations.of(context).skills,
              ),
            ],
          ),
          Positioned(
            top: -25,
            child: FloatingActionButton(
              backgroundColor: widget.plugin.color, // 使用插件主题色
              elevation: 4,
              shape: const CircleBorder(),
              child: Icon(
                _currentPage == 0 ? Icons.add_task : Icons.add_reaction,
                color: Colors.white,
                size: 32,
              ),
              onPressed: () {
                if (_currentPage == 0) {
                  // Tab0: 添加习惯
                  _addHabit();
                } else {
                  // Tab1: 添加技能
                  _addSkill();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
