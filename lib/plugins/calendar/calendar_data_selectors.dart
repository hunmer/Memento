part of 'calendar_plugin.dart';

// ==================== 数据选择器注册 ====================

void _registerDataSelectors() {
  pluginDataSelectorService.registerSelector(
    SelectorDefinition(
      id: 'calendar.event',
      pluginId: CalendarPlugin.instance.id,
      name: '选择日历事件',
      icon: CalendarPlugin.instance.icon,
      color: CalendarPlugin.instance.color,
      searchable: true,
      selectionMode: SelectionMode.single,
      steps: [
        SelectorStep(
          id: 'event',
          title: '选择日历事件',
          viewType: SelectorViewType.calendar,
          isFinalStep: true,
          dataLoader: (_) async {
            final events = CalendarPlugin.instance.controller.getAllEvents();
            return events.map((event) {
              return SelectableItem(
                id: event.id,
                title: event.title,
                subtitle:
                    event.description.isNotEmpty ? event.description : null,
                icon: event.icon,
                rawData: event,
                metadata: {
                  'date': event.startTime.toIso8601String(),
                  'endTime': event.endTime?.toIso8601String(),
                  'source': event.source,
                  'color': event.color.value,
                },
              );
            }).toList();
          },
        ),
      ],
    ),
  );
}
