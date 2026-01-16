part of 'activity_plugin.dart';

/// 注册数据选择器
void _registerDataSelectors() {
  // 1. 活动记录选择器
  pluginDataSelectorService.registerSelector(
    SelectorDefinition(
      id: 'activity.record',
      pluginId: ActivityPlugin.instance.id,
      name: '选择活动记录',
      icon: ActivityPlugin.instance.icon,
      color: ActivityPlugin.instance.color,
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
            final activities = await ActivityPlugin.instance.activityService.getActivitiesForDate(now);

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

  // 2. 热力图时间粒度选择器
  pluginDataSelectorService.registerSelector(
    SelectorDefinition(
      id: 'activity.heatmap_granularity',
      pluginId: ActivityPlugin.instance.id,
      name: '选择时间粒度',
      icon: Icons.grid_on,
      color: ActivityPlugin.instance.color,
      searchable: false,
      selectionMode: SelectionMode.single,
      steps: [
        SelectorStep(
          id: 'granularity',
          title: '选择时间粒度',
          viewType: SelectorViewType.list,
          isFinalStep: true,
          dataLoader: (_) async {
            return [
              SelectableItem(
                id: '5',
                title: '5分钟（超密集）',
                subtitle: '显示288个时间槽，极度详细',
                icon: Icons.grid_on,
                rawData: 5,
              ),
              SelectableItem(
                id: '10',
                title: '10分钟（很密集）',
                subtitle: '显示144个时间槽，非常详细',
                icon: Icons.blur_on,
                rawData: 10,
              ),
              SelectableItem(
                id: '15',
                title: '15分钟（密集）',
                subtitle: '显示96个时间槽，适合详细查看',
                icon: Icons.view_module,
                rawData: 15,
              ),
              SelectableItem(
                id: '30',
                title: '30分钟（中等）',
                subtitle: '显示48个时间槽，平衡显示',
                icon: Icons.dashboard,
                rawData: 30,
              ),
              SelectableItem(
                id: '60',
                title: '60分钟（简洁）',
                subtitle: '显示24个时间槽，简洁明了',
                icon: Icons.apps,
                rawData: 60,
              ),
            ];
          },
        ),
      ],
    ),
  );

  // 3. 活动标签选择器（用于小组件配置）
  pluginDataSelectorService.registerSelector(
    SelectorDefinition(
      id: 'activity.tag',
      pluginId: ActivityPlugin.instance.id,
      name: '选择活动标签',
      icon: Icons.tag,
      color: ActivityPlugin.instance.color,
      searchable: true,
      selectionMode: SelectionMode.single,
      steps: [
        SelectorStep(
          id: 'tag',
          title: '选择标签',
          viewType: SelectorViewType.list,
          isFinalStep: true,
          dataLoader: (_) async {
            // 获取最近使用的标签
            final recentTags = await ActivityPlugin.instance.activityService.getRecentTags();

            // 获取标签分组
            final tagGroups = await ActivityPlugin.instance.activityService.getTagGroups();

            // 收集所有唯一标签
            final allTags = <String>{};

            // 添加最近使用的标签
            allTags.addAll(recentTags);

            // 从标签组收集标签
            for (final group in tagGroups) {
              allTags.addAll(group.tags.map((t) => t.name));
            }

            // 如果没有标签，返回提示
            if (allTags.isEmpty) {
              return [
                SelectableItem(
                  id: 'no_tags',
                  title: '暂无标签',
                  subtitle: '请先创建活动并添加标签',
                  icon: Icons.info_outline,
                  color: Colors.grey,
                  rawData: null,
                  selectable: false,
                ),
              ];
            }

            // 生成可选标签列表
            return allTags.map((tag) {
              final isRecent = recentTags.contains(tag);
              return SelectableItem(
                id: tag,
                title: tag,
                subtitle: isRecent ? '最近使用' : '标签',
                icon: Icons.label,
                color: _getColorFromTag(tag),
                rawData: {'tag': tag},
              );
            }).toList();
          },
          searchFilter: (items, query) {
            if (query.isEmpty) return items;
            final lowerQuery = query.toLowerCase();
            return items.where((item) {
              return item.title.toLowerCase().contains(lowerQuery);
            }).toList();
          },
        ),
      ],
    ),
  );
}

/// 从标签生成颜色
Color _getColorFromTag(String tag) {
  final baseHue = (tag.hashCode % 360).abs().toDouble();
  return HSLColor.fromAHSL(1.0, baseHue, 0.6, 0.5).toColor();
}
