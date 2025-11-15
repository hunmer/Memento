import '../openai/models/plugin_analysis_method.dart';
import '../openai/models/parameter_definition.dart';

/// Tracker 插件的数据分析方法定义
final List<PluginAnalysisMethod> trackerAnalysisMethods = [
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
];
