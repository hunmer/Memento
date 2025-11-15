import '../openai/models/plugin_analysis_method.dart';
import '../openai/models/parameter_definition.dart';

/// Todo 插件的数据分析方法定义
final List<PluginAnalysisMethod> todoAnalysisMethods = [
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
];
