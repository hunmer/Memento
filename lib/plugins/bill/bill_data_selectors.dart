part of 'bill_plugin.dart';

// ==================== 数据选择器注册 ====================

/// 注册数据选择器
void _registerDataSelectors() {
  // 1. 选择账户（单级）
  pluginDataSelectorService.registerSelector(
    SelectorDefinition(
      id: 'bill.account',
      pluginId: BillPlugin.instance.id,
      name: '选择账户',
      icon: BillPlugin.instance.icon,
      color: BillPlugin.instance.color,
      searchable: true,
      selectionMode: SelectionMode.single,
      steps: [
        SelectorStep(
          id: 'account',
          title: '选择账户',
          viewType: SelectorViewType.list,
          isFinalStep: true,
          dataLoader: (_) async {
            return BillPlugin.instance.controller.accounts
                .map(
                  (account) => SelectableItem(
                    id: account.id,
                    title: account.title,
                    subtitle:
                        '余额: ¥${account.totalAmount.toStringAsFixed(2)}',
                    icon: account.icon,
                    color: account.backgroundColor,
                    rawData: account.toJson()..['icon'] = account.icon.codePoint,
                  ),
                )
                .toList();
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

  // 2. 选择账单记录（两级：账户 → 账单）
  pluginDataSelectorService.registerSelector(
    SelectorDefinition(
      id: 'bill.record',
      pluginId: BillPlugin.instance.id,
      name: '选择账单记录',
      icon: Icons.receipt_long,
      color: BillPlugin.instance.color,
      searchable: true,
      selectionMode: SelectionMode.single,
      steps: [
        // 第一步：选择账户
        SelectorStep(
          id: 'account',
          title: '选择账户',
          viewType: SelectorViewType.list,
          isFinalStep: false,
          dataLoader: (_) async {
            return BillPlugin.instance.controller.accounts
                .map(
                  (account) => SelectableItem(
                    id: account.id,
                    title: account.title,
                    subtitle:
                        '余额: ¥${account.totalAmount.toStringAsFixed(2)} | ${account.bills.length} 条账单',
                    icon: account.icon,
                    color: account.backgroundColor,
                    rawData: account,
                  ),
                )
                .toList();
          },
          searchFilter: (items, query) {
            if (query.isEmpty) return items;
            final lowerQuery = query.toLowerCase();
            return items.where((item) {
              return item.title.toLowerCase().contains(lowerQuery);
            }).toList();
          },
        ),
        // 第二步：选择账单
        SelectorStep(
          id: 'bill',
          title: '选择账单',
          viewType: SelectorViewType.list,
          isFinalStep: true,
          dataLoader: (previousSelections) async {
            final account = previousSelections['account'] as Account;
            // 按日期倒序排列
            final sortedBills = List<Bill>.from(account.bills)
              ..sort((a, b) => b.date.compareTo(a.date));

            return sortedBills
                .map(
                  (bill) => SelectableItem(
                    id: bill.id,
                    title: bill.title,
                    subtitle:
                        '${bill.category} | ${bill.date.toString().substring(0, 10)} | ¥${bill.amount.toStringAsFixed(2)}',
                    icon: bill.icon,
                    color: bill.iconColor,
                    rawData: bill,
                  ),
                )
                .toList();
          },
          searchFilter: (items, query) {
            if (query.isEmpty) return items;
            final lowerQuery = query.toLowerCase();
            return items.where((item) {
              final bill = item.rawData as Bill;
              return item.title.toLowerCase().contains(lowerQuery) ||
                  bill.category.toLowerCase().contains(lowerQuery) ||
                  bill.note.toLowerCase().contains(lowerQuery);
            }).toList();
          },
          emptyText: '该账户暂无账单记录',
        ),
      ],
    ),
  );

  // 3. 选择账户和时间范围（用于小组件配置）
  pluginDataSelectorService.registerSelector(
    SelectorDefinition(
      id: 'bill.account_with_period',
      pluginId: BillPlugin.instance.id,
      name: '选择账户和时间',
      icon: Icons.calendar_today,
      color: BillPlugin.instance.color,
      searchable: false,
      selectionMode: SelectionMode.single,
      steps: [
        // 第一步：选择账户
        SelectorStep(
          id: 'account',
          title: '选择账户',
          viewType: SelectorViewType.list,
          isFinalStep: false,
          dataLoader: (_) async {
            return BillPlugin.instance.controller.accounts
                .map(
                  (account) => SelectableItem(
                    id: account.id,
                    title: account.title,
                    subtitle:
                        '余额: ¥${account.totalAmount.toStringAsFixed(2)}',
                    icon: account.icon,
                    color: account.backgroundColor,
                    rawData: account.toJson()..['icon'] = account.icon.codePoint,
                  ),
                )
                .toList();
          },
          searchFilter: (items, query) {
            if (query.isEmpty) return items;
            final lowerQuery = query.toLowerCase();
            return items.where((item) {
              return item.title.toLowerCase().contains(lowerQuery);
            }).toList();
          },
        ),
        // 第二步：选择时间范围
        SelectorStep(
          id: 'period',
          title: '选择时间范围',
          viewType: SelectorViewType.list,
          isFinalStep: true,
          dataLoader: (_) async {
            final now = DateTime.now();
            final periods = [
              {
                'id': 'today',
                'label': '今天',
                'start': DateTime(now.year, now.month, now.day).toIso8601String(),
                'end': now.toIso8601String(),
              },
              {
                'id': 'week',
                'label': '本周',
                'start': now.subtract(Duration(days: now.weekday - 1)).toIso8601String(),
                'end': now.toIso8601String(),
              },
              {
                'id': 'month',
                'label': '本月',
                'start': DateTime(now.year, now.month, 1).toIso8601String(),
                'end': now.toIso8601String(),
              },
              {
                'id': 'year',
                'label': '本年',
                'start': DateTime(now.year, 1, 1).toIso8601String(),
                'end': now.toIso8601String(),
              },
              {
                'id': 'all',
                'label': '全部',
                'start': DateTime(2020, 1, 1).toIso8601String(),
                'end': now.toIso8601String(),
              },
            ];

            return periods
                .map(
                  (p) => SelectableItem(
                    id: p['id'] as String,
                    title: p['label'] as String,
                    subtitle: '统计该时间段的收支',
                    icon: Icons.access_time,
                    color: Colors.blue,
                    rawData: p,
                  ),
                )
                .toList();
          },
        ),
      ],
    ),
  );

  // 4. 支出统计配置（用于小组件）- 使用自定义表单
  pluginDataSelectorService.registerSelector(
    SelectorDefinition(
      id: 'bill.stats.config',
      pluginId: BillPlugin.instance.id,
      name: '支出统计配置',
      icon: Icons.pie_chart,
      color: BillPlugin.instance.color,
      searchable: false,
      selectionMode: SelectionMode.single,
      steps: [
        SelectorStep(
          id: 'config',
          title: '支出统计配置',
          viewType: SelectorViewType.customForm,
          isFinalStep: true,
          dataLoader: (_) async => [],
          customFormBuilder: (context, previousSelections, onComplete) {
            return _BillStatsConfigForm(
              onComplete: (config) {
                onComplete(config);
              },
            );
          },
        ),
      ],
    ),
  );

  // 5. 月份账单配置（用于小组件）- 使用自定义表单
  pluginDataSelectorService.registerSelector(
    SelectorDefinition(
      id: 'bill.monthly.config',
      pluginId: BillPlugin.instance.id,
      name: '月份账单配置',
      icon: Icons.calendar_month,
      color: BillPlugin.instance.color,
      searchable: false,
      selectionMode: SelectionMode.single,
      steps: [
        SelectorStep(
          id: 'config',
          title: '月份账单配置',
          viewType: SelectorViewType.customForm,
          isFinalStep: true,
          dataLoader: (_) async => [],
          customFormBuilder: (context, previousSelections, onComplete) {
            return _MonthlyBillConfigForm(
              onComplete: (config) {
                onComplete(config);
              },
            );
          },
        ),
      ],
    ),
  );
}
