part of 'database_plugin.dart';

/// 注册数据选择器
void _registerDataSelectors() {
  // 1. 数据库表选择器（单级）
  pluginDataSelectorService.registerSelector(SelectorDefinition(
    id: 'database.table',
    pluginId: id,
    name: '选择数据库表',
    description: '选择一个数据库表',
    icon: icon,
    color: color,
    steps: [
      SelectorStep(
        id: 'table',
        title: '数据库表列表',
        viewType: SelectorViewType.list,
        isFinalStep: true,
        emptyText: '暂无数据库表，请先创建',
        dataLoader: (_) async {
          final databases = await service.getAllDatabases();
          return databases.map((database) => SelectableItem(
            id: database.id,
            title: database.name,
            subtitle: database.description,
            icon: Icons.storage,
            color: color,
            rawData: database,
          )).toList();
        },
        searchFilter: (items, query) {
          final lowerQuery = query.toLowerCase();
          return items.where((item) =>
            item.title.toLowerCase().contains(lowerQuery) ||
            (item.subtitle?.toLowerCase().contains(lowerQuery) ?? false)
          ).toList();
        },
      ),
    ],
  ));

  // 2. 记录选择器（两级：数据库 → 记录）
  pluginDataSelectorService.registerSelector(SelectorDefinition(
    id: 'database.record',
    pluginId: id,
    name: '选择记录',
    description: '选择一条数据库记录',
    icon: Icons.description,
    color: color,
    steps: [
      // 第一级：选择数据库
      SelectorStep(
        id: 'database',
        title: '选择数据库',
        viewType: SelectorViewType.list,
        isFinalStep: false,
        emptyText: '暂无数据库',
        dataLoader: (_) async {
          final databases = await service.getAllDatabases();
          return databases.map((database) => SelectableItem(
            id: database.id,
            title: database.name,
            subtitle: database.description,
            icon: Icons.storage,
            color: color,
            rawData: database,
          )).toList();
        },
        searchFilter: (items, query) {
          final lowerQuery = query.toLowerCase();
          return items.where((item) =>
            item.title.toLowerCase().contains(lowerQuery)
          ).toList();
        },
      ),
      // 第二级：选择记录
      SelectorStep(
        id: 'record',
        title: '选择记录',
        viewType: SelectorViewType.list,
        isFinalStep: true,
        emptyText: '该数据库暂无记录',
        dataLoader: (previousSelections) async {
          final database = previousSelections['database'] as DatabaseModel;
          // 加载数据库记录
          final records = await controller.getRecords(database.id);
          if (records.isEmpty) return [];

          return records.map((record) {
            // 尝试获取记录的显示标题
            String displayTitle = '未命名';

            // 优先查找名为 'title' 或 'name' 的字段
            if (record.fields.containsKey('title') && record.fields['title'] != null) {
              displayTitle = record.fields['title'].toString();
            } else if (record.fields.containsKey('name') && record.fields['name'] != null) {
              displayTitle = record.fields['name'].toString();
            } else if (record.fields.isNotEmpty) {
              // 如果没有 title/name 字段，使用第一个非空字段
              final firstField = record.fields.entries.firstWhere(
                (e) => e.value != null && e.value.toString().isNotEmpty,
                orElse: () => MapEntry('', ''),
              );
              if (firstField.key.isNotEmpty) {
                displayTitle = '${firstField.key}: ${firstField.value}';
              }
            }

            // 截断过长的标题
            if (displayTitle.length > 50) {
              displayTitle = '${displayTitle.substring(0, 50)}...';
            }

            // 生成副标题（显示记录ID或创建时间）
            String subtitle = 'ID: ${record.id.substring(0, 8)}...';

            return SelectableItem(
              id: record.id,
              title: displayTitle,
              subtitle: subtitle,
              icon: Icons.description,
              rawData: record,
            );
          }).toList();
        },
        searchFilter: (items, query) {
          final lowerQuery = query.toLowerCase();
          return items.where((item) =>
            item.title.toLowerCase().contains(lowerQuery) ||
            (item.subtitle?.toLowerCase().contains(lowerQuery) ?? false)
          ).toList();
        },
      ),
    ],
  ));
}
