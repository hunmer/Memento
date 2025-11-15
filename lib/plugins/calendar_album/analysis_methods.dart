import '../openai/models/plugin_analysis_method.dart';
import '../openai/models/parameter_definition.dart';

/// Calendar Album 插件的数据分析方法定义
final List<PluginAnalysisMethod> calendarAlbumAnalysisMethods = [
  // 获取日记相册列表（支持日期范围和标签筛选）
  PluginAnalysisMethod(
    name: 'calendar_album_getEntries',
    title: '日记相册 - 获取日记列表',
    pluginId: 'calendar_album',
    template: {
      'method': 'calendar_album_getEntries',
      'startDate': '2025-01-01',
      'endDate': '2025-01-31',
      'tags': '',
      'mode': 'summary',
    },
    parameters: [
      ParameterDefinition(
        name: 'method',
        type: ParameterType.string,
        defaultValue: 'calendar_album_getEntries',
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
      ParameterDefinition(
        name: 'tags',
        type: ParameterType.string,
        defaultValue: '',
        label: '标签筛选',
        hint: '多个标签用逗号分隔，支持AND逻辑',
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

  // 获取照片列表
  PluginAnalysisMethod(
    name: 'calendar_album_getPhotos',
    title: '日记相册 - 获取照片列表',
    pluginId: 'calendar_album',
    template: {
      'method': 'calendar_album_getPhotos',
      'startDate': '2025-01-01',
      'endDate': '2025-01-31',
      'mode': 'summary',
    },
    parameters: [
      ParameterDefinition(
        name: 'method',
        type: ParameterType.string,
        defaultValue: 'calendar_album_getPhotos',
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
      ParameterDefinition(
        name: 'mode',
        type: ParameterType.mode,
        defaultValue: 'summary',
        label: '数据模式',
        options: ['summary', 'compact', 'full'],
      ),
    ],
  ),

  // 获取标签统计
  PluginAnalysisMethod(
    name: 'calendar_album_getTagStats',
    title: '日记相册 - 获取标签统计',
    pluginId: 'calendar_album',
    template: {
      'method': 'calendar_album_getTagStats',
      'mode': 'summary',
    },
    parameters: [
      ParameterDefinition(
        name: 'method',
        type: ParameterType.string,
        defaultValue: 'calendar_album_getTagStats',
        label: '方法名',
        required: true,
      ),
      ParameterDefinition(
        name: 'mode',
        type: ParameterType.mode,
        defaultValue: 'summary',
        label: '数据模式',
        options: ['summary', 'full'],
      ),
    ],
  ),

  // 获取心情和天气统计
  PluginAnalysisMethod(
    name: 'calendar_album_getMoodWeatherStats',
    title: '日记相册 - 获取心情和天气统计',
    pluginId: 'calendar_album',
    template: {
      'method': 'calendar_album_getMoodWeatherStats',
      'startDate': '2025-01-01',
      'endDate': '2025-01-31',
      'mode': 'summary',
    },
    parameters: [
      ParameterDefinition(
        name: 'method',
        type: ParameterType.string,
        defaultValue: 'calendar_album_getMoodWeatherStats',
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
      ParameterDefinition(
        name: 'mode',
        type: ParameterType.mode,
        defaultValue: 'summary',
        label: '数据模式',
        options: ['summary', 'full'],
      ),
    ],
  ),

  // 获取位置统计
  PluginAnalysisMethod(
    name: 'calendar_album_getLocationStats',
    title: '日记相册 - 获取位置统计',
    pluginId: 'calendar_album',
    template: {
      'method': 'calendar_album_getLocationStats',
      'startDate': '2025-01-01',
      'endDate': '2025-01-31',
      'mode': 'summary',
    },
    parameters: [
      ParameterDefinition(
        name: 'method',
        type: ParameterType.string,
        defaultValue: 'calendar_album_getLocationStats',
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
      ParameterDefinition(
        name: 'mode',
        type: ParameterType.mode,
        defaultValue: 'summary',
        label: '数据模式',
        options: ['summary', 'full'],
      ),
    ],
  ),

  // 获取日记统计概览
  PluginAnalysisMethod(
    name: 'calendar_album_getStatistics',
    title: '日记相册 - 获取统计概览',
    pluginId: 'calendar_album',
    template: {
      'method': 'calendar_album_getStatistics',
      'startDate': '2025-01-01',
      'endDate': '2025-01-31',
    },
    parameters: [
      ParameterDefinition(
        name: 'method',
        type: ParameterType.string,
        defaultValue: 'calendar_album_getStatistics',
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
];
