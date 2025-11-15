import '../openai/models/plugin_analysis_method.dart';
import '../openai/models/parameter_definition.dart';

/// Notes 插件的数据分析方法定义
final List<PluginAnalysisMethod> notesAnalysisMethods = [
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
];
