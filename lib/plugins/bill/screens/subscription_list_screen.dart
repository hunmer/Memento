import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription.dart';
import '../bill_plugin.dart';
import 'subscription_edit_screen.dart';

class SubscriptionListScreen extends StatefulWidget {
  final BillPlugin billPlugin;

  const SubscriptionListScreen({super.key, required this.billPlugin});

  @override
  State<SubscriptionListScreen> createState() => _SubscriptionListScreenState();
}

class _SubscriptionListScreenState extends State<SubscriptionListScreen> {
  late final void Function() _listener;
  bool _isGridView = true;
  static const String _viewModeKey = 'subscription_list_view_mode_grid';

  @override
  void initState() {
    super.initState();
    _loadViewMode();
    _listener = () {
      if (mounted) setState(() {});
    };
    widget.billPlugin.controller.subscriptions.addListener(_listener);
  }

  Future<void> _loadViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isGridView = prefs.getBool(_viewModeKey) ?? true;
      });
    }
  }

  Future<void> _toggleViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    final newValue = !_isGridView;
    await prefs.setBool(_viewModeKey, newValue);
    if (mounted) {
      setState(() {
        _isGridView = newValue;
      });
    }
  }

  @override
  void dispose() {
    widget.billPlugin.controller.subscriptions.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subscriptions =
        widget.billPlugin.controller.subscriptions.subscriptions;
    final activeSubscriptions = subscriptions.where((s) => s.isActive).toList();
    final inactiveSubscriptions =
        subscriptions.where((s) => !s.isActive).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          '订阅服务',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
            tooltip: _isGridView ? 'Switch to List View' : 'Switch to Grid View',
            onPressed: _toggleViewMode,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToEdit(),
          ),
        ],
      ),
      body:
          subscriptions.isEmpty
              ? _buildEmptyState()
              : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  if (activeSubscriptions.isNotEmpty) ...[
                    _buildSectionHeader('活跃订阅 (${activeSubscriptions.length})'),
                    _buildSubscriptionList(activeSubscriptions),
                  ],
                  if (inactiveSubscriptions.isNotEmpty) ...[
                    _buildSectionHeader(
                      '已终止 (${inactiveSubscriptions.length})',
                    ),
                    _buildSubscriptionList(inactiveSubscriptions, isInactive: true),
                  ],
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 80),
                  ), // Bottom padding for FAB
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEdit(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSubscriptionList(List<Subscription> subscriptions, {bool isInactive = false}) {
    if (_isGridView) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            return _SubscriptionCard(
              subscription: subscriptions[index],
              onTap: () => _navigateToEdit(subscription: subscriptions[index]),
              onLongPress: () => _showMenuDialog(subscriptions[index]),
              isInactive: isInactive,
            );
          }, childCount: subscriptions.length),
        ),
      );
    } else {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SubscriptionListTile(
                subscription: subscriptions[index],
                onTap: () => _navigateToEdit(subscription: subscriptions[index]),
                onLongPress: () => _showMenuDialog(subscriptions[index]),
                isInactive: isInactive,
              ),
            );
          }, childCount: subscriptions.length),
        ),
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.subscriptions_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无订阅服务',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text('点击下方按钮添加订阅服务', style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  void _navigateToEdit({Subscription? subscription}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => SubscriptionEditScreen(
              billPlugin: widget.billPlugin,
              subscription: subscription,
            ),
      ),
    );
  }

  void _showMenuDialog(Subscription subscription) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('编辑'),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToEdit(subscription: subscription);
                  },
                ),
                if (subscription.isActive)
                  ListTile(
                    leading: const Icon(Icons.stop_circle_outlined),
                    title: const Text('终止订阅'),
                    onTap: () {
                      Navigator.pop(context);
                      _showTerminateDialog(subscription);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('删除', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteDialog(subscription);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showTerminateDialog(Subscription subscription) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('终止订阅'),
            content: Text('确定要终止"${subscription.name}"吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  widget.billPlugin.controller.subscriptions
                      .terminateSubscription(subscription.id);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('确定'),
              ),
            ],
          ),
    );
  }

  void _showDeleteDialog(Subscription subscription) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('删除订阅'),
            content: Text('确定要删除"${subscription.name}"吗？此操作不可撤销。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  widget.billPlugin.controller.subscriptions.deleteSubscription(
                    subscription.id,
                  );
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('删除'),
              ),
            ],
          ),
    );
  }
}

