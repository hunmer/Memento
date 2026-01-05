part of 'timer_plugin.dart';

// ==================== 数据选择器注册 ====================

/// 注册插件数据选择器
void _registerDataSelectors() {
  // 注册计时任务选择器
  pluginDataSelectorService.registerSelector(
    SelectorDefinition(
      id: 'timer.task',
      pluginId: TimerPlugin.instance.id,
      name: '选择计时任务',
      icon: TimerPlugin.instance.icon,
      color: TimerPlugin.instance.color,
      searchable: true,
      selectionMode: SelectionMode.single,
      steps: [
        SelectorStep(
          id: 'task',
          title: '选择计时任务',
          viewType: SelectorViewType.list,
          isFinalStep: true,
          dataLoader: (_) async {
            return TimerPlugin.instance._tasks.map((task) {
              // 计算任务总时长
              final totalDuration = task.timerItems.fold<Duration>(
                Duration.zero,
                (sum, item) => sum + item.duration,
              );

              // 格式化时长显示
              String formatDuration(Duration duration) {
                final hours = duration.inHours;
                final minutes = duration.inMinutes.remainder(60);
                final seconds = duration.inSeconds.remainder(60);
                if (hours > 0) {
                  return '$hours小时$minutes分钟';
                } else if (minutes > 0) {
                  return '$minutes分钟$seconds秒';
                } else {
                  return '$seconds秒';
                }
              }

              return SelectableItem(
                id: task.id,
                title: task.name,
                subtitle:
                    '分组: ${task.group} · 时长: ${formatDuration(totalDuration)} · ${task.timerItems.length}个计时器',
                icon: task.icon,
                rawData: task.toJson(),
              );
            }).toList();
          },
          searchFilter: (items, query) {
            if (query.isEmpty) return items;
            final lowerQuery = query.toLowerCase();
            return items.where((item) {
              final task = item.rawData as TimerTask;
              return item.title.toLowerCase().contains(lowerQuery) ||
                  task.group.toLowerCase().contains(lowerQuery);
            }).toList();
          },
        ),
      ],
    ),
  );
}
