import '../openai/models/plugin_analysis_method.dart';
import '../openai/models/parameter_definition.dart';

/// Timer 插件的数据分析方法定义
final List<PluginAnalysisMethod> timerAnalysisMethods = [
  PluginAnalysisMethod(
    name: 'timer_getTasks',
    title: '计时器 - 获取任务列表',
    pluginId: 'timer',
    template: {
      'method': 'timer_getTasks',
      'status': 'all',
      'group': '',
    },
    parameters: [
      ParameterDefinition(
        name: 'method',
        type: ParameterType.string,
        defaultValue: 'timer_getTasks',
        label: '方法名',
        required: true,
      ),
      ParameterDefinition(
        name: 'status',
        type: ParameterType.mode,
        defaultValue: 'all',
        label: '状态筛选',
        hint: 'all: 全部, running: 运行中, completed: 已完成, pending: 未开始',
        options: ['all', 'running', 'completed', 'pending'],
      ),
      ParameterDefinition(
        name: 'group',
        type: ParameterType.string,
        defaultValue: '',
        label: '分组名称',
        hint: '指定分组名称,留空则获取全部分组',
      ),
    ],
  ),
  PluginAnalysisMethod(
    name: 'timer_getTaskById',
    title: '计时器 - 获取指定任务详情',
    pluginId: 'timer',
    template: {
      'method': 'timer_getTaskById',
      'taskId': '',
    },
    parameters: [
      ParameterDefinition(
        name: 'method',
        type: ParameterType.string,
        defaultValue: 'timer_getTaskById',
        label: '方法名',
        required: true,
      ),
      ParameterDefinition(
        name: 'taskId',
        type: ParameterType.string,
        defaultValue: '',
        label: '任务ID',
        hint: '计时器任务的唯一标识符',
        required: true,
      ),
    ],
  ),
  PluginAnalysisMethod(
    name: 'timer_getStatistics',
    title: '计时器 - 获取统计数据',
    pluginId: 'timer',
    template: {
      'method': 'timer_getStatistics',
      'startDate': '',
      'endDate': '',
      'groupBy': 'day',
    },
    parameters: [
      ParameterDefinition(
        name: 'method',
        type: ParameterType.string,
        defaultValue: 'timer_getStatistics',
        label: '方法名',
        required: true,
      ),
      ParameterDefinition(
        name: 'startDate',
        type: ParameterType.date,
        defaultValue: '',
        label: '开始日期',
        hint: '格式: YYYY-MM-DD, 留空则为最近30天',
      ),
      ParameterDefinition(
        name: 'endDate',
        type: ParameterType.date,
        defaultValue: '',
        label: '结束日期',
        hint: '格式: YYYY-MM-DD, 留空则为今天',
      ),
      ParameterDefinition(
        name: 'groupBy',
        type: ParameterType.mode,
        defaultValue: 'day',
        label: '分组方式',
        hint: '按日期或任务分组统计',
        options: ['day', 'task', 'group', 'type'],
      ),
    ],
  ),
  PluginAnalysisMethod(
    name: 'timer_getCompletedHistory',
    title: '计时器 - 获取完成历史',
    pluginId: 'timer',
    template: {
      'method': 'timer_getCompletedHistory',
      'limit': '20',
      'offset': '0',
    },
    parameters: [
      ParameterDefinition(
        name: 'method',
        type: ParameterType.string,
        defaultValue: 'timer_getCompletedHistory',
        label: '方法名',
        required: true,
      ),
      ParameterDefinition(
        name: 'limit',
        type: ParameterType.number,
        defaultValue: '20',
        label: '返回数量',
        hint: '最多返回的记录数量',
      ),
      ParameterDefinition(
        name: 'offset',
        type: ParameterType.number,
        defaultValue: '0',
        label: '跳过数量',
        hint: '用于分页,跳过前N条记录',
      ),
    ],
  ),
  PluginAnalysisMethod(
    name: 'timer_getGroupSummary',
    title: '计时器 - 获取分组摘要',
    pluginId: 'timer',
    template: {
      'method': 'timer_getGroupSummary',
    },
    parameters: [
      ParameterDefinition(
        name: 'method',
        type: ParameterType.string,
        defaultValue: 'timer_getGroupSummary',
        label: '方法名',
        required: true,
      ),
    ],
  ),
  PluginAnalysisMethod(
    name: 'timer_getTimerTypeStatistics',
    title: '计时器 - 获取计时器类型统计',
    pluginId: 'timer',
    template: {
      'method': 'timer_getTimerTypeStatistics',
      'startDate': '',
      'endDate': '',
    },
    parameters: [
      ParameterDefinition(
        name: 'method',
        type: ParameterType.string,
        defaultValue: 'timer_getTimerTypeStatistics',
        label: '方法名',
        required: true,
      ),
      ParameterDefinition(
        name: 'startDate',
        type: ParameterType.date,
        defaultValue: '',
        label: '开始日期',
        hint: '格式: YYYY-MM-DD, 留空则统计全部',
      ),
      ParameterDefinition(
        name: 'endDate',
        type: ParameterType.date,
        defaultValue: '',
        label: '结束日期',
        hint: '格式: YYYY-MM-DD, 留空则为今天',
      ),
    ],
  ),
];
