import 'package:get/get.dart';
import 'package:Memento/plugins/database/widgets/record_edit_widget.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/widgets/smooth_bottom_sheet.dart';
import 'package:Memento/plugins/database/controllers/database_controller.dart';
import 'package:Memento/plugins/database/models/database_model.dart';
import 'package:Memento/plugins/database/widgets/database_edit_widget.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper/index.dart';
import '../models/record.dart' as record_model;

/// 记录排序选项
enum RecordSortOption {
  /// 更新时间降序（最新的在前）
  updatedDesc,
  /// 更新时间升序
  updatedAsc,
  /// 创建时间降序
  createdDesc,
  /// 创建时间升序
  createdAsc,
}

class DatabaseDetailWidget extends StatefulWidget {
  final DatabaseController controller;
  final String databaseId;

  const DatabaseDetailWidget({
    super.key,
    required this.controller,
    required this.databaseId,
  });

  @override
  State<DatabaseDetailWidget> createState() => _DatabaseDetailWidgetState();
}

class _DatabaseDetailWidgetState extends State<DatabaseDetailWidget> {
  late Future<void> _loadingFuture;
  bool _isGridView = false;

  /// 所有记录列表
  List<record_model.Record> _allRecords = [];

  /// 过滤后的记录列表
  List<record_model.Record> _filteredRecords = [];

  /// 当前搜索关键词
  String _searchKeyword = '';

  /// 多条件过滤状态
  final MultiFilterState _multiFilterState = MultiFilterState();

  /// 数据是否需要重新加载
  bool _needsReload = true;


  @override
  void initState() {
    super.initState();
    _loadingFuture = widget.controller.loadDatabase(widget.databaseId);
  }

  @override
  void dispose() {
    _multiFilterState.dispose();
    super.dispose();
  }