class _SubscriptionListTile extends StatelessWidget {
  final Subscription subscription;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isInactive;

  const _SubscriptionListTile({
    required this.subscription,
    required this.onTap,
    required this.onLongPress,
    this.isInactive = false,
  });

  String _getFrequencyText(int days) {
    if (days >= 360) return 'Yearly';
    if (days >= 28) return 'Monthly';
    if (days == 7) return 'Weekly';
    return '$days Days';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isInactive ? Colors.grey : subscription.iconColor;
    final frequency = _getFrequencyText(subscription.days);
    final nextDate =
        subscription.isActive
            ? DateTime.now().add(Duration(days: subscription.remainingDays))
            : null;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        height: 128,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.dividerColor.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Decorative background icon
            Positioned(
              right: -24,
              bottom: -24,
              child: Transform.rotate(
                angle: 0.2,
                child: Icon(
                  subscription.icon,
                  size: 160,
                  color: color.withOpacity(0.05),
                ),
              ),
            ),

            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Colors.transparent, color.withOpacity(0.05)],
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon Box
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isInactive ? Colors.grey.withOpacity(0.1) : color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(subscription.icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  
                  // Info Column
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                subscription.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        // Price & Frequency
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Text(
                                '¥${subscription.totalAmount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade400,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  frequency,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),

                        // Footer Row: Next Date & Progress
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Next Date
                            if (nextDate != null)
                              Row(
                                children: [
                                  Icon(Icons.event, size: 12, color: theme.hintColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Next: ${DateFormat('MMM d, yyyy').format(nextDate)}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: theme.hintColor,
                                    ),
                                  ),
                                ],
                              ),
                            
                            const Spacer(),

                            // Progress & Auto Badge
                            Row(
                              children: [
                                // Progress Bar
                                SizedBox(
                                  width: 80,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: theme.disabledColor.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                          child: FractionallySizedBox(
                                            alignment: Alignment.centerLeft,
                                            widthFactor: subscription.progress.clamp(0.0, 1.0),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: color,
                                                borderRadius: BorderRadius.circular(3),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${(subscription.progress * 100).toInt()}%',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                
                                // Auto Badge
                                if (subscription.isActive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Auto-renew',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.blue.shade400,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final Subscription subscription;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isInactive;

  const _SubscriptionCard({
    required this.subscription,
    required this.onTap,
    required this.onLongPress,
    this.isInactive = false,
  });

  String _getFrequencyText(int days) {
    if (days >= 360) return 'Yearly';
    if (days >= 28) return 'Monthly';
    if (days == 7) return 'Weekly';
    return '$days Days';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isInactive ? Colors.grey : subscription.iconColor;
    final frequency = _getFrequencyText(subscription.days);
    final nextDate =
        subscription.isActive
            ? DateTime.now().add(Duration(days: subscription.remainingDays))
            : null;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.dividerColor.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Decorative background icon
            Positioned(
              right: -16,
              bottom: -16,
              child: Transform.rotate(
                angle: 0.2, // ~12 degrees
                child: Icon(
                  subscription.icon,
                  size: 96,
                  color: color.withOpacity(0.05),
                ),
              ),
            ),

            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.transparent, color.withOpacity(0.05)],
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Icon Box
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color:
                              isInactive
                                  ? Colors.grey.withOpacity(0.1)
                                  : color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(subscription.icon, color: color, size: 24),
                      ),
                      // Price & Frequency
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              frequency,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '¥${subscription.totalAmount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      subscription.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // Footer (Progress & Info)
                  Column(
                    children: [
                      Divider(
                        height: 1,
                        color: theme.dividerColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 8),
                      // Date Row
                      if (nextDate != null)
                        Row(
                          children: [
                            Icon(Icons.event, size: 12, color: theme.hintColor),
                            const SizedBox(width: 4),
                            Text(
                              'Next: ${DateFormat('MMM d').format(nextDate)}',
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      // Progress Bar Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Bar
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: theme.disabledColor.withOpacity(
                                        0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: subscription.progress.clamp(
                                        0.0,
                                        1.0,
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${(subscription.progress * 100).toInt()}%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Badge
                          if (subscription.isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Auto',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue.shade400,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

