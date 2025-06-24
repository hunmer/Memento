import 'package:Memento/core/plugin_manager.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/tracker/tracker_plugin.dart';
import 'package:provider/provider.dart';
import 'package:Memento/l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _filterStatus = '全部';
  String _currentGroup = '全部';
  bool _isGridView = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(TrackerLocalizations.of(context)!.goalTracking),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => PluginManager.toHomeScreen(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _filterStatus = value),
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: '全部',
                    child: Text(TrackerLocalizations.of(context)!.all),
                  ),
                  PopupMenuItem(
                    value: '进行中',
                    child: Text(TrackerLocalizations.of(context)!.inProgress),
                  ),
                  PopupMenuItem(
                    value: '已完成',
                    child: Text(TrackerLocalizations.of(context)!.completed),
                  ),
                ],
            icon: const Icon(Icons.filter_list),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => {}),
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: '最近',
                    child: Text(TrackerLocalizations.of(context)!.recent),
                  ),
                  PopupMenuItem(
                    value: '本周',
                    child: Text(TrackerLocalizations.of(context)!.thisWeek),
                  ),
                  PopupMenuItem(
                    value: '本月',
                    child: Text(TrackerLocalizations.of(context)!.thisMonth),
                  ),
                ],
            icon: const Icon(Icons.calendar_today),
          ),
        ],
      ),
      body: Column(
        children: [
          // 分组切换器
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Consumer<TrackerController>(
              builder: (context, controller, child) {
                final groups = ['全部', ...controller.getAllGroups()];
                return ListView.builder(
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGoalDialog(context),
        child: const Icon(Icons.add),
      ),
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
            onTap: () => TrackerPlugin.instance.openGoalDetail(context, goal),
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
                      TrackerLocalizations.of(context)!.confirmDeletion,
                    ),
                    content: Text(
                      '${TrackerLocalizations.of(context)!.confirmDeletion} "${goal.name}"',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(AppLocalizations.of(context)!.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(
                          AppLocalizations.of(context)!.delete,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
            );
          },
          onDismissed: (direction) {
            controller.deleteGoal(goal.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${TrackerLocalizations.of(context)!.goalDeleted} "${goal.name}"',
                ),
              ),
            );
          },
          child: GoalCard(
            goal: goal,
            controller: controller,
            onTap: () => TrackerPlugin.instance.openGoalDetail(context, goal),
          ),
        );
      },
    );
  }

  void _showAddGoalDialog(BuildContext context) {
    final controller = Provider.of<TrackerController>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => GoalEditPage(controller: controller),
    );
  }
}
