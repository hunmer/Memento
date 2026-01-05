import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/store/controllers/store_controller.dart';
import 'package:Memento/plugins/store/models/points_log.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper/filter_models.dart';
import 'package:Memento/core/services/toast_service.dart';

/// 排序顺序枚举
enum SortOrder {
  newestFirst,
  oldestFirst,
}

class PointsHistory extends StatefulWidget {
  final StoreController controller;

  const PointsHistory({super.key, required this.controller});

  @override
  State<PointsHistory> createState() => _PointsHistoryState();
}

class _PointsHistoryState extends State<PointsHistory> {
  static const int _pageSize = 30;
  int _currentPage = 0;
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  List<PointsLog> _displayedLogs = [];

  // 搜索和过滤状态
  String _searchQuery = '';
  Map<String, dynamic> _filters = {};
  SortOrder _sortOrder = SortOrder.newestFirst;
  List<PointsLog> _filteredLogs = []; // 完整的过滤后数据

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_scrollListener);
    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) {
      _loadInitialData();
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading) {
      _loadMoreData();
    }
  }

  void _loadInitialData() {
    setState(() {
      _currentPage = 0;
      _displayedLogs.clear();
      // 更新完整的过滤后数据
      _filteredLogs = _applyFilters(widget.controller.pointsLogs);
    });
    _loadMoreData();
  }

  /// 应用搜索和过滤条件到原始数据
  List<PointsLog> _applyFilters(List<PointsLog> originalLogs) {
    var filtered = List<PointsLog>.from(originalLogs);

    // 搜索过滤（按理由）
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((log) => log.reason.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // 类型过滤（获得/消耗）
    final types = _filters['type'] as List<String>?;
    if (types != null && types.isNotEmpty) {
      filtered = filtered.where((log) => types.contains(log.type)).toList();
    }

    // 日期范围过滤
    final dateRange = _filters['dateRange'] as DateTimeRange?;
    if (dateRange != null) {
      filtered = filtered
          .where((log) =>
              !log.timestamp.isBefore(dateRange.start) &&
              !log.timestamp.isAfter(dateRange.end))
          .toList();
    }

    // 排序
    switch (_sortOrder) {
      case SortOrder.newestFirst:
        filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        break;
      case SortOrder.oldestFirst:
        filtered.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        break;
    }

    return filtered;
  }

  void _loadMoreData() {
    if (_isLoading) return;
    if (_currentPage * _pageSize >= _filteredLogs.length) return;

    setState(() {
      _isLoading = true;
    });

    // 模拟异步加载
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          final start = _currentPage * _pageSize;
          final end = (start + _pageSize <= _filteredLogs.length)
              ? start + _pageSize
              : _filteredLogs.length;

          if (_currentPage == 0) {
            _displayedLogs = _filteredLogs.sublist(start, end);
          } else {
            _displayedLogs.addAll(
              _filteredLogs.sublist(start, end),
            );
          }

          _currentPage++;
          _isLoading = false;
        });
      }
    });
  }

  /// 搜索回调
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 0;
      _displayedLogs.clear();
      // 更新完整的过滤后数据
      _filteredLogs = _applyFilters(widget.controller.pointsLogs);
    });
    _loadMoreData();
  }

  /// 多条件过滤回调
  void _onMultiFilterChanged(Map<String, dynamic> filters) {
    setState(() {
      _filters = filters;
      // 从过滤器中获取排序设置
      final sortOrder = filters['sortOrder'] as String?;
      if (sortOrder == 'oldestFirst') {
        _sortOrder = SortOrder.oldestFirst;
      } else {
        _sortOrder = SortOrder.newestFirst;
      }
      _currentPage = 0;
      _displayedLogs.clear();
      // 更新完整的过滤后数据
      _filteredLogs = _applyFilters(widget.controller.pointsLogs);
    });
    _loadMoreData();
  }

  /// 构建多条件过滤项
  List<FilterItem> _buildMultiFilterItems() {
    return [
      // 类型过滤（获得/消耗）
      FilterItem(
        id: 'type',
        title: 'store_type'.tr,
        type: FilterType.tagsMultiple,
        initialValue: const ['获得', '消耗'],
        builder: (context, value, onChanged) {
          final selected = value as List<String>? ?? ['获得', '消耗'];
          return Wrap(
            spacing: 8,
            children: ['获得', '消耗'].map((type) {
              final isSelected = selected.contains(type);
              return FilterChip(
                label: Text(type),
                selected: isSelected,
                onSelected: (bool isCurrentlySelected) {
                  final newSelected = List<String>.from(selected);
                  if (isCurrentlySelected) {
                    if (!newSelected.contains(type)) newSelected.add(type);
                  } else {
                    newSelected.remove(type);
                  }
                  onChanged(newSelected);
                },
                selectedColor: Colors.green.withValues(alpha: 0.3),
                checkmarkColor: Colors.green,
              );
            }).toList(),
          );
        },
        getBadge: (value) {
          final selected = value as List<String>? ?? [];
          if (selected.length == 2 || selected.isEmpty) return null;
          return selected.length.toString();
        },
      ),
      // 日期范围过滤
      FilterItem(
        id: 'dateRange',
        title: 'store_dateRange'.tr,
        type: FilterType.dateRange,
        initialValue: null,
        builder: (context, value, onChanged) {
          final range = value as DateTimeRange?;
          return TextButton.icon(
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 30)),
                initialDateRange: range,
                locale: const Locale('zh', 'CN'),
              );
              if (picked != null) {
                onChanged(picked);
              }
            },
            icon: const Icon(Icons.calendar_today),
            label: Text(
              range == null
                  ? 'store_selectDateRange'.tr
                  : '${range.start.month}/${range.start.day} - ${range.end.month}/${range.end.day}',
            ),
          );
        },
        getBadge: (value) => value != null ? '1' : null,
      ),
      // 排序选项
      FilterItem(
        id: 'sortOrder',
        title: 'store_sort'.tr,
        type: FilterType.tagsSingle,
        initialValue: 'newestFirst',
        builder: (context, value, onChanged) {
          final selected = value as String? ?? 'newestFirst';
          return Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: Text('store_newestFirst'.tr),
                selected: selected == 'newestFirst',
                onSelected: (_) => onChanged('newestFirst'),
                selectedColor: Colors.blue.withValues(alpha: 0.3),
              ),
              FilterChip(
                label: Text('store_oldestFirst'.tr),
                selected: selected == 'oldestFirst',
                onSelected: (_) => onChanged('oldestFirst'),
                selectedColor: Colors.blue.withValues(alpha: 0.3),
              ),
            ],
          );
        },
        getBadge: (value) => null,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller.pointsLogs.isEmpty) {
      return _buildEmptyView();
    }

    return _buildHistoryView();
  }

  Widget _buildEmptyView() {
    return SuperCupertinoNavigationWrapper(
      title: Icon(
        Icons.history,
        color: Colors.green.shade600,
        size: 24,
      ),
      largeTitle: 'store_pointsHistory'.tr,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'store_noRecords'.tr,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'store_earnPointsTip'.tr,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
      enableLargeTitle: true,
      enableSearchBar: false,
    );
  }

  Widget _buildHistoryView() {
    final totalEarned = widget.controller.pointsLogs
        .where((log) => log.type == '获得')
        .fold<int>(0, (sum, log) => sum + log.value);
    final totalSpent = widget.controller.pointsLogs
        .where((log) => log.type == '消耗')
        .fold<int>(0, (sum, log) => sum + log.value);

    return SuperCupertinoNavigationWrapper(
      title: Icon(
        Icons.history,
        color: Colors.green.shade600,
        size: 24,
      ),
      largeTitle: 'store_pointsHistory'.tr,
      body: Column(
        children: [
          // 统计信息
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        '当前积分',
                        widget.controller.currentPoints.toString(),
                        Colors.purple,
                        Icons.account_balance_wallet,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        '总获得',
                        '+$totalEarned',
                        Colors.green,
                        Icons.add_circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        '总消耗',
                        '-$totalSpent',
                        Colors.red,
                        Icons.remove_circle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 积分历史列表
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              itemCount: _displayedLogs.length +
                  (_currentPage * _pageSize < _filteredLogs.length ? 1 : 0),
              itemBuilder: (context, index) {
                // 如果是最后一个项目且还有更多数据可加载，显示加载指示器
                if (index == _displayedLogs.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final log = _displayedLogs[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: log.type == '获得' ? Colors.green.shade100 : Colors.red.shade100,
                      child: Icon(
                        log.type == '获得' ? Icons.add : Icons.remove,
                        color: log.type == '获得' ? Colors.green : Colors.red,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'store_pointsHistoryEntry'.tr
                          .replaceFirst('{value}', log.value.toString())
                          .replaceFirst('{type}', log.type),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    subtitle: Text(
                      log.reason,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '${log.timestamp.month}/${log.timestamp.day}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      enableLargeTitle: true,
      enableSearchBar: true,
      enableMultiFilter: true,
      multiFilterItems: _buildMultiFilterItems(),
      searchPlaceholder: 'store_searchReason'.tr,
      onSearchChanged: _onSearchChanged,
      onMultiFilterChanged: _onMultiFilterChanged,
      actions: [
        TextButton(
          onPressed: () {
            _showClearLogsDialog(context);
          },
          child: Text(
            '清空',
            style: TextStyle(
              color: Colors.red[400],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showClearLogsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('store_clearPointsHistory'.tr),
        content: Text('store_confirmClearPointsHistory'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('store_cancel'.tr),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await widget.controller.clearPointsLogs();
              _loadInitialData();
              if (mounted) {
                Toast.success('积分记录已清空');
              }
            },
            child: Text(
              '确定',
              style: TextStyle(color: Colors.red[400]),
            ),
          ),
        ],
      ),
    );
  }
}
