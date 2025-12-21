import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../widgets/super_cupertino_navigation_wrapper.dart';
import '../models/subscription.dart';
import '../bill_plugin.dart';
import 'subscription_edit_screen.dart';
import 'package:Memento/widgets/smooth_bottom_sheet.dart';

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

  // 搜索相关状态
  String _searchQuery = '';
  final Map<String, bool> _searchFilters = {
    'name': true, // 是否搜索名称
    'category': true, // 是否搜索分类
  };

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

  List<Subscription> _filterSubscriptions(List<Subscription> subscriptions) {
    if (_searchQuery.isEmpty) {
      return subscriptions;
    }

    final query = _searchQuery.toLowerCase();
    return subscriptions.where((subscription) {
      // 按名称搜索
      final matchName =
          _searchFilters['name'] == true &&
          subscription.name.toLowerCase().contains(query);

      // 按分类搜索
      final matchCategory =
          _searchFilters['category'] == true &&
          subscription.category.toLowerCase().contains(query);

      return matchName || matchCategory;
    }).toList();
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
    final activeSubscriptions = _filterSubscriptions(
      subscriptions.where((s) => s.isActive).toList(),
    );
    final inactiveSubscriptions = _filterSubscriptions(
      subscriptions.where((s) => !s.isActive).toList(),
    );

    return SuperCupertinoNavigationWrapper(
      title: Text('bill_subscription'.tr),
      largeTitle: 'bill_subscription'.tr,
      enableSearchBar: true,
      searchPlaceholder: '搜索订阅服务...',
      onSearchChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      enableSearchFilter: true,
      filterLabels: const {'name': '名称', 'category': '分类'},
      onSearchFilterChanged: (filters) {
        setState(() {
          _searchFilters.addAll(filters);
        });
      },
      searchBody: _buildSearchBody(),
      body: _buildMainBody(activeSubscriptions, inactiveSubscriptions),
      actions: [
        IconButton(
          icon: Icon(
            _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
          ),
          tooltip:
              _isGridView
                  ? 'bill_switchToListView'.tr
                  : 'bill_switchToGridView'.tr,
          onPressed: _toggleViewMode,
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _navigateToEdit(),
        ),
      ],
    );
  }

  Widget _buildMainBody(
    List<Subscription> activeSubscriptions,
    List<Subscription> inactiveSubscriptions,
  ) {
    final allSubscriptions = [...activeSubscriptions, ...inactiveSubscriptions];

    if (allSubscriptions.isEmpty) {
      return _buildEmptyState();
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        if (activeSubscriptions.isNotEmpty) ...[
          _buildSectionHeader(
            '${"bill_activeSubscriptions".tr} (${activeSubscriptions.length})',
          ),
          _buildSubscriptionList(activeSubscriptions),
        ],
        if (inactiveSubscriptions.isNotEmpty) ...[
          _buildSectionHeader(
            '${"bill_inactiveSubscriptions".tr} (${inactiveSubscriptions.length})',
          ),
          _buildSubscriptionList(inactiveSubscriptions, isInactive: true),
        ],
        const SliverToBoxAdapter(
          child: SizedBox(height: 80),
        ), // Bottom padding for FAB
      ],
    );
  }

  Widget _buildSearchBody() {
    final subscriptions =
        widget.billPlugin.controller.subscriptions.subscriptions;
    final filteredSubscriptions = _filterSubscriptions(subscriptions);

    if (_searchQuery.isNotEmpty && filteredSubscriptions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '未找到匹配的订阅服务',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (filteredSubscriptions.isEmpty) {
      return _buildEmptyState();
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildSubscriptionList(filteredSubscriptions),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildSubscriptionList(
    List<Subscription> subscriptions, {
    bool isInactive = false,
  }) {
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
                onTap:
                    () => _navigateToEdit(subscription: subscriptions[index]),
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
            'bill_noSubscriptions'.tr,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'bill_clickToAddSubscription'.tr,
            style: TextStyle(color: Colors.grey.shade500),
          ),
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
    SmoothBottomSheet.show(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text('bill_edit'.tr),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToEdit(subscription: subscription);
                },
              ),
              if (subscription.isActive)
                ListTile(
                  leading: const Icon(Icons.stop_circle_outlined),
                  title: Text('bill_terminateSubscription'.tr),
                  onTap: () {
                    Navigator.pop(context);
                    _showTerminateDialog(subscription);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(
                  'bill_delete'.tr,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteDialog(subscription);
                },
              ),
            ],
          ),
    );
  }

  void _showTerminateDialog(Subscription subscription) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('bill_terminateSubscription'.tr),
            content: Text(
              'bill_terminateConfirm'.tr.replaceAll(
                '{name}',
                subscription.name,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('bill_cancel'.tr),
              ),
              ElevatedButton(
                onPressed: () {
                  widget.billPlugin.controller.subscriptions
                      .terminateSubscription(subscription.id);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('bill_save'.tr),
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
            title: Text('bill_deleteSubscription'.tr),
            content: Text(
              'bill_deleteConfirm'.tr.replaceAll('{name}', subscription.name),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('bill_cancel'.tr),
              ),
              ElevatedButton(
                onPressed: () {
                  widget.billPlugin.controller.subscriptions.deleteSubscription(
                    subscription.id,
                  );
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('bill_delete'.tr),
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
    if (days >= 360) return 'bill_yearly'.tr;
    if (days >= 28) return 'bill_monthly'.tr;
    if (days == 7) return 'bill_weekly'.tr;
    return '$days ${"bill_days".tr}';
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
                      color:
                          isInactive
                              ? Colors.grey.withOpacity(0.1)
                              : color.withOpacity(0.1),
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
                                  Icon(
                                    Icons.event,
                                    size: 12,
                                    color: theme.hintColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${"bill_nextDate".tr} ${DateFormat('MMM d, yyyy').format(nextDate)}',
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
                                            color: theme.disabledColor
                                                .withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              3,
                                            ),
                                          ),
                                          child: FractionallySizedBox(
                                            alignment: Alignment.centerLeft,
                                            widthFactor: subscription.progress
                                                .clamp(0.0, 1.0),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: color,
                                                borderRadius:
                                                    BorderRadius.circular(3),
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
                                      'bill_autoRenew'.tr,
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
    if (days >= 360) return 'bill_yearly'.tr;
    if (days >= 28) return 'bill_monthly'.tr;
    if (days == 7) return 'bill_weekly'.tr;
    return '$days ${"bill_days".tr}';
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
                              '${"bill_nextDate".tr} ${DateFormat('MMM d').format(nextDate)}',
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
                                'bill_autoRenew'.tr,
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
