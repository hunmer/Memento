import '../openai/models/plugin_analysis_method.dart';
import '../openai/models/parameter_definition.dart';

/// Calendar 插件的数据分析方法定义
final List<PluginAnalysisMethod> calendarAnalysisMethods = [
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
