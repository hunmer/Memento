import '../openai/models/plugin_analysis_method.dart';
import '../openai/models/parameter_definition.dart';

/// Habits 插件的数据分析方法定义
final List<PluginAnalysisMethod> habitsAnalysisMethods = [
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
];
