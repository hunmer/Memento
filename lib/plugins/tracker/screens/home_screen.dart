import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/plugins/tracker/tracker_plugin.dart';
import 'package:Memento/plugins/tracker/screens/goal_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:Memento/core/services/toast_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String _filterStatus = '全部';
  String _currentGroup = '全部';
  final bool _isGridView = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 分组切换器
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Consumer<TrackerController>(
            builder: (context, controller, child) {
              final groups = ['全部', ...controller.getAllGroups()];
              return ListView.builder(
                padding: EdgeInsets.zero,
                scrollDirection: Axis.horizontal,
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  final isSelected = _currentGroup == group;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(group),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _currentGroup = group);
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
        // 目标列表
        Expanded(child: _buildGoalsList(context)),
      ],
    );
  }

  Widget _buildGoalsList(BuildContext context) {
    final controller = Provider.of<TrackerController>(context);
    final filteredGoals =
        controller.goals.where((goal) {
          if (_currentGroup != '全部' && goal.group != _currentGroup) {
            return false;
          }

          // 根据状态过滤
          if (_filterStatus == '进行中' && goal.isCompleted) return false;
          if (_filterStatus == '已完成' && !goal.isCompleted) return false;

          // 根据日期过滤
          // 这里可以根据需要实现日期过滤逻辑

          return true;
        }).toList();

    if (_isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: filteredGoals.length,
        itemBuilder: (context, index) {
          final goal = filteredGoals[index];
          return GoalCard(
            goal: goal,
            controller: controller,
            onTap: () {
              NavigationHelper.openContainerWithHero(
                context,
                (context) => ChangeNotifierProvider.value(
                  value: controller,
                  child: GoalDetailScreen(goal: goal),
                ),
                closedColor: Theme.of(context).colorScheme.surface,
              );
            },
          );
        },
      );
    }

    return ListView.builder(
      itemCount: filteredGoals.length,
      itemBuilder: (context, index) {
        final goal = filteredGoals[index];
        return Dismissible(
          key: Key(goal.id),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: Text(
                      'tracker_confirmDeletion'.tr,
                    ),
                    content: Text(
                      '${'tracker_confirmDeletion'.tr} "${goal.name}"',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('app_cancel'.tr),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(
                          'app_delete'.tr,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
            );
          },
          onDismissed: (direction) {
            controller.deleteGoal(goal.id);
            Toast.success(
              '${'tracker_goalDeleted'.tr} "${goal.name}"',
            );
          },
          child: GoalCard(
            goal: goal,
            controller: controller,
            onTap: () {
              NavigationHelper.openContainerWithHero(
                context,
                (context) => ChangeNotifierProvider.value(
                  value: controller,
                  child: GoalDetailScreen(goal: goal),
                ),
                closedColor: Theme.of(context).colorScheme.surface,
              );
            },
          ),
        );
      },
    );
  }

}