  /// 构建多条件过滤项
  List<FilterItem> _buildFilterItems() {
    return [
      // 1. 日期范围过滤（基于更新时间）
      FilterItem(
        id: 'dateRange',
        title: '日期',
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

      // 2. 排序方式
      FilterItem(
        id: 'sort',
        title: '排序',
        type: FilterType.custom,
        builder: (context, currentValue, onChanged) {
          return _buildSortFilter(context, currentValue, onChanged);
        },
        getBadge: (value) {
          if (value == null) return null;
          final option = value as RecordSortOption;
          return switch (option) {
            RecordSortOption.updatedDesc => '最新更新',
            RecordSortOption.updatedAsc => '最早更新',
            RecordSortOption.createdDesc => '最新创建',
            RecordSortOption.createdAsc => '最早创建',
          };
        },
        initialValue: RecordSortOption.updatedDesc,
      ),
    ];
  }

  /// 构建排序选择器
  Widget _buildSortFilter(
    BuildContext context,
    dynamic currentValue,
    ValueChanged<dynamic> onChanged,
  ) {
    final option = currentValue as RecordSortOption? ?? RecordSortOption.updatedDesc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('排序方式', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        SegmentedButton<RecordSortOption>(
          segments: const [
            ButtonSegment(
              value: RecordSortOption.updatedDesc,
              label: Text('最新更新'),
              icon: Icon(Icons.arrow_downward, size: 16),
            ),
            ButtonSegment(
              value: RecordSortOption.updatedAsc,
              label: Text('最早更新'),
              icon: Icon(Icons.arrow_upward, size: 16),
            ),
            ButtonSegment(
              value: RecordSortOption.createdDesc,
              label: Text('最新创建'),
            ),
            ButtonSegment(
              value: RecordSortOption.createdAsc,
              label: Text('最早创建'),
            ),
          ],
          selected: {option},
          onSelectionChanged: (Set<RecordSortOption> newSelection) {
            onChanged(newSelection.first);
          },
        ),
      ],
    );
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

  /// 计算过滤后的记录列表（不调用setState）
  List<record_model.Record> _computeFilteredRecords(
    List<record_model.Record> records,
    Map<String, dynamic> filters,
    String keyword,
  ) {
    var result = List<record_model.Record>.from(records);

    // 关键词过滤 - 搜索所有字段值
    if (keyword.isNotEmpty) {
      final lowerKeyword = keyword.toLowerCase();
      result = result.where((record) {
        // 搜索 title 字段
        if (record.fields['title']?.toString().toLowerCase().contains(lowerKeyword) == true) {
          return true;
        }
        // 搜索所有其他字段值
        return record.fields.values.any((value) =>
          value?.toString().toLowerCase().contains(lowerKeyword) == true);
      }).toList();
    }

    // 日期范围过滤（基于 updatedAt）
    if (filters['dateRange'] != null) {
      final range = filters['dateRange'] as DateTimeRange;
      result = result
          .where((record) =>
              !record.updatedAt.isBefore(range.start) &&
              !record.updatedAt.isAfter(range.end))
          .toList();
    }

    // 排序
    final sortOption = filters['sort'] as RecordSortOption? ?? RecordSortOption.updatedDesc;

    switch (sortOption) {
      case RecordSortOption.updatedDesc:
        result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case RecordSortOption.updatedAsc:
        result.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      case RecordSortOption.createdDesc:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case RecordSortOption.createdAsc:
        result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    return result;
  }

  /// 应用过滤条件（调用setState）
  void _applyFilters(Map<String, dynamic> filters, String keyword) {
    _filteredRecords = _computeFilteredRecords(_allRecords, filters, keyword);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final database = widget.controller.currentDatabase!;

        // 加载记录数据
        return FutureBuilder<List<record_model.Record>>(
          future: widget.controller.getRecords(database.id),
          builder: (context, recordSnapshot) {
            if (recordSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final records = recordSnapshot.data ?? [];

            // 初始化或更新记录列表（不在build中调用setState）
            if (_needsReload || _allRecords.length != records.length) {
              _allRecords = records;
              _needsReload = false;
              // 直接计算过滤结果，不调用setState
              _filteredRecords = _computeFilteredRecords(
                _allRecords,
                _multiFilterState.getAllValues(),
                _searchKeyword,
              );
            }

            return _buildSuperCupertinoContent(database);
          },
        );
      },
    );
  }

  Widget _buildSuperCupertinoContent(DatabaseModel database) {
    return SuperCupertinoNavigationWrapper(
      title: Text(database.name),
      largeTitle: database.name,
      automaticallyImplyLeading: true,

      // 顶部操作按钮
      actions: [
        IconButton(
          icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
          onPressed: () {
            setState(() {
              _isGridView = !_isGridView;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            NavigationHelper.push(
              context,
              DatabaseEditWidget(
                controller: widget.controller,
                database: database,
              ),
            ).then((_) => setState(() {}));
          },
        ),
      ],

      // 启用搜索栏
      enableSearchBar: true,
      searchPlaceholder: '搜索记录...',
      onSearchChanged: _onSearchChanged,

      // 启用多条件过滤
      enableMultiFilter: true,
      multiFilterItems: _buildFilterItems(),
      multiFilterBarHeight: 50,
      onMultiFilterChanged: _onMultiFilterChanged,

      // 主体内容（包含浮动按钮）
      body: Stack(
        children: [
          // 主要内容
          _filteredRecords.isEmpty
              ? _buildEmptyState()
              : _isGridView ? _buildGridView(database) : _buildListView(database),

          // 浮动操作按钮
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: 'database_detail_fab',
              onPressed: () async {
                final result = await NavigationHelper.push(
                  context,
                  RecordEditWidget(
                    controller: widget.controller,
                    database: database,
                    record: null,
                  ),
                );
                if (result != null) {
                  setState(() {
                    _needsReload = true;
                  });
                }
              },
              child: const Icon(Icons.add),
            ),
          ),
        ],
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
            hasFilters ? '没有匹配的记录' : '暂无记录',
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

  Widget _buildListView(DatabaseModel database) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredRecords.length,
      itemBuilder: (context, index) {
        final record = _filteredRecords[index];
        return _buildRecordCard(database, record);
      },
    );
  }

  /// 构建记录卡片（列表模式）
  Widget _buildRecordCard(DatabaseModel database, record_model.Record record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          NavigationHelper.push(
            context,
            RecordEditWidget(
              controller: widget.controller,
              database: database,
              record: record,
            ),
          ).then((_) => setState(() {
            _needsReload = true;
          }));
        },
        onLongPress: () {
          _showRecordMenu(context, record);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Text(
                record.fields['title']?.toString() ?? 'database_untitled_record'.tr,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),

              // 更新时间
              Text(
                '更新于 ${_formatDateTime(record.updatedAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withOpacity(0.6),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridView(DatabaseModel database) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: _filteredRecords.length,
      itemBuilder: (context, index) {
        final record = _filteredRecords[index];
        return Card(
          child: InkWell(
            onTap: () {
              NavigationHelper.push(
                context,
                RecordEditWidget(
                  controller: widget.controller,
                  database: database,
                  record: record,
                ),
              ).then((_) => setState(() {
                _allRecords.clear();
              }));
            },
            onLongPress: () {
              _showRecordMenu(context, record);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (record.fields['image'] != null)
                    Image.network(record.fields['image'], height: 80),
                  if (record.fields['image'] != null) const SizedBox(height: 8),
                  Text(
                    record.fields['title']?.toString() ??
                        'database_untitled_record'.tr,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(record.updatedAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withOpacity(0.6),
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '今天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return '昨天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    record_model.Record record,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('database_delete_record_title'.tr),
        content: Text(
          'database_delete_record_message'.trParams({
            'name': record.fields['title'] ?? 'database_untitled_record'.tr,
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('database_cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('database_delete'.tr),
          ),
        ],
      ),
    ).then((value) => value ?? false);
  }

  Future<void> _deleteRecord(record_model.Record record) async {
    await widget.controller.deleteRecord(record.id);
    _allRecords.removeWhere((r) => r.id == record.id);
    _applyFilters(_multiFilterState.getAllValues(), _searchKeyword);
  }

  void _showRecordMenu(BuildContext context, record_model.Record record) {
    SmoothBottomSheet.show(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text('database_edit'.tr),
              onTap: () {
                Navigator.of(context).pop();
                _editRecord(context, record);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: Text('database_delete'.tr),
              onTap: () async {
                Navigator.of(context).pop();
                final shouldDelete = await _confirmDelete(context, record);
                if (shouldDelete) {
                  await _deleteRecord(record);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _editRecord(BuildContext context, record_model.Record record) {
    NavigationHelper.push(
      context,
      RecordEditWidget(
        controller: widget.controller,
        database: widget.controller.currentDatabase!,
        record: record,
      ),
    ).then((_) => setState(() {
      _needsReload = true;
    }));
  }
}
