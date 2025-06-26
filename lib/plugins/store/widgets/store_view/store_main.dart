import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/plugins/store/l10n/store_localizations.dart';
import 'package:Memento/plugins/store/store_plugin.dart';
import 'package:Memento/plugins/store/widgets/store_view/archived_products.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/store/widgets/store_view/badge_icon.dart';
import 'package:Memento/plugins/store/widgets/store_view/product_list.dart';
import 'package:Memento/plugins/store/widgets/store_view/user_items.dart';
import 'package:Memento/plugins/store/widgets/store_view/points_history.dart';
import 'package:Memento/plugins/store/widgets/add_product_page.dart';
import '../../models/product.dart';

class StoreMainView extends StatefulWidget {
  const StoreMainView({super.key});

  @override
  _StoreMainState createState() => _StoreMainState();
}

class _StoreMainState extends State<StoreMainView> {
  late StorePlugin _plugin;
  int _selectedIndex = 0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _plugin = PluginManager().getPlugin('store') as StorePlugin;
    _plugin.controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    _plugin.controller.removeListener(_onControllerUpdate);
    _pageController.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initializeData() async {
    if (!_isInitialized) {
      await _plugin.controller.loadFromStorage();
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 添加返回按钮
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => PluginManager.toHomeScreen(context),
        ),
        title: Text(
          _selectedIndex == 0
              ? StoreLocalizations.of(context)!.storeTitle
              : _selectedIndex == 1
              ? StoreLocalizations.of(context)!.myItems
              : StoreLocalizations.of(context)!.pointsHistory,
        ),
        actions: [
          if (_selectedIndex == 1)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.filter_alt),
                  onPressed: () => _navigateToFilterPage(context),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _showClearConfirmation(context),
                ),
              ],
            ),
          if (_selectedIndex == 0)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.sort),
                  onPressed: _showSortDialog,
                ),
                // 添加存档按钮
                IconButton(
                  icon: Stack(
                    children: [
                      const Icon(Icons.archive),
                      if (_plugin.controller.archivedProducts.isNotEmpty)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 12,
                              minHeight: 12,
                            ),
                            child: Text(
                              '${_plugin.controller.archivedProducts.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ArchivedProductsPage(
                              controller: _plugin.controller,
                            ),
                      ),
                    ).then((_) {
                      if (mounted) setState(() {});
                    });
                  },
                  tooltip: StoreLocalizations.of(context)!.viewArchivedProducts,
                ),
              ],
            ),
          if (_selectedIndex == 2)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showClearPointsLogsConfirmation(context),
            ),
        ],
      ),
      body: _buildCurrentPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.ease,
          );
        },
        items: [
          BottomNavigationBarItem(
            icon: StreamBuilder<int>(
              stream: _plugin.controller.productsStream,
              initialData: _plugin.controller.products.length,
              builder: (context, snapshot) {
                return BadgeIcon(
                  icon: const Icon(Icons.shopping_bag),
                  count: snapshot.data ?? 0,
                );
              },
            ),
            label: StoreLocalizations.of(context)!.productList,
          ),
          BottomNavigationBarItem(
            icon: StreamBuilder<int>(
              stream: _plugin.controller.userItemsStream,
              initialData: _plugin.controller.userItems.length,
              builder: (context, snapshot) {
                return BadgeIcon(
                  icon: const Icon(Icons.inventory),
                  count: snapshot.data ?? 0,
                );
              },
            ),
            label: StoreLocalizations.of(context)!.myItems,
          ),
          BottomNavigationBarItem(
            icon: StreamBuilder<int>(
              stream: _plugin.controller.pointsStream,
              initialData: _plugin.controller.currentPoints,
              builder: (context, snapshot) {
                return BadgeIcon(
                  icon: const Icon(Icons.history),
                  count: snapshot.data ?? 0,
                  isPoints: true,
                );
              },
            ),
            label: StoreLocalizations.of(context)!.pointsHistory,
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  final PageController _pageController = PageController();

  Widget _buildCurrentPage() {
    return PageView(
      controller: _pageController,
      onPageChanged: (index) => setState(() => _selectedIndex = index),
      children: [
        ProductList(
          controller: _plugin.controller,
          key: const PageStorageKey('product_list'),
        ),
        UserItems(controller: _plugin.controller, key: _userItemsKey),
        PointsHistory(
          controller: _plugin.controller,
          key: const PageStorageKey('points_history'),
        ),
      ],
    );
  }

  void _navigateToAddProduct(BuildContext context, {Product? product}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AddProductPage(
              controller: _plugin.controller,
              product: product,
            ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {});
        _plugin.controller.loadFromStorage(); // 重新加载数据
      }
    });
  }

  void _showAddPointsDialog(BuildContext context) {
    final pointsController = TextEditingController();
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(StoreLocalizations.of(context)!.addPointsDialogTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: pointsController,
                  decoration: InputDecoration(
                    labelText:
                        StoreLocalizations.of(context)!.pointsAmountLabel,
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    labelText: StoreLocalizations.of(context)!.reasonLabel,
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
                      await _plugin.controller.addPoints(
                        points,
                        reasonController.text.isEmpty
                            ? StoreLocalizations.of(
                              context,
                            )!.pointsAdjustmentDefaultReason
                            : reasonController.text,
                      );
                      await _plugin.controller.saveToStorage();
                      if (mounted) setState(() {});
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

  Widget _buildFloatingActionButton() {
    if (_selectedIndex == 0) {
      return _CustomFloatingButton(
        onPressed: () => _navigateToAddProduct(context),
        icon: Icons.add,
      );
    } else if (_selectedIndex == 2) {
      return _CustomFloatingButton(
        onPressed: () => _showAddPointsDialog(context),
        icon: Icons.add,
      );
    }
    return Container();
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(StoreLocalizations.of(context)!.confirmClearTitle),
            content: Text(
              StoreLocalizations.of(context)!.confirmClearItemsMessage,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () async {
                  await _plugin.controller.clearUserItems();
                  if (mounted) setState(() {});
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        StoreLocalizations.of(context)!.itemsCleared,
                      ),
                    ),
                  );
                },
                child: Text(
                  StoreLocalizations.of(context).clear,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _showClearPointsLogsConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(StoreLocalizations.of(context)!.confirmClearTitle),
            content: Text(
              StoreLocalizations.of(context)!.confirmClearPointsMessage,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () async {
                  await _plugin.controller.clearPointsLogs();
                  if (mounted) setState(() {});
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        StoreLocalizations.of(context)!.pointsCleared,
                      ),
                    ),
                  );
                },
                child: Text(
                  StoreLocalizations.of(context).clear,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  final GlobalKey<State<UserItems>> _userItemsKey = GlobalKey();

  void _navigateToFilterPage(BuildContext context) {
    int statusIndex = 0; // 0:全部, 1:可使用, 2:已过期
    String? nameFilter;
    DateTimeRange? dateRange;
    final priceMinController = TextEditingController();
    final priceMaxController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            StoreLocalizations.of(context)!.itemFilter,
            textAlign: TextAlign.left,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  StoreLocalizations.of(context)!.itemStatus,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                StatefulBuilder(
                  builder: (context, setDialogState) {
                    return Column(
                      children: [
                        RadioListTile<int>(
                          title: Text(StoreLocalizations.of(context)!.all),
                          value: 0,
                          groupValue: statusIndex,
                          onChanged: (value) {
                            setDialogState(() => statusIndex = value!);
                          },
                        ),
                        RadioListTile<int>(
                          title: Text(StoreLocalizations.of(context)!.usable),
                          value: 1,
                          groupValue: statusIndex,
                          onChanged: (value) {
                            setDialogState(() => statusIndex = value!);
                          },
                        ),
                        RadioListTile<int>(
                          title: Text(StoreLocalizations.of(context)!.expired),
                          value: 2,
                          groupValue: statusIndex,
                          onChanged: (value) {
                            setDialogState(() => statusIndex = value!);
                          },
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  StoreLocalizations.of(context)!.nameFilter,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    hintText: StoreLocalizations.of(context)!.nameFilterHint,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onChanged: (value) => nameFilter = value,
                ),
                const SizedBox(height: 24),
                Text(
                  StoreLocalizations.of(context)!.priceRange,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceMinController,
                        decoration: InputDecoration(
                          hintText:
                              StoreLocalizations.of(context)!.priceRangeHint,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: priceMaxController,
                        decoration: InputDecoration(
                          hintText:
                              StoreLocalizations.of(context)!.priceRangeHint,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  StoreLocalizations.of(context)!.dateRange,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    StoreLocalizations.of(context)!.dateRangeSelectionHint,
                  ),
                  subtitle: Text(
                    dateRange == null
                        ? StoreLocalizations.of(context)!.all
                        : '${dateRange!.start.toLocal().toString().split(' ')[0]} 至 ${dateRange!.end.toLocal().toString().split(' ')[0]}',
                  ),
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => dateRange = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () {
                // 应用名称筛选
                if (nameFilter != null && nameFilter!.isNotEmpty) {
                  _plugin.controller.applyFilters(name: nameFilter);
                }

                // 应用价格区间筛选
                final minPrice = double.tryParse(priceMinController.text);
                final maxPrice = double.tryParse(priceMaxController.text);
                if (minPrice != null && maxPrice != null) {
                  _plugin.controller.applyPriceFilter(minPrice, maxPrice);
                }

                // 更新状态筛选
                if (_userItemsKey.currentState != null) {
                  (_userItemsKey.currentState as dynamic).updateStatusFilter(
                    statusIndex,
                  );
                }

                // 刷新界面
                setState(() {});
                Navigator.pop(context);
              },
              child: Text(StoreLocalizations.of(context).apply),
            ),
          ],
        );
      },
    );
  }

  void _showSortDialog() {
    final priceRangeController = TextEditingController();
    final nameFilterController = TextEditingController();
    String? selectedSort;
    DateTimeRange? dateRange;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(StoreLocalizations.of(context)!.sortAndFilter),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  StoreLocalizations.of(context)!.sortMethod,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                RadioListTile<String>(
                  title: Text(StoreLocalizations.of(context)!.byStock),
                  value: 'stock',
                  groupValue: selectedSort,
                  onChanged: (value) => setState(() => selectedSort = value),
                ),
                RadioListTile<String>(
                  title: Text(StoreLocalizations.of(context)!.byPrice),
                  value: 'price',
                  groupValue: selectedSort,
                  onChanged: (value) => setState(() => selectedSort = value),
                ),
                RadioListTile<String>(
                  title: Text(StoreLocalizations.of(context)!.byExpiry),
                  value: 'exchangeEnd',
                  groupValue: selectedSort,
                  onChanged: (value) => setState(() => selectedSort = value),
                ),
                const Divider(),
                const Text(
                  '筛选条件',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextField(
                  controller: nameFilterController,
                  decoration: InputDecoration(
                    labelText: StoreLocalizations.of(context).nameFilter,
                    hintText: StoreLocalizations.of(context).nameFilterHint,
                  ),
                ),
                TextField(
                  controller: priceRangeController,
                  decoration: InputDecoration(
                    labelText: StoreLocalizations.of(context).priceRange,
                    hintText: StoreLocalizations.of(context).priceRangeHint,
                  ),
                  keyboardType: TextInputType.number,
                ),
                ListTile(
                  title: Text(StoreLocalizations.of(context).dateRangeTitle),
                  subtitle: Text(
                    dateRange == null
                        ? '未选择'
                        : '${dateRange!.start.toLocal().toString().split(' ')[0]} 至 ${dateRange!.end.toLocal().toString().split(' ')[0]}',
                  ),
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => dateRange = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () {
                if (selectedSort != null) {
                  _plugin.controller.sortProducts(selectedSort!);
                }
                // 应用筛选条件
                _plugin.controller.applyFilters(
                  name: nameFilterController.text,
                  priceRange: priceRangeController.text,
                  dateRange: dateRange,
                );
                setState(() {});
                Navigator.pop(context);
              },
              child: Text(StoreLocalizations.of(context).apply),
            ),
          ],
        );
      },
    );
  }
}

class _CustomFloatingButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;

  const _CustomFloatingButton({required this.onPressed, required this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Material(
        shape: const CircleBorder(),
        color: Theme.of(context).colorScheme.secondary,
        elevation: 4,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}
