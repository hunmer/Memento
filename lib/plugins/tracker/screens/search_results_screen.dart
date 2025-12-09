import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Memento/plugins/tracker/tracker_plugin.dart';

import 'package:get/get.dart';
class SearchResultsScreen extends StatefulWidget {
  final String searchQuery;

  const SearchResultsScreen({
    super.key,
    required this.searchQuery,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<TrackerController>(
      builder: (context, controller, child) {
        final filteredGoals = _filterGoals(controller.goals, widget.searchQuery);

        if (widget.searchQuery.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  '输入关键词搜索目标',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        if (filteredGoals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '未找到相关目标',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '尝试使用其他关键词',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: filteredGoals.length,
          itemBuilder: (context, index) {
            final goal = filteredGoals[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: _buildGoalIcon(goal),
                ),
                title: Text(
                  goal.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${goal.group} • ${goal.currentValue.toStringAsFixed(0)}/${goal.targetValue} ${goal.unitType}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Icon(
                  goal.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: goal.isCompleted ? Colors.green : Colors.grey,
                ),
                onTap: () => TrackerPlugin.instance.openGoalDetail(context, goal),
              ),
            );
          },
        );
      },
    );
  }

  List<Goal> _filterGoals(List<Goal> goals, String query) {
    if (query.isEmpty) return goals;

    final lowercaseQuery = query.toLowerCase();

    return goals.where((goal) {
      // 搜索目标名称
      if (goal.name.toLowerCase().contains(lowercaseQuery)) {
        return true;
      }

      // 搜索分组名称
      if (goal.group.toLowerCase().contains(lowercaseQuery)) {
        return true;
      }

      // 搜索单位类型
      if (goal.unitType.toLowerCase().contains(lowercaseQuery)) {
        return true;
      }

      return false;
    }).toList();
  }

  Widget _buildGoalIcon(Goal goal) {
    // 尝试解析图标代码点，使用 IconData 显示
    try {
      final codePoint = int.tryParse(goal.icon);
      if (codePoint != null) {
        return Icon(
          IconData(codePoint, fontFamily: 'MaterialIcons'),
          size: 20,
          color: Theme.of(context).primaryColor,
        );
      }
    } catch (e) {
      // 图标解析失败，使用默认图标
    }
    // 默认图标
    return const Icon(
      Icons.track_changes,
      size: 20,
      color: Colors.grey,
    );
  }
}
