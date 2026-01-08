import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/route/route_history_manager.dart';
import 'package:Memento/core/route/page_visit_record.dart';

/// 路由历史记录对话框
///
/// 显示最近访问的页面列表，用户可以点击快速跳转
class RouteHistoryDialog extends StatefulWidget {
  const RouteHistoryDialog({super.key});

  @override
  State<RouteHistoryDialog> createState() => _RouteHistoryDialogState();
}

class _RouteHistoryDialogState extends State<RouteHistoryDialog> {
  List<PageVisitRecord> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 获取最近10条历史记录
      final history = RouteHistoryManager.getHistory(limit: 10);
      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('加载路由历史失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 打开指定页面
  Future<void> _openPage(PageVisitRecord record) async {
    // 关闭对话框
    if (!mounted) return;
    Navigator.of(context).pop();

    // 使用路由路径直接跳转（不再需要手动记录历史，NavigatorObserver 会自动处理）
    final result = await Navigator.pushNamed(context, record.pageId);

    // 如果路由跳转失败，显示提示
    if (result == null && mounted) {
      // 某些路由可能返回 null，这不算失败
      // 但如果需要处理错误，可以在这里添加逻辑
    }
  }

  /// 清空历史记录
  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
            title: Text(
              'widget_confirmClear'.tr,
            ),
            content: Text(
              'widget_confirmEmptyHistory'.tr,
            ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
                child: Text('widget_cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
                child: Text('widget_confirm'.tr),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await RouteHistoryManager.clearHistory();
      _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.history,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'widget_routeHistory'.tr,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // 清空按钮
                  if (_history.isNotEmpty)
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      onPressed: _clearHistory,
                      tooltip: 'widget_clearHistory'.tr,
                    ),
                  // 关闭按钮
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // 内容区域
            Flexible(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : _history.isEmpty
                      ? _buildEmptyState()
                      : _buildHistoryList(),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'widget_noHistory'.tr,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'widget_visitPageAutoRecord'.tr,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建历史记录列表
  Widget _buildHistoryList() {
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _history.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final record = _history[index];
        return _buildHistoryItem(record);
      },
    );
  }

  /// 构建单个历史记录项
  Widget _buildHistoryItem(PageVisitRecord record) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Icon(
          record.icon ?? Icons.description,
          color: theme.colorScheme.onPrimaryContainer,
          size: 20,
        ),
      ),
      title: Text(
        record.title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Row(
        children: [
          Icon(
            Icons.access_time,
            size: 14,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(width: 4),
          Text(
            record.getRelativeTime(),
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.touch_app,
            size: 14,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(width: 4),
          Text(
            'widget_visits'.trParams({'count': record.visitCount.toString()}),
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
      onTap: () => _openPage(record),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.outline,
      ),
    );
  }
}
