import 'package:flutter/material.dart';
import '../../controllers/store_controller.dart';
import '../../models/points_log.dart';

class PointsHistory extends StatefulWidget {
  final StoreController controller;

  const PointsHistory({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  _PointsHistoryState createState() => _PointsHistoryState();
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
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
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
          final end = (start + _pageSize <= widget.controller.pointsLogs.length)
              ? start + _pageSize
              : widget.controller.pointsLogs.length;
          
          if (_currentPage == 0) {
            _displayedLogs = widget.controller.pointsLogs.sublist(start, end);
          } else {
            _displayedLogs.addAll(widget.controller.pointsLogs.sublist(start, end));
          }
          
          _currentPage++;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _showClearConfirmation() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认清空'),
          content: const Text('确定要清空所有积分记录吗？'),
          actions: [
            TextButton(
              child: const Text('取消'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('确定'),
              onPressed: () {
                widget.controller.clearPointsLogs();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller.pointsLogs.isEmpty) {
      return const Center(child: Text('暂无记录'));
    }
    
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(8),
            itemCount: _displayedLogs.length + (_currentPage * _pageSize < widget.controller.pointsLogs.length ? 1 : 0),
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
                  title: Text('${log.value}积分 (${log.type})'),
                  subtitle: Text(log.reason),
                  trailing: Text(
                    '${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
