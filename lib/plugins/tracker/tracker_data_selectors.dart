part of 'tracker_plugin.dart';

/// 注册数据选择器
void _registerDataSelectors() {
  pluginDataSelectorService.registerSelector(
    SelectorDefinition(
      id: 'tracker.goal',
      pluginId: id,
      name: '选择追踪目标',
      icon: icon,
      color: color,
      searchable: true,
      selectionMode: SelectionMode.single,
      steps: [
        SelectorStep(
          id: 'goal',
          title: '选择目标',
          viewType: SelectorViewType.list,
          isFinalStep: true,
          dataLoader: (_) async {
            final goals = await _controller.getAllGoals();
            return goals.map((goal) {
              // 构建副标题：显示进度和分组信息
              final progress = _controller.calculateProgress(goal);
              final progressText =
                  '${(progress * 100).toStringAsFixed(1)}% (${goal.currentValue}/${goal.targetValue} ${goal.unitType})';
              final subtitle = '${goal.group} • $progressText';

              return SelectableItem(
                id: goal.id,
                title: goal.name,
                subtitle: subtitle,
                icon: Icons.track_changes,
                rawData: goal,
              );
            }).toList();
          },
          searchFilter: (items, query) {
            if (query.isEmpty) return items;
            final lowerQuery = query.toLowerCase();
            return items.where((item) {
              final goal = item.rawData as Goal;
              return item.title.toLowerCase().contains(lowerQuery) ||
                  goal.group.toLowerCase().contains(lowerQuery) ||
                  goal.unitType.toLowerCase().contains(lowerQuery);
            }).toList();
          },
        ),
      ],
    ),
  );
}
