import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/subscription.dart';
import '../controls/subscription_controller.dart';
import '../bill_plugin.dart';
import 'subscription_edit_screen.dart';

class SubscriptionListScreen extends StatefulWidget {
  final BillPlugin billPlugin;

  const SubscriptionListScreen({
    super.key,
    required this.billPlugin,
  });

  @override
  State<SubscriptionListScreen> createState() => _SubscriptionListScreenState();
}

class _SubscriptionListScreenState extends State<SubscriptionListScreen> {
  late final void Function() _listener;

  @override
  void initState() {
    super.initState();
    _listener = () {
      if (mounted) setState(() {});
    };
    widget.billPlugin.controller.subscriptions.addListener(_listener);
  }

  @override
  void dispose() {
    widget.billPlugin.controller.subscriptions.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subscriptions = widget.billPlugin.controller.subscriptions.subscriptions;
    final activeSubscriptions = subscriptions.where((s) => s.isActive).toList();
    final inactiveSubscriptions = subscriptions.where((s) => !s.isActive).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('订阅服务'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _navigateToEdit(),
          ),
        ],
      ),
      body: subscriptions.isEmpty
          ? _buildEmptyState()
          : ListView(
              children: [
                if (activeSubscriptions.isNotEmpty) ...[
                  _buildSectionHeader('活跃订阅 (${activeSubscriptions.length})'),
                  ...activeSubscriptions.map((subscription) =>
                    _buildSubscriptionTile(subscription)
                  ),
                ],
                if (inactiveSubscriptions.isNotEmpty) ...[
                  _buildSectionHeader('已终止 (${inactiveSubscriptions.length})'),
                  ...inactiveSubscriptions.map((subscription) =>
                    _buildSubscriptionTile(subscription, isInactive: true)
                  ),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEdit(),
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.subscriptions, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            '暂无订阅服务',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            '点击下方按钮添加订阅服务',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSubscriptionTile(Subscription subscription, {bool isInactive = false}) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: subscription.iconColor.withOpacity(0.2),
          child: Icon(subscription.icon, color: subscription.iconColor),
        ),
        title: Text(subscription.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('总金额: ¥${subscription.totalAmount.toStringAsFixed(2)}'),
            Text('单日: ¥${subscription.dailyAmount.toStringAsFixed(2)} / 天'),
            Text('进度: ${(subscription.progress * 100).toStringAsFixed(0)}% (${subscription.completedDays}/${subscription.days}天)'),
            if (subscription.remainingDays > 0)
              Text('剩余: ${subscription.remainingDays}天'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, subscription),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Text('编辑'),
            ),
            if (subscription.isActive)
              PopupMenuItem(
                value: 'terminate',
                child: Text('终止订阅'),
              ),
            PopupMenuItem(
              value: 'delete',
              child: Text('删除', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEdit({Subscription? subscription}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SubscriptionEditScreen(
          billPlugin: widget.billPlugin,
          subscription: subscription,
        ),
      ),
    );
  }

  void _handleMenuAction(String action, Subscription subscription) {
    switch (action) {
      case 'edit':
        _navigateToEdit(subscription: subscription);
        break;
      case 'terminate':
        _showTerminateDialog(subscription);
        break;
      case 'delete':
        _showDeleteDialog(subscription);
        break;
    }
  }

  void _showTerminateDialog(Subscription subscription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('终止订阅'),
        content: Text('确定要终止"${subscription.name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.billPlugin.controller.subscriptions.terminateSubscription(subscription.id);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Subscription subscription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除订阅'),
        content: Text('确定要删除"${subscription.name}"吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.billPlugin.controller.subscriptions.deleteSubscription(subscription.id);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('删除'),
          ),
        ],
      ),
    );
  }
}
