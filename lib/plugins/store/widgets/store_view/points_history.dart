import 'package:Memento/plugins/store/l10n/store_localizations.dart';
import 'package:flutter/material.dart';
import '../../controllers/store_controller.dart';
import '../../models/points_log.dart';
import '../../../../widgets/super_cupertino_navigation_wrapper.dart';

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
      _loadMoreData();
    });
  }

  void _loadMoreData() {
    if (_isLoading) return;
    if (_currentPage * _pageSize >= widget.controller.pointsLogs.length) return;

    setState(() {
      _isLoading = true;
    });

    // 模拟异步加载
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          final start = _currentPage * _pageSize;
          final end =
              (start + _pageSize <= widget.controller.pointsLogs.length)
                  ? start + _pageSize
                  : widget.controller.pointsLogs.length;

          if (_currentPage == 0) {
            _displayedLogs = widget.controller.pointsLogs.sublist(start, end);
          } else {
            _displayedLogs.addAll(
              widget.controller.pointsLogs.sublist(start, end),
            );
          }

          _currentPage++;
          _isLoading = false;
        });
      }
    });
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
      largeTitle: StoreLocalizations.of(context).pointsHistory,
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
              StoreLocalizations.of(context).noRecords,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '完成应用内活动即可获得积分',
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
      largeTitle: StoreLocalizations.of(context).pointsHistory,
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
                  (_currentPage * _pageSize < widget.controller.pointsLogs.length ? 1 : 0),
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
                      StoreLocalizations.of(context).pointsHistoryEntry
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
      enableSearchBar: false,
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
        title: const Text('清空积分记录'),
        content: const Text('确定要清空所有积分历史记录吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await widget.controller.clearPointsLogs();
              _loadInitialData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('积分记录已清空')),
                );
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
