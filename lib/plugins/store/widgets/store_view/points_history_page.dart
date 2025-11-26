import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/plugins/store/l10n/store_localizations.dart';
import 'package:flutter/material.dart';
import '../../controllers/store_controller.dart';
import '../../models/points_log.dart';

/// 积分历史独立页面（包含 AppBar）
class PointsHistoryPage extends StatefulWidget {
  final StoreController controller;

  const PointsHistoryPage({super.key, required this.controller});

  @override
  State<PointsHistoryPage> createState() => _PointsHistoryPageState();
}

class _PointsHistoryPageState extends State<PointsHistoryPage> {
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
    final l10n = StoreLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => PluginManager.toHomeScreen(context),
        ),
        title: Text(l10n.pointsHistory),
        actions: [
          // 显示当前积分
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: StreamBuilder<int>(
                stream: widget.controller.pointsStream,
                initialData: widget.controller.currentPoints,
                builder: (context, snapshot) {
                  return Chip(
                    avatar: const Icon(Icons.stars, size: 18),
                    label: Text('${snapshot.data ?? 0}'),
                  );
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showClearPointsLogsConfirmation(context),
            tooltip: l10n.clear,
          ),
        ],
      ),
      body: _buildPointsHistory(),
      floatingActionButton: FloatingActionButton(
        heroTag: 'points_history_fab',
        onPressed: () => _showAddPointsDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPointsHistory() {
    if (widget.controller.pointsLogs.isEmpty) {
      return Center(
        child: Text(StoreLocalizations.of(context).noRecords),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: _displayedLogs.length +
          (_currentPage * _pageSize < widget.controller.pointsLogs.length
              ? 1
              : 0),
      itemBuilder: (context, index) {
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

  void _showAddPointsDialog(BuildContext context) {
    final pointsController = TextEditingController();
    final reasonController = TextEditingController();
    final l10n = StoreLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addPointsDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pointsController,
              decoration: InputDecoration(
                labelText: l10n.pointsAmountLabel,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: l10n.reasonLabel,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              if (pointsController.text.isNotEmpty) {
                final points = int.tryParse(pointsController.text) ?? 0;
                if (points != 0) {
                  await widget.controller.addPoints(
                    points,
                    reasonController.text.isEmpty
                        ? l10n.pointsAdjustmentDefaultReason
                        : reasonController.text,
                  );
                  await widget.controller.saveToStorage();
                  if (mounted) {
                    setState(() {});
                    _loadInitialData();
                  }
                  Navigator.pop(context);
                }
              }
            },
            child: Text(AppLocalizations.of(context)!.ok),
          ),
        ],
      ),
    );
  }

  void _showClearPointsLogsConfirmation(BuildContext context) {
    final l10n = StoreLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmClearTitle),
        content: Text(l10n.confirmClearPointsMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              await widget.controller.clearPointsLogs();
              if (mounted) {
                setState(() {});
                _loadInitialData();
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.pointsCleared),
                ),
              );
            },
            child: Text(
              l10n.clear,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
