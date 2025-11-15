import '../openai/models/plugin_analysis_method.dart';
import '../openai/models/parameter_definition.dart';

/// Chat 插件的数据分析方法定义
final List<PluginAnalysisMethod> chatAnalysisMethods = [
  // 获取消息列表
  PluginAnalysisMethod(
    name: 'chat_getMessages',
    title: '聊天 - 获取消息列表',
    pluginId: 'chat',
    template: {
      'method': 'chat_getMessages',
      'channelId': '',
      'startDate': '2025-01-01',
      'endDate': '2025-01-31',
      'mode': 'summary',
    },
    parameters: [
      ParameterDefinition(
        name: 'method',
        type: ParameterType.string,
        defaultValue: 'chat_getMessages',
        label: '方法名',
        required: true,
      ),
      ParameterDefinition(
        name: 'channelId',
        type: ParameterType.string,
        defaultValue: '',
        label: '频道ID',
        hint: '留空则获取所有频道的消息',
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

  // 获取频道列表
  PluginAnalysisMethod(
    name: 'chat_getChannels',
    title: '聊天 - 获取频道列表',
    pluginId: 'chat',
    template: {
      'method': 'chat_getChannels',
      'mode': 'summary',
    },
    parameters: [
      ParameterDefinition(
        name: 'method',
        type: ParameterType.string,
        defaultValue: 'chat_getChannels',
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

  // 获取消息统计
  PluginAnalysisMethod(
    name: 'chat_getStatistics',
    title: '聊天 - 获取消息统计',
    pluginId: 'chat',
    template: {
      'method': 'chat_getStatistics',
      'channelId': '',
      'startDate': '2025-01-01',
      'endDate': '2025-01-31',
    },
    parameters: [
      ParameterDefinition(
        name: 'method',
        type: ParameterType.string,
        defaultValue: 'chat_getStatistics',
        label: '方法名',
        required: true,
      ),
      ParameterDefinition(
        name: 'channelId',
        type: ParameterType.string,
        defaultValue: '',
        label: '频道ID',
        hint: '留空则统计所有频道',
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
    ],
  ),
];
