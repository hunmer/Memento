import 'package:Memento/plugins/store/l10n/store_localizations.dart';
import 'package:flutter/material.dart';
import '../../controllers/store_controller.dart';
import '../../models/points_log.dart';

/// 积分历史内容组件（不包含 Scaffold，用于 TabBarView）
class PointsHistoryContent extends StatefulWidget {
  final StoreController controller;

  const PointsHistoryContent({super.key, required this.controller});

  @override
  State<PointsHistoryContent> createState() => _PointsHistoryContentState();
}

class _PointsHistoryContentState extends State<PointsHistoryContent> {
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
      _displayedLogs = [];
      _loadMoreData();
    });
  }

  void _loadMoreData() {
    if (_isLoading) return;
    if (_currentPage * _pageSize >= widget.controller.pointsLogs.length) return;

    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          final start = _currentPage * _pageSize;
          final end = (start + _pageSize <= widget.controller.pointsLogs.length)
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
      return Center(child: Text(StoreLocalizations.of(context).noRecords));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: _displayedLogs.length +
          (_currentPage * _pageSize < widget.controller.pointsLogs.length
              ? 1
              : 0),
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
          child: ListTile(
            leading: Icon(
              log.type == '获得' ? Icons.add : Icons.remove,
              color: log.type == '获得' ? Colors.green : Colors.red,
            ),
            title: Text(
              StoreLocalizations.of(context)
                  .pointsHistoryEntry
                  .replaceFirst('{value}', log.value.toString())
                  .replaceFirst('{type}', log.type),
            ),
            subtitle: Text(log.reason),
            trailing: Text(
              '${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}',
            ),
          ),
        );
      },
    );
  }
}