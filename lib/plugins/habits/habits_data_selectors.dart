part of 'habits_plugin.dart';

/// 注册数据选择器
void _registerDataSelectors() {
  pluginDataSelectorService.registerSelector(SelectorDefinition(
    id: 'habits.habit',
    pluginId: id,
    name: '选择习惯',
    icon: icon,
    color: color,
    searchable: true,
    selectionMode: SelectionMode.single,
    steps: [
      SelectorStep(
        id: 'habit',
        title: '选择习惯',
        viewType: SelectorViewType.list,
        isFinalStep: true,
        dataLoader: (_) async {
          final habits = _habitController.getHabits();
          final List<SelectableItem> items = [];

          for (final habit in habits) {
            // 获取累计时长和完成次数作为副标题
            final duration = await _recordController.getTotalDuration(habit.id);
            final count = await _recordController.getCompletionCount(habit.id);

            items.add(SelectableItem(
              id: habit.id,
              title: habit.title,
              subtitle: '$duration 分钟 · $count 次完成',
              icon: habit.icon != null
                  ? IconData(int.parse(habit.icon!), fontFamily: 'MaterialIcons')
                  : Icons.auto_awesome,
              rawData: habit,
            ));
          }

          return items;
        },
        searchFilter: (items, query) {
          if (query.isEmpty) return items;
          final lowerQuery = query.toLowerCase();
          return items.where((item) =>
            item.title.toLowerCase().contains(lowerQuery) ||
            (item.rawData as Habit).group?.toLowerCase().contains(lowerQuery) == true ||
            (item.rawData as Habit).tags.any((tag) => tag.toLowerCase().contains(lowerQuery))
          ).toList();
        },
      ),
    ],
  ));
}
