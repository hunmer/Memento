import '../openai/models/plugin_analysis_method.dart';
import '../openai/models/parameter_definition.dart';

/// 脚本中心插件的数据分析方法定义
final List<PluginAnalysisMethod> scriptsCenterAnalysisMethods = [
  // 获取脚本列表
  PluginAnalysisMethod(
    name: 'scripts_center_getScripts',
    title: '脚本中心 - 获取脚本列表',
    pluginId: 'scripts_center',
    template: {
      'method': 'scripts_center_getScripts',
      'enabled': 'all',
      'mode': 'summary',
    },
    parameters: [
      ParameterDefinition(
        name: 'method',
        type: ParameterType.string,
        defaultValue: 'scripts_center_getScripts',
        label: '方法名',
        required: true,
      ),
      ParameterDefinition(
        name: 'enabled',
        type: ParameterType.string,
        defaultValue: 'all',
        label: '启用状态',
        options: ['all', 'enabled', 'disabled'],
        hint: 'all=所有脚本, enabled=仅启用, disabled=仅禁用',
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

  // 获取脚本详情
  PluginAnalysisMethod(
    name: 'scripts_center_getScriptDetail',
    title: '脚本中心 - 获取脚本详情',
    pluginId: 'scripts_center',
    template: {
      'method': 'scripts_center_getScriptDetail',
      'scriptId': '',
      'includeCode': false,
    },
    parameters: [
      ParameterDefinition(
        name: 'method',
        type: ParameterType.string,
        defaultValue: 'scripts_center_getScriptDetail',
        label: '方法名',
        required: true,
      ),
      ParameterDefinition(
        name: 'scriptId',
        type: ParameterType.string,
        defaultValue: '',
        label: '脚本ID',
        required: true,
        hint: '脚本的唯一标识符',
      ),
      ParameterDefinition(
        name: 'includeCode',
        type: ParameterType.string,
        defaultValue: 'false',
        label: '包含脚本代码',
        options: ['true', 'false'],
        hint: '是否在返回结果中包含脚本源代码',
      ),
    ],
  ),

  // 获取脚本执行历史
  PluginAnalysisMethod(
    name: 'scripts_center_getExecutionHistory',
    title: '脚本中心 - 获取执行历史',
    pluginId: 'scripts_center',
    template: {
      'method': 'scripts_center_getExecutionHistory',
      'scriptId': '',
      'limit': 10,
    },
    parameters: [
      ParameterDefinition(
        name: 'method',
        type: ParameterType.string,
        defaultValue: 'scripts_center_getExecutionHistory',
        label: '方法名',
        required: true,
      ),
      ParameterDefinition(
        name: 'scriptId',
        type: ParameterType.string,
        defaultValue: '',
        label: '脚本ID',
        hint: '留空则获取所有脚本的执行历史',
      ),
      ParameterDefinition(
        name: 'limit',
        type: ParameterType.number,
        defaultValue: 10,
        label: '返回数量',
        hint: '限制返回的历史记录数量',
      ),
    ],
  ),

  // 获取脚本统计信息
  PluginAnalysisMethod(
    name: 'scripts_center_getStatistics',
    title: '脚本中心 - 获取统计信息',
    pluginId: 'scripts_center',
    template: {
      'method': 'scripts_center_getStatistics',
      'startDate': '2025-01-01',
      'endDate': '2025-01-31',
    },
    parameters: [
      ParameterDefinition(
        name: 'method',
        type: ParameterType.string,
        defaultValue: 'scripts_center_getStatistics',
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
    ],
  ),

  // 获取触发器配置
  PluginAnalysisMethod(
    name: 'scripts_center_getTriggers',
    title: '脚本中心 - 获取触发器配置',
    pluginId: 'scripts_center',
    template: {
      'method': 'scripts_center_getTriggers',
      'scriptId': '',
    },
    parameters: [
      ParameterDefinition(
        name: 'method',
        type: ParameterType.string,
        defaultValue: 'scripts_center_getTriggers',
        label: '方法名',
        required: true,
      ),
      ParameterDefinition(
        name: 'scriptId',
        type: ParameterType.string,
        defaultValue: '',
        label: '脚本ID',
        hint: '留空则获取所有脚本的触发器配置',
      ),
    ],
  ),

  // 获取脚本文件夹列表
  PluginAnalysisMethod(
    name: 'scripts_center_getFolders',
    title: '脚本中心 - 获取文件夹列表',
    pluginId: 'scripts_center',
    template: {
      'method': 'scripts_center_getFolders',
    },
    parameters: [
      ParameterDefinition(
        name: 'method',
        type: ParameterType.string,
        defaultValue: 'scripts_center_getFolders',
        label: '方法名',
        required: true,
      ),
    ],
  ),
];
