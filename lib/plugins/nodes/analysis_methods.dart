import '../openai/models/plugin_analysis_method.dart';
import '../openai/models/parameter_definition.dart';

/// Nodes 插件的数据分析方法定义
final List<PluginAnalysisMethod> nodesAnalysisMethods = [
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
];
