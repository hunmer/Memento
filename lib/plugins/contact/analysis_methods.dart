import '../openai/models/plugin_analysis_method.dart';
import '../openai/models/parameter_definition.dart';

/// Contact 插件的数据分析方法定义
final List<PluginAnalysisMethod> contactAnalysisMethods = [
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
];
