
import 'package:Memento/core/plugin_manager.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/tracker/controllers/tracker_controller.dart';
import 'package:Memento/plugins/tracker/widgets/goal_card.dart';
import 'package:Memento/plugins/tracker/widgets/goal_edit_page.dart';
import 'package:Memento/plugins/tracker/screens/goal_detail_screen.dart';
import 'package:Memento/plugins/tracker/models/goal.dart';
import 'package:Memento/plugins/tracker/tracker_plugin.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _filterStatus = '全部';
  String _filterDate = '最近';

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TrackerController>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('目标跟踪'),
         leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => PluginManager.toHomeScreen(context),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _filterStatus = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: '全部', child: Text('全部')),
              const PopupMenuItem(value: '进行中', child: Text('进行中')),
              const PopupMenuItem(value: '已完成', child: Text('已完成')),
            ],
            icon: const Icon(Icons.filter_list),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _filterDate = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: '最近', child: Text('最近')),
              const PopupMenuItem(value: '本周', child: Text('本周')),
              const PopupMenuItem(value: '本月', child: Text('本月')),
            ],
            icon: const Icon(Icons.calendar_today),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: controller.goals.length,
        itemBuilder: (context, index) {
          final goal = controller.goals[index];
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
                builder: (context) => AlertDialog(
                  title: const Text('确认删除'),
                  content: Text('确定要删除目标"${goal.name}"吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('删除', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
            onDismissed: (direction) {
              controller.deleteGoal(goal.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已删除目标"${goal.name}"')),
              );
            },
            child: GoalCard(
              goal: goal,
              controller: controller,
              onTap: () => TrackerPlugin.instance.openGoalDetail(context, goal),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGoalDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEditGoalDialog(BuildContext context, Goal goal) {
    final controller = Provider.of<TrackerController>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => GoalEditPage(
        controller: controller,
        goal: goal,
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context) {
    final controller = Provider.of<TrackerController>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => GoalEditPage(
        controller: controller,
      ),
    );
  }
}
