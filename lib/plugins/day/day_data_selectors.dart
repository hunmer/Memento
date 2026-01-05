part of 'day_plugin.dart';

  // ==================== 数据选择器注册 ====================

  void _registerDataSelectors() {
    // 纪念日选择器
    pluginDataSelectorService.registerSelector(SelectorDefinition(
      id: 'day.memorial',
      pluginId: id,
      name: '选择纪念日',
      icon: icon,
      color: color,
      searchable: true,
      selectionMode: SelectionMode.single,
      steps: [
        SelectorStep(
          id: 'memorial',
          title: '选择纪念日',
          viewType: SelectorViewType.list,
          isFinalStep: true,
          dataLoader: (_) async {
            return _controller.memorialDays.map((day) {
              // 计算倒计时文本
              String subtitle;
              if (day.isToday) {
                subtitle = '今天';
              } else if (day.daysRemaining > 0) {
                subtitle = '剩余 ${day.daysRemaining} 天';
              } else {
                subtitle = '已过 ${day.daysPassed} 天';
              }

              // 添加日期信息
              subtitle += ' · ${day.formattedTargetDate}';

              return SelectableItem(
                id: day.id,
                title: day.title,
                subtitle: subtitle,
                icon: Icons.event_outlined,
                rawData: day,
              );
            }).toList();
          },
          searchFilter: (items, query) {
            if (query.isEmpty) return items;
            final lowerQuery = query.toLowerCase();
            return items.where((item) =>
              item.title.toLowerCase().contains(lowerQuery)
            ).toList();
          },
        ),
      ],
    ));

    // 日期范围选择器 - 基于天数的范围选择
    pluginDataSelectorService.registerSelector(SelectorDefinition(
      id: 'day.dateRange',
      pluginId: id,
      name: 'day_dateRangeFilter'.tr,
      icon: Icons.date_range,
      color: color,
      searchable: false,
      selectionMode: SelectionMode.single,
      steps: [
        SelectorStep(
          id: 'dateRange',
          title: 'day_dateRangeFilter'.tr,
          viewType: SelectorViewType.list,
          isFinalStep: true,
          dataLoader: (_) async {
            return [
              // 未来7天 (0到7天)
              SelectableItem(
                id: 'next_7',
                title: '未来7天',
                subtitle: '今天起往后7天',
                icon: Icons.arrow_upward,
                rawData: {'startDay': 0, 'endDay': 7, 'title': '未来7天'},
              ),
              // 未来30天 (0到30天)
              SelectableItem(
                id: 'next_30',
                title: '未来30天',
                subtitle: '今天起往后30天',
                icon: Icons.trending_up,
                rawData: {'startDay': 0, 'endDay': 30, 'title': '未来30天'},
              ),
              // 过去7天 (-7到0天)
              SelectableItem(
                id: 'past_7',
                title: '过去7天',
                subtitle: '往前7天到今天',
                icon: Icons.arrow_downward,
                rawData: {'startDay': -7, 'endDay': 0, 'title': '过去7天'},
              ),
              // 过去30天 (-30到0天)
              SelectableItem(
                id: 'past_30',
                title: '过去30天',
                subtitle: '往前30天到今天',
                icon: Icons.trending_down,
                rawData: {'startDay': -30, 'endDay': 0, 'title': '过去30天'},
              ),
              // 前后7天 (-7到7天)
              SelectableItem(
                id: 'around_7',
                title: '前后7天',
                subtitle: '往前7天到往后7天',
                icon: Icons.sync_alt,
                rawData: {'startDay': -7, 'endDay': 7, 'title': '前后7天'},
              ),
              // 前后30天 (-30到30天)
              SelectableItem(
                id: 'around_30',
                title: '前后30天',
                subtitle: '往前30天到往后30天',
                icon: Icons.all_inclusive,
                rawData: {'startDay': -30, 'endDay': 30, 'title': '前后30天'},
              ),
              // 全部
              SelectableItem(
                id: 'all',
                title: 'day_allDays'.tr,
                subtitle: '显示所有纪念日',
                icon: Icons.calendar_today,
                rawData: {'startDay': null, 'endDay': null, 'title': 'day_allDays'.tr},
              ),
            ];
          },
        ),
      ],
    ));
  }
