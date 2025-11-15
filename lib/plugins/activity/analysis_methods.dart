import '../openai/models/plugin_analysis_method.dart';
import '../openai/models/parameter_definition.dart';

/// Activity 插件的数据分析方法定义
final List<PluginAnalysisMethod> activityAnalysisMethods = [
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
];
