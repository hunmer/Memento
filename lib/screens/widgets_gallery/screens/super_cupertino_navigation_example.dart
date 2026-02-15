import 'package:flutter/material.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper/index.dart';

/// Super Cupertino 导航包装示例 - 多条件过滤和搜索演示
class SuperCupertinoNavigationExample extends StatefulWidget {
  const SuperCupertinoNavigationExample({super.key});

  @override
  State<SuperCupertinoNavigationExample> createState() =>
      _SuperCupertinoNavigationExampleState();
}

class _SuperCupertinoNavigationExampleState
    extends State<SuperCupertinoNavigationExample> {
  /// 示例任务数据
  final List<_TaskItem> _allTasks = _generateSampleTasks();

  /// 过滤后的任务列表
  List<_TaskItem> _filteredTasks = [];

  /// 当前搜索关键词
  String _searchKeyword = '';

  /// 多条件过滤状态
  final MultiFilterState _multiFilterState = MultiFilterState();

  /// 尺寸模式
  String _sizeMode = 'small';

  @override
  void initState() {
    super.initState();
    _filteredTasks = List.from(_allTasks);
  }

  @override
  void dispose() {
    _multiFilterState.dispose();
    super.dispose();
  }

  /// 获取宽度
  double _getWidth() {
    final screenWidth = MediaQuery.of(context).size.width;
    switch (_sizeMode) {
      case 'small':
        return 360;
      case 'medium':
        return 440;
      case 'mediumWide':
        return screenWidth - 32;
      case 'large':
        return 520;
      case 'largeWide':
        return screenWidth - 32;
      default:
        return 360;
    }
  }

  /// 是否占满宽度
  bool _isFullWidth() {
    return _sizeMode == 'mediumWide' || _sizeMode == 'largeWide';
  }

  /// 构建多条件过滤项
  List<FilterItem> _buildFilterItems() {
    // 获取所有可用的标签
    final allTags = _allTasks
        .expand((task) => task.tags)
        .toSet()
        .toList()
      ..sort();

    return [
      // 1. 标签多选过滤
      FilterItem(
        id: 'tags',
        title: '标签',
        type: FilterType.tagsMultiple,
        builder: (context, currentValue, onChanged) {
          return FilterBuilders.buildTagsFilter(
            context: context,
            currentValue: currentValue,
            onChanged: onChanged,
            availableTags: allTags,
          );
        },
        getBadge: FilterBuilders.tagsBadge,
      ),

      // 2. 优先级过滤
      FilterItem(
        id: 'priority',
        title: '优先级',
        type: FilterType.custom,
        builder: (context, currentValue, onChanged) {
          return FilterBuilders.buildPriorityFilter<_DemoTaskPriority>(
            context: context,
            currentValue: currentValue,
            onChanged: onChanged,
            priorityLabels: {
              _DemoTaskPriority.low: '低',
              _DemoTaskPriority.medium: '中',
              _DemoTaskPriority.high: '高',
            },
            priorityColors: {
              _DemoTaskPriority.low: Colors.green,
              _DemoTaskPriority.medium: Colors.orange,
              _DemoTaskPriority.high: Colors.red,
            },
          );
        },
        getBadge: (value) => FilterBuilders.priorityBadge(
          value,
          {
            _DemoTaskPriority.low: '低',
            _DemoTaskPriority.medium: '中',
            _DemoTaskPriority.high: '高',
          },
        ),
      ),

      // 3. 状态过滤
      FilterItem(
        id: 'status',
        title: '状态',
        type: FilterType.checkbox,
        builder: (context, currentValue, onChanged) {
          return FilterBuilders.buildCheckboxFilter(
            context: context,
            currentValue: currentValue,
            onChanged: onChanged,
            options: {
              'pending': '待处理',
              'inProgress': '进行中',
              'completed': '已完成',
            },
          );
        },
        getBadge: FilterBuilders.checkboxBadge,
        initialValue: {
          'pending': true,
          'inProgress': true,
          'completed': true,
        },
      ),

      // 4. 日期范围过滤
      FilterItem(
        id: 'dateRange',
        title: '日期范围',
        type: FilterType.dateRange,
        builder: (context, currentValue, onChanged) {
          return FilterBuilders.buildDateRangeFilter(
            context: context,
            currentValue: currentValue,
            onChanged: onChanged,
          );
        },
        getBadge: FilterBuilders.dateRangeBadge,
      ),
    ];
  }

  /// 处理多条件过滤变更
  void _onMultiFilterChanged(Map<String, dynamic> filters) {
    _applyFilters(filters, _searchKeyword);
  }

  /// 处理搜索
  void _onSearchChanged(String keyword) {
    setState(() {
      _searchKeyword = keyword;
      _applyFilters(_multiFilterState.getAllValues(), keyword);
    });
  }

  /// 应用过滤条件
  void _applyFilters(Map<String, dynamic> filters, String keyword) {
    var result = List<_TaskItem>.from(_allTasks);

    // 关键词过滤
    if (keyword.isNotEmpty) {
      result = result
          .where((task) =>
              task.title.toLowerCase().contains(keyword.toLowerCase()) ||
              task.description.toLowerCase().contains(keyword.toLowerCase()))
          .toList();
    }

    // 标签过滤
    if (filters['tags'] != null && (filters['tags'] as List).isNotEmpty) {
      final selectedTags = filters['tags'] as List<String>;
      result = result
          .where((task) =>
              task.tags.any((tag) => selectedTags.contains(tag)))
          .toList();
    }

    // 优先级过滤
    if (filters['priority'] != null) {
      final priority = filters['priority'] as _DemoTaskPriority;
      result = result.where((task) => task.priority == priority).toList();
    }

    // 状态过滤
    if (filters['status'] != null) {
      final status = filters['status'] as Map<String, bool>;
      final includePending = status['pending'] ?? false;
      final includeInProgress = status['inProgress'] ?? false;
      final includeCompleted = status['completed'] ?? false;

      result = result.where((task) {
        if (task.status == _DemoTaskStatus.pending && !includePending) {
          return false;
        }
        if (task.status == _DemoTaskStatus.inProgress && !includeInProgress) {
          return false;
        }
        if (task.status == _DemoTaskStatus.completed && !includeCompleted) {
          return false;
        }
        return true;
      }).toList();
    }

    // 日期范围过滤
    if (filters['dateRange'] != null) {
      final range = filters['dateRange'] as DateTimeRange;
      result = result
          .where((task) =>
              !task.dueDate.isBefore(range.start) &&
              !task.dueDate.isAfter(range.end))
          .toList();
    }

    setState(() {
      _filteredTasks = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Cupertino 导航'),
      ),
      body: Column(
        children: [
          // 尺寸切换按钮
          _buildSizeSelector(theme),
          const Divider(height: 1),
          // 内容
          Expanded(
            child: _isFullWidth()
                ? SuperCupertinoNavigationWrapper(
                    title: const Text('任务列表'),
                    largeTitle: '任务列表',
                    automaticallyImplyLeading: true,

                    // 启用搜索栏
                    enableSearchBar: true,
                    searchPlaceholder: '搜索任务标题或描述...',
                    onSearchChanged: _onSearchChanged,

                    // 启用多条件过滤
                    enableMultiFilter: true,
                    multiFilterItems: _buildFilterItems(),
                    multiFilterBarHeight: 50,
                    onMultiFilterChanged: _onMultiFilterChanged,

                    // 主体内容
                    body: _filteredTasks.isEmpty
                        ? _buildEmptyState()
                        : _buildTaskList(isWide: true),
                  )
                : Center(
                    child: SizedBox(
                      width: _getWidth(),
                      height: double.infinity,
                      child: SuperCupertinoNavigationWrapper(
                        title: const Text('任务列表'),
                        largeTitle: '任务列表',
                        automaticallyImplyLeading: true,

                        // 启用搜索栏
                        enableSearchBar: true,
                        searchPlaceholder: '搜索任务标题或描述...',
                        onSearchChanged: _onSearchChanged,

                        // 启用多条件过滤
                        enableMultiFilter: true,
                        multiFilterItems: _buildFilterItems(),
                        multiFilterBarHeight: 50,
                        onMultiFilterChanged: _onMultiFilterChanged,

                        // 主体内容
                        body: _filteredTasks.isEmpty
                            ? _buildEmptyState()
                            : _buildTaskList(isWide: false),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// 尺寸选择器
  Widget _buildSizeSelector(ThemeData theme) {
    final sizes = [
      {'value': 'small', 'label': '小尺寸'},
      {'value': 'medium', 'label': '中尺寸'},
      {'value': 'mediumWide', 'label': '中宽'},
      {'value': 'large', 'label': '大尺寸'},
      {'value': 'largeWide', 'label': '大宽'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: sizes.map((size) {
          final isSelected = _sizeMode == size['value'];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: ChoiceChip(
              label: Text(size['label']!),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _sizeMode = size['value']!;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    final hasFilters = _multiFilterState.hasAnyFilter || _searchKeyword.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilters ? Icons.filter_list_off : Icons.inbox,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters ? '没有匹配的任务' : '暂无任务',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withOpacity(0.6),
                ),
          ),
          if (hasFilters) ...[
            const SizedBox(height: 8),
            Text(
              '尝试调整过滤条件',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withOpacity(0.4),
                  ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建任务列表
  Widget _buildTaskList({required bool isWide}) {
    final horizontalPadding = isWide ? 16.0 : 0.0;
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
      itemCount: _filteredTasks.length,
      itemBuilder: (context, index) {
        final task = _filteredTasks[index];
        return _buildTaskCard(task, isWide: isWide);
      },
    );
  }

  /// 构建任务卡片
  Widget _buildTaskCard(_TaskItem task, {required bool isWide}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // 显示任务详情
          showDialog(
            context: context,
            builder: (context) => _TaskDetailDialog(task: task),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题和状态
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  _buildStatusChip(task.status),
                ],
              ),
              const SizedBox(height: 8),

              // 描述
              Text(
                task.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withOpacity(0.7),
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // 底部信息：优先级、标签、日期
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPriorityChip(task.priority),
                  ...task.tags.map((tag) => _buildTagChip(tag)),
                  const Spacer(),
                  _buildDateChip(task.dueDate),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建状态芯片
  Widget _buildStatusChip(_DemoTaskStatus status) {
    final (label, color) = switch (status) {
      _DemoTaskStatus.pending => ('待处理', Colors.orange),
      _DemoTaskStatus.inProgress => ('进行中', Colors.blue),
      _DemoTaskStatus.completed => ('已完成', Colors.green),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 构建优先级芯片
  Widget _buildPriorityChip(_DemoTaskPriority priority) {
    final (label, icon, color) = switch (priority) {
      _DemoTaskPriority.low => ('低', Icons.arrow_downward, Colors.green),
      _DemoTaskPriority.medium => ('中', Icons.remove, Colors.orange),
      _DemoTaskPriority.high => ('高', Icons.arrow_upward, Colors.red),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 构建标签芯片
  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  /// 构建日期芯片
  Widget _buildDateChip(DateTime date) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.calendar_today, size: 14),
        const SizedBox(width: 4),
        Text(
          '${date.month}/${date.day}',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

/// 任务详情对话框
class _TaskDetailDialog extends StatelessWidget {
  final _TaskItem task;

  const _TaskDetailDialog({required this.task});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(task.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(task.description),
          const SizedBox(height: 16),
          _buildDetailRow('状态', _getStatusText(task.status)),
          _buildDetailRow('优先级', _getPriorityText(task.priority)),
          _buildDetailRow('截止日期',
              '${task.dueDate.year}-${task.dueDate.month}-${task.dueDate.day}'),
          _buildDetailRow('标签', task.tags.join(', ')),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _getStatusText(_DemoTaskStatus status) {
    return switch (status) {
      _DemoTaskStatus.pending => '待处理',
      _DemoTaskStatus.inProgress => '进行中',
      _DemoTaskStatus.completed => '已完成',
    };
  }

  String _getPriorityText(_DemoTaskPriority priority) {
    return switch (priority) {
      _DemoTaskPriority.low => '低',
      _DemoTaskPriority.medium => '中',
      _DemoTaskPriority.high => '高',
    };
  }
}

/// 任务优先级枚举
enum _DemoTaskPriority { low, medium, high }

/// 任务状态枚举
enum _DemoTaskStatus { pending, inProgress, completed }

/// 任务数据模型
class _TaskItem {
  final String id;
  final String title;
  final String description;
  final _DemoTaskPriority priority;
  final _DemoTaskStatus status;
  final List<String> tags;
  final DateTime dueDate;

  const _TaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.tags,
    required this.dueDate,
  });
}

/// 生成示例任务数据
List<_TaskItem> _generateSampleTasks() {
  final now = DateTime.now();
  return [
    _TaskItem(
      id: '1',
      title: '完成项目文档',
      description: '编写项目的技术文档和用户手册',
      priority: _DemoTaskPriority.high,
      status: _DemoTaskStatus.inProgress,
      tags: ['工作', '文档'],
      dueDate: now.add(const Duration(days: 2)),
    ),
    _TaskItem(
      id: '2',
      title: '团队周会',
      description: '参加每周一的团队同步会议',
      priority: _DemoTaskPriority.medium,
      status: _DemoTaskStatus.pending,
      tags: ['工作', '会议'],
      dueDate: now.add(const Duration(days: 1)),
    ),
    _TaskItem(
      id: '3',
      title: '学习 Flutter 新特性',
      description: '了解 Flutter 3.0 的新功能和改进',
      priority: _DemoTaskPriority.low,
      status: _DemoTaskStatus.pending,
      tags: ['学习', '技术'],
      dueDate: now.add(const Duration(days: 7)),
    ),
    _TaskItem(
      id: '4',
      title: '健身计划',
      description: '每周至少三次健身房锻炼',
      priority: _DemoTaskPriority.medium,
      status: _DemoTaskStatus.inProgress,
      tags: ['生活', '健康'],
      dueDate: now.add(const Duration(days: 5)),
    ),
    _TaskItem(
      id: '5',
      title: '代码审查',
      description: '审查团队成员提交的 PR',
      priority: _DemoTaskPriority.high,
      status: _DemoTaskStatus.completed,
      tags: ['工作', '代码'],
      dueDate: now.subtract(const Duration(days: 1)),
    ),
    _TaskItem(
      id: '6',
      title: '购买生活用品',
      description: '购买洗发水、牙膏等日常用品',
      priority: _DemoTaskPriority.low,
      status: _DemoTaskStatus.pending,
      tags: ['生活', '购物'],
      dueDate: now.add(const Duration(days: 3)),
    ),
    _TaskItem(
      id: '7',
      title: '阅读技术书籍',
      description: '完成《Clean Code》的阅读',
      priority: _DemoTaskPriority.medium,
      status: _DemoTaskStatus.inProgress,
      tags: ['学习', '阅读'],
      dueDate: now.add(const Duration(days: 14)),
    ),
    _TaskItem(
      id: '8',
      title: '修复线上 Bug',
      description: '修复用户报告的登录问题',
      priority: _DemoTaskPriority.high,
      status: _DemoTaskStatus.pending,
      tags: ['工作', '紧急'],
      dueDate: now,
    ),
    _TaskItem(
      id: '9',
      title: '整理桌面文件',
      description: '整理电脑桌面和文档文件夹',
      priority: _DemoTaskPriority.low,
      status: _DemoTaskStatus.completed,
      tags: ['生活'],
      dueDate: now.subtract(const Duration(days: 2)),
    ),
    _TaskItem(
      id: '10',
      title: '准备演示文稿',
      description: '为下周的客户演示准备 PPT',
      priority: _DemoTaskPriority.high,
      status: _DemoTaskStatus.inProgress,
      tags: ['工作', '演示'],
      dueDate: now.add(const Duration(days: 4)),
    ),
  ];
}
