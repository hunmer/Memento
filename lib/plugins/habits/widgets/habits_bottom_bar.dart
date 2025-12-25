import 'package:get/get.dart';
import 'package:Memento/plugins/habits/controllers/completion_record_controller.dart';
import 'package:Memento/plugins/habits/controllers/habit_controller.dart';
import 'package:Memento/plugins/habits/controllers/skill_controller.dart';
import 'package:Memento/plugins/habits/widgets/habits_list/habits_view.dart';
import 'package:Memento/plugins/habits/widgets/skills_list.dart';
import 'package:Memento/plugins/habits/widgets/habit_form.dart';
import 'package:Memento/plugins/habits/widgets/skill_form.dart';
import 'package:Memento/plugins/habits/habits_plugin.dart';
import 'package:Memento/core/widgets/keep_alive_wrapper.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/widgets/custom_bottom_bar.dart';

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
  final GlobalKey _bottomBarKey = GlobalKey();
  final GlobalKey _fabKey = GlobalKey();

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

  /// 构建 FAB
  Widget _buildFab() {
    return FloatingActionButton(
      key: _fabKey,
      backgroundColor: widget.plugin.color,
      elevation: 4,
      shape: const CircleBorder(),
      onPressed: () {
        if (_currentPage == 0) {
          NavigationHelper.openContainerWithHero(
            context,
            (context) => Scaffold(
              appBar: AppBar(
                title: Text('habits_newHabit'.tr),
                backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              ),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: HabitForm(
                onSave: (habit) async {
                  await _habitController.saveHabit(habit);
                },
              ),
            ),
            sourceKey: _fabKey,
            heroTag: 'habits_fab_add_habit',
            closedShape: const CircleBorder(),
          );
        } else {
          NavigationHelper.openContainerWithHero(
            context,
            (context) => Scaffold(
              appBar: AppBar(
                title: Text('habits_createSkill'.tr),
                backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              ),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: SkillForm(
                onSave: (skill) async {
                  await _skillController.saveSkill(skill);
                },
              ),
            ),
            sourceKey: _fabKey,
            heroTag: 'habits_fab_add_skill',
            closedShape: const CircleBorder(),
          );
        }
      },
      child: Icon(
        _currentPage == 0 ? Icons.add_task : Icons.add_reaction,
        color: widget.plugin.color.computeLuminance() < 0.5
            ? Colors.white
            : Colors.black,
        size: 32,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomBottomBar(
      colors: _colors,
      currentIndex: _currentPage,
      tabController: _tabController,
      bottomBarKey: _bottomBarKey,
      body: (context, controller) => TabBarView(
        controller: _tabController,
        dragStartBehavior: DragStartBehavior.start,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          KeepAliveWrapper(
            child: CombinedHabitsView(controller: _habitController),
          ),
          KeepAliveWrapper(
            child: SkillsList(
              skillController: _skillController,
              recordController: _recordController,
            ),
          ),
        ],
      ),
      fab: _buildFab(),
      children: [
        Tab(
          icon: Icon(Icons.check_circle),
          text: 'habits_habits'.tr,
        ),
        Tab(
          icon: Icon(Icons.star),
          text: 'habits_skills'.tr,
        ),
      ],
    );
  }
}
