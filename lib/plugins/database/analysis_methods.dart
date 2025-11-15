import '../openai/models/plugin_analysis_method.dart';
import '../openai/models/parameter_definition.dart';

/// Database 插件的数据分析方法定义
final List<PluginAnalysisMethod> databaseAnalysisMethods = [
  // 获取数据库列表
  PluginAnalysisMethod(
    name: 'database_getDatabases',
    title: '自定义数据库 - 获取数据库列表',
    pluginId: 'database',
    template: {
      'method': 'database_getDatabases',
      'mode': 'summary',
    },
    parameters: [
      ParameterDefinition(
        name: 'method',
        type: ParameterType.string,
        defaultValue: 'database_getDatabases',
        label: '方法名',
        required: true,
      ),
      ParameterDefinition(
        name: 'mode',
        type: ParameterType.mode,
        defaultValue: 'summary',
        label: '数据模式',
        options: ['summary', 'compact', 'full'],
        hint: 'summary: 仅数据库基本信息，compact: 包含字段定义，full: 包含所有详细信息',
      ),
    ],
  ),

  // 获取特定数据库的记录
  PluginAnalysisMethod(
    name: 'database_getRecords',
    title: '自定义数据库 - 获取数据表记录',
    pluginId: 'database',
    template: {
      'method': 'database_getRecords',
      'databaseId': '',
      'mode': 'summary',
    },
    parameters: [
      ParameterDefinition(
        name: 'method',
        type: ParameterType.string,
        defaultValue: 'database_getRecords',
        label: '方法名',
        required: true,
      ),
      ParameterDefinition(
        name: 'databaseId',
        type: ParameterType.string,
        defaultValue: '',
        label: '数据库ID',
        hint: '要获取记录的数据库ID，留空则获取所有数据库的记录',
      ),
      ParameterDefinition(
        name: 'mode',
        type: ParameterType.mode,
        defaultValue: 'summary',
        label: '数据模式',
        options: ['summary', 'compact', 'full'],
        hint: 'summary: 记录总数和时间范围，compact: 包含关键字段数据，full: 包含所有字段',
      ),
      ParameterDefinition(
        name: 'limit',
        type: ParameterType.number,
        defaultValue: 100,
        label: '记录数量限制',
        hint: '最多返回的记录数量（默认100）',
      ),
    ],
  ),

  // 统计数据库信息
  PluginAnalysisMethod(
    name: 'database_getStatistics',
    title: '自定义数据库 - 获取统计信息',
    pluginId: 'database',
    template: {
      'method': 'database_getStatistics',
      'databaseId': '',
    },
    parameters: [
      ParameterDefinition(
        name: 'method',
        type: ParameterType.string,
        defaultValue: 'database_getStatistics',
        label: '方法名',
        required: true,
      ),
      ParameterDefinition(
        name: 'databaseId',
        type: ParameterType.string,
        defaultValue: '',
        label: '数据库ID',
        hint: '要统计的数据库ID，留空则统计所有数据库',
      ),
    ],
  ),

  // 查询记录
  PluginAnalysisMethod(
    name: 'database_queryRecords',
    title: '自定义数据库 - 查询记录',
    pluginId: 'database',
    template: {
      'method': 'database_queryRecords',
      'databaseId': '',
      'filters': '{}',
      'mode': 'compact',
    },
    parameters: [
      ParameterDefinition(
        name: 'method',
        type: ParameterType.string,
        defaultValue: 'database_queryRecords',
        label: '方法名',
        required: true,
      ),
      ParameterDefinition(
        name: 'databaseId',
        type: ParameterType.string,
        defaultValue: '',
        label: '数据库ID',
        hint: '要查询的数据库ID',
        required: true,
      ),
      ParameterDefinition(
        name: 'filters',
        type: ParameterType.string,
        defaultValue: '{}',
        label: '过滤条件',
        hint: 'JSON格式的过滤条件，例如：{"字段名": "值"}',
      ),
      ParameterDefinition(
        name: 'mode',
        type: ParameterType.mode,
        defaultValue: 'compact',
        label: '数据模式',
        options: ['summary', 'compact', 'full'],
        hint: 'summary: 仅记录数量，compact: 包含关键字段，full: 包含所有字段',
      ),
    ],
  ),

  // 获取字段统计
  PluginAnalysisMethod(
    name: 'database_getFieldStatistics',
    title: '自定义数据库 - 获取字段统计',
    pluginId: 'database',
    template: {
      'method': 'database_getFieldStatistics',
      'databaseId': '',
      'fieldName': '',
    },
    parameters: [
      ParameterDefinition(
        name: 'method',
        type: ParameterType.string,
        defaultValue: 'database_getFieldStatistics',
        label: '方法名',
        required: true,
      ),
      ParameterDefinition(
        name: 'databaseId',
        type: ParameterType.string,
        defaultValue: '',
        label: '数据库ID',
        hint: '要统计的数据库ID',
        required: true,
      ),
      ParameterDefinition(
        name: 'fieldName',
        type: ParameterType.string,
        defaultValue: '',
        label: '字段名称',
        hint: '要统计的字段名称',
        required: true,
      ),
    ],
  ),

  // 获取时间范围内的记录
  PluginAnalysisMethod(
    name: 'database_getRecordsByDateRange',
    title: '自定义数据库 - 获取时间范围内的记录',
    pluginId: 'database',
    template: {
      'method': 'database_getRecordsByDateRange',
      'databaseId': '',
      'startDate': '',
      'endDate': '',
      'mode': 'compact',
    },
    parameters: [
      ParameterDefinition(
        name: 'method',
        type: ParameterType.string,
        defaultValue: 'database_getRecordsByDateRange',
        label: '方法名',
        required: true,
      ),
      ParameterDefinition(
        name: 'databaseId',
        type: ParameterType.string,
        defaultValue: '',
        label: '数据库ID',
        hint: '要查询的数据库ID',
        required: true,
      ),
      ParameterDefinition(
        name: 'startDate',
        type: ParameterType.date,
        defaultValue: '',
        label: '开始日期',
        hint: '格式：YYYY-MM-DD',
      ),
      ParameterDefinition(
        name: 'endDate',
        type: ParameterType.date,
        defaultValue: '',
        label: '结束日期',
        hint: '格式：YYYY-MM-DD',
      ),
      ParameterDefinition(
        name: 'mode',
        type: ParameterType.mode,
        defaultValue: 'compact',
        label: '数据模式',
        options: ['summary', 'compact', 'full'],
        hint: 'summary: 仅记录数量，compact: 包含关键字段，full: 包含所有字段',
      ),
    ],
  ),
];
