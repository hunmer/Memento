
import 'package:flutter/material.dart';
import 'package:Memento/plugins/tracker/tracker_plugin.dart';
import 'package:Memento/plugins/tracker/widgets/goal_card.dart';
import 'package:Memento/plugins/tracker/models/goal.dart';
import 'package:Memento/plugins/tracker/controllers/tracker_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TrackerController _controller = TrackerPlugin.instance.controller;
  List<Goal> _goals = [];
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final goals = await _controller.getAllGoals();
    setState(() {
      _goals = goals;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = _controller.calculateOverallProgress();
    final filteredGoals = _goals.where((goal) {
      switch (_filter) {
        case 'active':
          return !goal.isCompleted;
        case 'completed':
          return goal.isCompleted;
        default:
          return true;
      }
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('目标跟踪'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _filter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('全部')),
              const PopupMenuItem(value: 'active', child: Text('进行中')),
              const PopupMenuItem(value: 'completed', child: Text('已完成')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: LinearProgressIndicator(
              value: progress,
              semanticsLabel: '目标完成进度',
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredGoals.length,
              itemBuilder: (context, index) {
                final goal = filteredGoals[index];
                return GoalCard(
                  goal: goal,
                  controller: _controller,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GoalEditPage(
                        controller: _controller,
                        goal: goal,
                      ),
                      ),
                    );
                    _loadGoals(); // 刷新目标列表
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GoalEditPage(
              controller: _controller,
              goal: null,
            ),
            ),
          );
          _loadGoals(); // 刷新目标列表
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
