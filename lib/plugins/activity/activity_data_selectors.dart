part of 'activity_plugin.dart';

/// 注册数据选择器
void _registerDataSelectors() {
  pluginDataSelectorService.registerSelector(
    SelectorDefinition(
      id: 'activity.record',
      pluginId: id,
      name: '选择活动记录',
      icon: icon,
      color: color,
      searchable: true,
      selectionMode: SelectionMode.single,
      steps: [
        SelectorStep(
          id: 'record',
          title: '选择活动记录',
          viewType: SelectorViewType.list,
          isFinalStep: true,
          dataLoader: (_) async {
            // 获取今天的活动记录
            final now = DateTime.now();
            final activities = await _activityService.getActivitiesForDate(now);

            return activities.map((activity) {
              // 格式化时间显示
              final startTime = '${activity.startTime.hour.toString().padLeft(2, '0')}:${activity.startTime.minute.toString().padLeft(2, '0')}';
              final endTime = '${activity.endTime.hour.toString().padLeft(2, '0')}:${activity.endTime.minute.toString().padLeft(2, '0')}';
              final timeRange = '$startTime - $endTime';

              // 构建副标题: 时间范围 + 标签
              final subtitle = activity.tags.isNotEmpty
                  ? '$timeRange · ${activity.tags.join(', ')}'
                  : timeRange;

              return SelectableItem(
                id: activity.id,
                title: activity.title,
                subtitle: subtitle,
                icon: Icons.timeline,
                rawData: activity,
              );
            }).toList();
          },
          searchFilter: (items, query) {
            if (query.isEmpty) return items;
            final lowerQuery = query.toLowerCase();
            return items.where((item) {
              final activity = item.rawData as ActivityRecord;
              // 搜索标题、标签和描述
              return item.title.toLowerCase().contains(lowerQuery) ||
                  activity.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)) ||
                  (activity.description?.toLowerCase().contains(lowerQuery) ?? false);
            }).toList();
          },
        ),
      ],
    ),
  );
}
