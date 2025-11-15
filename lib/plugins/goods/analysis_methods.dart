import '../openai/models/plugin_analysis_method.dart';
import '../openai/models/parameter_definition.dart';

/// Goods 插件的数据分析方法定义
final List<PluginAnalysisMethod> goodsAnalysisMethods = [
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
];
