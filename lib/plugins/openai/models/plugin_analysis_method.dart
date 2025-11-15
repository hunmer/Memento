import 'parameter_definition.dart';

class PluginAnalysisMethod {
  final String name;
  final String title;
  final Map<String, dynamic> template;
  final String? pluginId;
  final List<ParameterDefinition>? parameters; // 参数定义列表

  const PluginAnalysisMethod({
    required this.name,
    required this.title,
    required this.template,
    this.pluginId,
    this.parameters,
  });

  String get formattedJson {
    return _prettyPrintJson(template);
  }

  // 格式化JSON字符串
  String _prettyPrintJson(Map<String, dynamic> json) {
    var indent = '  ';
    var result = '{\n';
    
    json.forEach((key, value) {
      result += '$indent"$key": ${_formatValue(value)},\n';
    });
    
    // 移除最后一个逗号
    if (result.endsWith(',\n')) {
      result = '${result.substring(0, result.length - 2)}\n';
    }
    
    result += '}';
    return result;
  }

  String _formatValue(dynamic value) {
    if (value is String) {
      return '"$value"';
    }
    return value.toString();
  }

  // 预定义的方法列表
  static List<PluginAnalysisMethod> get predefinedMethods => [
    // Activity 插件
    PluginAnalysisMethod(
      name: 'activity_getActivities',
      title: '活动记录 - 获取活动列表',
      pluginId: 'activity',
      template: {
        'method': 'activity_getActivities',
        'startDate': '2025-01-01',
        'endDate': '2025-01-31',
        'mode': 'summary',
      },
      parameters: [
        ParameterDefinition(
          name: 'method',
          type: ParameterType.string,
          defaultValue: 'activity_getActivities',
          label: '方法名',
          required: true,
        ),
        ParameterDefinition(
          name: 'startDate',
          type: ParameterType.date,
          defaultValue: '2025-01-01',
          label: '开始日期',
          hint: 'YYYY-MM-DD',
        ),
        ParameterDefinition(
          name: 'endDate',
          type: ParameterType.date,
          defaultValue: '2025-01-31',
          label: '结束日期',
          hint: 'YYYY-MM-DD',
        ),
        ParameterDefinition(
          name: 'mode',
          type: ParameterType.mode,
          defaultValue: 'summary',
          label: '数据模式',
          options: ['summary', 'compact', 'full'],
        ),
      ],
    ),

    // Bill 插件
    PluginAnalysisMethod(
      name: 'bill_getBills',
      title: '账单 - 获取账单列表',
      pluginId: 'bill',
      template: {
        'method': 'bill_getBills',
        'startDate': '2025-01-01',
        'endDate': '2025-01-31',
        'mode': 'summary',
      },
      parameters: [
        ParameterDefinition(
          name: 'method',
          type: ParameterType.string,
          defaultValue: 'bill_getBills',
          label: '方法名',
          required: true,
        ),
        ParameterDefinition(
          name: 'startDate',
          type: ParameterType.date,
          defaultValue: '2025-01-01',
          label: '开始日期',
          hint: 'YYYY-MM-DD',
        ),
        ParameterDefinition(
          name: 'endDate',
          type: ParameterType.date,
          defaultValue: '2025-01-31',
          label: '结束日期',
          hint: 'YYYY-MM-DD',
        ),
        ParameterDefinition(
          name: 'mode',
          type: ParameterType.mode,
          defaultValue: 'summary',
          label: '数据模式',
          options: ['summary', 'compact', 'full'],
        ),
      ],
    ),

    // Checkin 插件
    PluginAnalysisMethod(
      name: 'checkin_getCheckinHistory',
      title: '签到 - 获取打卡历史',
      pluginId: 'checkin',
      template: {
        'method': 'checkin_getCheckinHistory',
        'startDate': '2025-01-01',
        'endDate': '2025-01-31',
        'mode': 'summary',
      },
      parameters: [
        ParameterDefinition(
          name: 'method',
          type: ParameterType.string,
          defaultValue: 'checkin_getCheckinHistory',
          label: '方法名',
          required: true,
        ),
        ParameterDefinition(
          name: 'startDate',
          type: ParameterType.date,
          defaultValue: '2025-01-01',
          label: '开始日期',
          hint: 'YYYY-MM-DD',
        ),
        ParameterDefinition(
          name: 'endDate',
          type: ParameterType.date,
          defaultValue: '2025-01-31',
          label: '结束日期',
          hint: 'YYYY-MM-DD',
        ),
        ParameterDefinition(
          name: 'mode',
          type: ParameterType.mode,
          defaultValue: 'summary',
          label: '数据模式',
          options: ['summary', 'compact', 'full'],
        ),
      ],
    ),

    // Diary 插件
    PluginAnalysisMethod(
      name: 'diary_getDiaries',
      title: '日记 - 获取日记列表',
      pluginId: 'diary',
      template: {
        'method': 'diary_getDiaries',
        'startDate': '2025-01-01',
        'endDate': '2025-01-31',
        'mode': 'summary',
      },
      parameters: [
        ParameterDefinition(
          name: 'method',
          type: ParameterType.string,
          defaultValue: 'diary_getDiaries',
          label: '方法名',
          required: true,
        ),
        ParameterDefinition(
          name: 'startDate',
          type: ParameterType.date,
          defaultValue: '2025-01-01',
          label: '开始日期',
          hint: 'YYYY-MM-DD',
        ),
        ParameterDefinition(
          name: 'endDate',
          type: ParameterType.date,
          defaultValue: '2025-01-31',
          label: '结束日期',
          hint: 'YYYY-MM-DD',
        ),
        ParameterDefinition(
          name: 'mode',
          type: ParameterType.mode,
          defaultValue: 'summary',
          label: '数据模式',
          options: ['summary', 'compact', 'full'],
        ),
      ],
    ),

    // Notes 插件
    PluginAnalysisMethod(
      name: 'notes_getNotes',
      title: '笔记 - 获取笔记列表',
      pluginId: 'notes',
      template: {
        'method': 'notes_getNotes',
        'mode': 'summary',
      },
      parameters: [
        ParameterDefinition(
          name: 'method',
          type: ParameterType.string,
          defaultValue: 'notes_getNotes',
          label: '方法名',
          required: true,
        ),
        ParameterDefinition(
          name: 'mode',
          type: ParameterType.mode,
          defaultValue: 'summary',
          label: '数据模式',
          options: ['summary', 'compact', 'full'],
        ),
      ],
    ),

    // Day 插件
    PluginAnalysisMethod(
      name: 'day_getDays',
      title: '纪念日 - 获取纪念日列表',
      pluginId: 'day',
      template: {
        'method': 'day_getDays',
        'mode': 'summary',
      },
      parameters: [
        ParameterDefinition(
          name: 'method',
          type: ParameterType.string,
          defaultValue: 'day_getDays',
          label: '方法名',
          required: true,
        ),
        ParameterDefinition(
          name: 'mode',
          type: ParameterType.mode,
          defaultValue: 'summary',
          label: '数据模式',
          options: ['summary', 'compact', 'full'],
        ),
      ],
    ),

    // Nodes 插件
    PluginAnalysisMethod(
      name: 'nodes_getNodePaths',
      title: '节点笔记本 - 获取节点路径',
      pluginId: 'nodes',
      template: {
        'method': 'nodes_getNodePaths',
        'mode': 'summary',
      },
      parameters: [
        ParameterDefinition(
          name: 'method',
          type: ParameterType.string,
          defaultValue: 'nodes_getNodePaths',
          label: '方法名',
          required: true,
        ),
        ParameterDefinition(
          name: 'mode',
          type: ParameterType.mode,
          defaultValue: 'summary',
          label: '数据模式',
          options: ['summary', 'compact', 'full'],
        ),
      ],
    ),

    // Todo 插件
    PluginAnalysisMethod(
      name: 'todo_getTasks',
      title: '任务 - 获取任务列表',
      pluginId: 'todo',
      template: {
        'method': 'todo_getTasks',
        'mode': 'summary',
      },
      parameters: [
        ParameterDefinition(
          name: 'method',
          type: ParameterType.string,
          defaultValue: 'todo_getTasks',
          label: '方法名',
          required: true,
        ),
        ParameterDefinition(
          name: 'mode',
          type: ParameterType.mode,
          defaultValue: 'summary',
          label: '数据模式',
          options: ['summary', 'compact', 'full'],
        ),
      ],
    ),
    PluginAnalysisMethod(
      name: 'todo_getStats',
      title: '任务 - 获取统计数据',
      pluginId: 'todo',
      template: {
        'method': 'todo_getStats',
      },
      parameters: [
        ParameterDefinition(
          name: 'method',
          type: ParameterType.string,
          defaultValue: 'todo_getStats',
          label: '方法名',
          required: true,
        ),
      ],
    ),

    // Tracker 插件
    PluginAnalysisMethod(
      name: 'tracker_getGoals',
      title: '目标追踪 - 获取目标列表',
      pluginId: 'tracker',
      template: {
        'method': 'tracker_getGoals',
        'mode': 'summary',
      },
      parameters: [
        ParameterDefinition(
          name: 'method',
          type: ParameterType.string,
          defaultValue: 'tracker_getGoals',
          label: '方法名',
          required: true,
        ),
        ParameterDefinition(
          name: 'mode',
          type: ParameterType.mode,
          defaultValue: 'summary',
          label: '数据模式',
          options: ['summary', 'compact', 'full'],
        ),
      ],
    ),
    PluginAnalysisMethod(
      name: 'tracker_getProgress',
      title: '目标追踪 - 获取进度数据',
      pluginId: 'tracker',
      template: {
        'method': 'tracker_getProgress',
        'days': '30',
      },
      parameters: [
        ParameterDefinition(
          name: 'method',
          type: ParameterType.string,
          defaultValue: 'tracker_getProgress',
          label: '方法名',
          required: true,
        ),
        ParameterDefinition(
          name: 'days',
          type: ParameterType.number,
          defaultValue: '30',
          label: '天数',
        ),
      ],
    ),

    // Goods 插件
    PluginAnalysisMethod(
      name: 'goods_getItems',
      title: '物品管理 - 获取物品列表',
      pluginId: 'goods',
      template: {
        'method': 'goods_getItems',
        'mode': 'summary',
      },
      parameters: [
        ParameterDefinition(
          name: 'method',
          type: ParameterType.string,
          defaultValue: 'goods_getItems',
          label: '方法名',
          required: true,
        ),
        ParameterDefinition(
          name: 'mode',
          type: ParameterType.mode,
          defaultValue: 'summary',
          label: '数据模式',
          options: ['summary', 'compact', 'full'],
        ),
      ],
    ),
    PluginAnalysisMethod(
      name: 'goods_getCategories',
      title: '物品管理 - 获取分类列表',
      pluginId: 'goods',
      template: {
        'method': 'goods_getCategories',
      },
      parameters: [
        ParameterDefinition(
          name: 'method',
          type: ParameterType.string,
          defaultValue: 'goods_getCategories',
          label: '方法名',
          required: true,
        ),
      ],
    ),

    // Habits 插件
    PluginAnalysisMethod(
      name: 'habits_getHabits',
      title: '习惯管理 - 获取习惯列表',
      pluginId: 'habits',
      template: {
        'method': 'habits_getHabits',
        'startDate': '2025-01-01',
        'endDate': '2025-01-31',
        'mode': 'summary',
      },
      parameters: [
        ParameterDefinition(
          name: 'method',
          type: ParameterType.string,
          defaultValue: 'habits_getHabits',
          label: '方法名',
          required: true,
        ),
        ParameterDefinition(
          name: 'startDate',
          type: ParameterType.date,
          defaultValue: '2025-01-01',
          label: '开始日期',
          hint: 'YYYY-MM-DD',
        ),
        ParameterDefinition(
          name: 'endDate',
          type: ParameterType.date,
          defaultValue: '2025-01-31',
          label: '结束日期',
          hint: 'YYYY-MM-DD',
        ),
        ParameterDefinition(
          name: 'mode',
          type: ParameterType.mode,
          defaultValue: 'summary',
          label: '数据模式',
          options: ['summary', 'compact', 'full'],
        ),
      ],
    ),
    PluginAnalysisMethod(
      name: 'habits_getStats',
      title: '习惯管理 - 获取统计数据',
      pluginId: 'habits',
      template: {
        'method': 'habits_getStats',
      },
      parameters: [
        ParameterDefinition(
          name: 'method',
          type: ParameterType.string,
          defaultValue: 'habits_getStats',
          label: '方法名',
          required: true,
        ),
      ],
    ),

    // Contact 插件
    PluginAnalysisMethod(
      name: 'contact_getContacts',
      title: '联系人 - 获取联系人列表',
      pluginId: 'contact',
      template: {
        'method': 'contact_getContacts',
        'mode': 'summary',
      },
      parameters: [
        ParameterDefinition(
          name: 'method',
          type: ParameterType.string,
          defaultValue: 'contact_getContacts',
          label: '方法名',
          required: true,
        ),
        ParameterDefinition(
          name: 'mode',
          type: ParameterType.mode,
          defaultValue: 'summary',
          label: '数据模式',
          options: ['summary', 'compact', 'full'],
        ),
      ],
    ),

    // Calendar 插件
    PluginAnalysisMethod(
      name: 'calendar_getEvents',
      title: '日历 - 获取事件列表',
      pluginId: 'calendar',
      template: {
        'method': 'calendar_getEvents',
        'startDate': '2025-01-01',
        'endDate': '2025-01-31',
        'mode': 'summary',
      },
      parameters: [
        ParameterDefinition(
          name: 'method',
          type: ParameterType.string,
          defaultValue: 'calendar_getEvents',
          label: '方法名',
          required: true,
        ),
        ParameterDefinition(
          name: 'startDate',
          type: ParameterType.date,
          defaultValue: '2025-01-01',
          label: '开始日期',
          hint: 'YYYY-MM-DD',
        ),
        ParameterDefinition(
          name: 'endDate',
          type: ParameterType.date,
          defaultValue: '2025-01-31',
          label: '结束日期',
          hint: 'YYYY-MM-DD',
        ),
        ParameterDefinition(
          name: 'mode',
          type: ParameterType.mode,
          defaultValue: 'summary',
          label: '数据模式',
          options: ['summary', 'compact', 'full'],
        ),
      ],
    ),
    PluginAnalysisMethod(
      name: 'calendar_getTodayEvents',
      title: '日历 - 获取今日事件',
      pluginId: 'calendar',
      template: {
        'method': 'calendar_getTodayEvents',
        'mode': 'summary',
      },
      parameters: [
        ParameterDefinition(
          name: 'method',
          type: ParameterType.string,
          defaultValue: 'calendar_getTodayEvents',
          label: '方法名',
          required: true,
        ),
        ParameterDefinition(
          name: 'mode',
          type: ParameterType.mode,
          defaultValue: 'summary',
          label: '数据模式',
          options: ['summary', 'compact', 'full'],
        ),
      ],
    ),
  ];
}