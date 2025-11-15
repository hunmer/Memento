import '../openai/models/plugin_analysis_method.dart';
import '../openai/models/parameter_definition.dart';

/// Day 插件的数据分析方法定义
final List<PluginAnalysisMethod> dayAnalysisMethods = [
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
];
