import '../openai/models/plugin_analysis_method.dart';
import '../openai/models/parameter_definition.dart';

/// Store 插件的数据分析方法定义
final List<PluginAnalysisMethod> storeAnalysisMethods = [
  // 获取商品列表
  PluginAnalysisMethod(
    name: 'store_getProducts',
    title: '物品兑换 - 获取商品列表',
    pluginId: 'store',
    template: {
      'method': 'store_getProducts',
      'mode': 'summary',
    },
    parameters: [
      ParameterDefinition(
        name: 'method',
        type: ParameterType.string,
        defaultValue: 'store_getProducts',
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

  // 获取用户物品列表
  PluginAnalysisMethod(
    name: 'store_getUserItems',
    title: '物品兑换 - 获取用户物品列表',
    pluginId: 'store',
    template: {
      'method': 'store_getUserItems',
      'mode': 'summary',
    },
    parameters: [
      ParameterDefinition(
        name: 'method',
        type: ParameterType.string,
        defaultValue: 'store_getUserItems',
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

  // 获取积分历史
  PluginAnalysisMethod(
    name: 'store_getPointsHistory',
    title: '物品兑换 - 获取积分历史',
    pluginId: 'store',
    template: {
      'method': 'store_getPointsHistory',
      'startDate': '',
      'endDate': '',
      'mode': 'summary',
    },
    parameters: [
      ParameterDefinition(
        name: 'method',
        type: ParameterType.string,
        defaultValue: 'store_getPointsHistory',
        label: '方法名',
        required: true,
      ),
      ParameterDefinition(
        name: 'startDate',
        type: ParameterType.date,
        label: '开始日期',
      ),
      ParameterDefinition(
        name: 'endDate',
        type: ParameterType.date,
        label: '结束日期',
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

  // 获取兑换历史
  PluginAnalysisMethod(
    name: 'store_getRedeemHistory',
    title: '物品兑换 - 获取兑换历史',
    pluginId: 'store',
    template: {
      'method': 'store_getRedeemHistory',
      'startDate': '',
      'endDate': '',
      'mode': 'summary',
    },
    parameters: [
      ParameterDefinition(
        name: 'method',
        type: ParameterType.string,
        defaultValue: 'store_getRedeemHistory',
        label: '方法名',
        required: true,
      ),
      ParameterDefinition(
        name: 'startDate',
        type: ParameterType.date,
        label: '开始日期',
      ),
      ParameterDefinition(
        name: 'endDate',
        type: ParameterType.date,
        label: '结束日期',
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

  // 获取积分统计
  PluginAnalysisMethod(
    name: 'store_getPointsStats',
    title: '物品兑换 - 获取积分统计',
    pluginId: 'store',
    template: {
      'method': 'store_getPointsStats',
      'startDate': '',
      'endDate': '',
    },
    parameters: [
      ParameterDefinition(
        name: 'method',
        type: ParameterType.string,
        defaultValue: 'store_getPointsStats',
        label: '方法名',
        required: true,
      ),
      ParameterDefinition(
        name: 'startDate',
        type: ParameterType.date,
        label: '开始日期',
      ),
      ParameterDefinition(
        name: 'endDate',
        type: ParameterType.date,
        label: '结束日期',
      ),
    ],
  ),

  // 获取归档商品列表
  PluginAnalysisMethod(
    name: 'store_getArchivedProducts',
    title: '物品兑换 - 获取归档商品列表',
    pluginId: 'store',
    template: {
      'method': 'store_getArchivedProducts',
      'mode': 'summary',
    },
    parameters: [
      ParameterDefinition(
        name: 'method',
        type: ParameterType.string,
        defaultValue: 'store_getArchivedProducts',
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

  // 获取即将过期的物品
  PluginAnalysisMethod(
    name: 'store_getExpiringItems',
    title: '物品兑换 - 获取即将过期的物品',
    pluginId: 'store',
    template: {
      'method': 'store_getExpiringItems',
      'days': 7,
      'mode': 'summary',
    },
    parameters: [
      ParameterDefinition(
        name: 'method',
        type: ParameterType.string,
        defaultValue: 'store_getExpiringItems',
        label: '方法名',
        required: true,
      ),
      ParameterDefinition(
        name: 'days',
        type: ParameterType.number,
        defaultValue: 7,
        label: '天数',
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

  // 获取使用历史
  PluginAnalysisMethod(
    name: 'store_getUsageHistory',
    title: '物品兑换 - 获取使用历史',
    pluginId: 'store',
    template: {
      'method': 'store_getUsageHistory',
      'startDate': '',
      'endDate': '',
      'mode': 'summary',
    },
    parameters: [
      ParameterDefinition(
        name: 'method',
        type: ParameterType.string,
        defaultValue: 'store_getUsageHistory',
        label: '方法名',
        required: true,
      ),
      ParameterDefinition(
        name: 'startDate',
        type: ParameterType.date,
        label: '开始日期',
      ),
      ParameterDefinition(
        name: 'endDate',
        type: ParameterType.date,
        label: '结束日期',
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
