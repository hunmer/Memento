part of 'diary_plugin.dart';

  /// 注册日记数据选择器
  void _registerDataSelectors() {
    // 日记条目选择器 - 使用日历视图
    pluginDataSelectorService.registerSelector(SelectorDefinition(
      id: 'diary.entry',
      pluginId: id,
      name: '选择日记',
      icon: icon,
      color: color,
      searchable: true,
      selectionMode: SelectionMode.single,
      steps: [
        SelectorStep(
          id: 'entry',
          title: '选择日期',
          viewType: SelectorViewType.calendar,
          isFinalStep: true,
          dataLoader: (_) async {
            final entries = await DiaryUtils.loadDiaryEntries();
            return entries.entries.map((e) {
              final entry = e.value;
              return SelectableItem(
                id: DateFormat('yyyy-MM-dd').format(e.key),
                title: entry.title.isNotEmpty
                    ? entry.title
                    : DateFormat('yyyy-MM-dd').format(e.key),
                subtitle: entry.content.length > 50
                    ? '${entry.content.substring(0, 50)}...'
                    : entry.content,
                icon: Icons.article,
                color: color,
                rawData: entry,
                metadata: {
                  'date': e.key,
                  'mood': entry.mood,
                  'wordCount': entry.content.length,
                },
              );
            }).toList();
          },
          searchFilter: (items, query) {
            if (query.isEmpty) return items;
            final lowerQuery = query.toLowerCase();
            return items.where((item) {
              final entry = item.rawData as DiaryEntry;
              return item.title.toLowerCase().contains(lowerQuery) ||
                  entry.content.toLowerCase().contains(lowerQuery) ||
                  (entry.mood?.contains(query) ?? false);
            }).toList();
          },
        ),
      ],
    ));
  }
