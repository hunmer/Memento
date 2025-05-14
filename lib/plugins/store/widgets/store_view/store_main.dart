import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/store/widgets/store_view/archived_products.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/store/widgets/store_view/badge_icon.dart';
import 'package:Memento/plugins/store/widgets/store_view/product_list.dart';
import 'package:Memento/plugins/store/widgets/store_view/user_items.dart';
import 'package:Memento/plugins/store/widgets/store_view/points_history.dart';
import 'package:Memento/plugins/store/widgets/add_product_page.dart';
import '../../controllers/store_controller.dart';
import '../../models/product.dart';

class StoreMain extends StatefulWidget {
  final StoreController controller;

  const StoreMain({
    Key? key, 
    required this.controller,
  }) : super(key: key);

  @override
  _StoreMainState createState() => _StoreMainState();
}

class _StoreMainState extends State<StoreMain> {
  int _selectedIndex = 0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
    // 添加控制器监听
    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
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
      await widget.controller.loadFromStorage();
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
        title: Text(_selectedIndex == 0 
          ? '积分商城' 
          : _selectedIndex == 1 
            ? '我的物品'
            : '积分记录'),
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
                      if (widget.controller.archivedProducts.isNotEmpty)
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
                              '${widget.controller.archivedProducts.length}',
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
                        builder: (context) => ArchivedProductsPage(
                          controller: widget.controller,
                        ),
                      ),
                    ).then((_) {
                      if (mounted) setState(() {});
                    });
                  },
                  tooltip: '查看存档商品',
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
              stream: widget.controller.productsStream,
              initialData: widget.controller.products.length,
              builder: (context, snapshot) {
                return BadgeIcon(
                  icon: const Icon(Icons.shopping_bag),
                  count: snapshot.data ?? 0,
                );
              },
            ),
            label: '商品列表',
          ),
          BottomNavigationBarItem(
            icon: StreamBuilder<int>(
              stream: widget.controller.userItemsStream,
              initialData: widget.controller.userItems.length,
              builder: (context, snapshot) {
                return BadgeIcon(
                  icon: const Icon(Icons.inventory),
                  count: snapshot.data ?? 0,
                );
              },
            ),
            label: '我的物品',
          ),
          BottomNavigationBarItem(
            icon: StreamBuilder<int>(
              stream: widget.controller.pointsStream,
              initialData: widget.controller.currentPoints,
              builder: (context, snapshot) {
                return BadgeIcon(
                  icon: const Icon(Icons.history),
                  count: snapshot.data ?? 0,
                  isPoints: true,
                );
              },
            ),
            label: '积分记录',
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
          controller: widget.controller,
          key: const PageStorageKey('product_list'),
        ),
        UserItems(
          controller: widget.controller,
          key: _userItemsKey,
        ),
        PointsHistory(
          controller: widget.controller,
          key: const PageStorageKey('points_history'),
        ),
      ],
    );
  }

  void _navigateToAddProduct(BuildContext context, {Product? product}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductPage(
          controller: widget.controller,
          product: product,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _showAddPointsDialog(BuildContext context) {
    final pointsController = TextEditingController();
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加积分'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pointsController,
              decoration: const InputDecoration(labelText: '积分数量'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: '原因'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              if (pointsController.text.isNotEmpty) {
                final points = int.tryParse(pointsController.text) ?? 0;
                if (points > 0) {
                  await widget.controller.addPoints(
                    points,
                    reasonController.text.isEmpty ? '积分调整' : reasonController.text,
                  );
                  await widget.controller.saveToStorage();
                  if (mounted) setState(() {});
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('确认'),
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
      builder: (context) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('确定要清空所有物品记录吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await widget.controller.clearUserItems();
              if (mounted) setState(() {});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已清空物品记录')),
              );
            },
            child: const Text('清空', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  void _showClearPointsLogsConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('确定要清空所有积分记录吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await widget.controller.clearPointsLogs();
              if (mounted) setState(() {});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已清空积分记录')),
              );
            },
            child: const Text('清空', style: TextStyle(color: Colors.red)),
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
          title: const Text('物品筛选', textAlign: TextAlign.left),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('物品状态', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                StatefulBuilder(
                  builder: (context, setDialogState) {
                    return Column(
                      children: [
                        RadioListTile<int>(
                          title: const Text('全部'),
                          value: 0,
                          groupValue: statusIndex,
                          onChanged: (value) {
                            setDialogState(() => statusIndex = value!);
                          },
                        ),
                        RadioListTile<int>(
                          title: const Text('可使用'),
                          value: 1,
                          groupValue: statusIndex,
                          onChanged: (value) {
                            setDialogState(() => statusIndex = value!);
                          },
                        ),
                        RadioListTile<int>(
                          title: const Text('已过期'),
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
                const Text('名称筛选', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    hintText: '输入物品名称关键词',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (value) => nameFilter = value,
                ),
                const SizedBox(height: 24),
                const Text('价格区间', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceMinController,
                        decoration: const InputDecoration(
                          hintText: '最低价',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: priceMaxController,
                        decoration: const InputDecoration(
                          hintText: '最高价',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('日期范围', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('选择日期范围'),
                  subtitle: Text(dateRange == null 
                    ? '未选择' 
                    : '${dateRange!.start.toLocal().toString().split(' ')[0]} 至 ${dateRange!.end.toLocal().toString().split(' ')[0]}'),
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
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                // 应用名称筛选
                if (nameFilter != null && nameFilter!.isNotEmpty) {
                  widget.controller.applyFilters(name: nameFilter);
                }
                
                // 应用价格区间筛选
                final minPrice = double.tryParse(priceMinController.text);
                final maxPrice = double.tryParse(priceMaxController.text);
                if (minPrice != null && maxPrice != null) {
                  widget.controller.applyPriceFilter(minPrice, maxPrice);
                }
                
                // 更新状态筛选
                if (_userItemsKey.currentState != null) {
                  (_userItemsKey.currentState as dynamic).updateStatusFilter(statusIndex);
                }
                
                // 刷新界面
                setState(() {});
                Navigator.pop(context);
              },
              child: const Text('应用'),
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
          title: const Text('排序与筛选'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('排序方式', style: TextStyle(fontWeight: FontWeight.bold)),
                RadioListTile<String>(
                  title: const Text('按库存数'),
                  value: 'stock',
                  groupValue: selectedSort,
                  onChanged: (value) => setState(() => selectedSort = value),
                ),
                RadioListTile<String>(
                  title: const Text('按单价'),
                  value: 'price',
                  groupValue: selectedSort,
                  onChanged: (value) => setState(() => selectedSort = value),
                ),
                RadioListTile<String>(
                  title: const Text('按有效兑换期'),
                  value: 'exchangeEnd',
                  groupValue: selectedSort,
                  onChanged: (value) => setState(() => selectedSort = value),
                ),
                const Divider(),
                const Text('筛选条件', style: TextStyle(fontWeight: FontWeight.bold)),
                TextField(
                  controller: nameFilterController,
                  decoration: const InputDecoration(
                    labelText: '名称筛选',
                    hintText: '输入商品名称关键词',
                  ),
                ),
                TextField(
                  controller: priceRangeController,
                  decoration: const InputDecoration(
                    labelText: '价格范围',
                    hintText: '例如: 100-500',
                  ),
                  keyboardType: TextInputType.number,
                ),
                ListTile(
                  title: const Text('日期范围'),
                  subtitle: Text(dateRange == null 
                    ? '未选择' 
                    : '${dateRange!.start.toLocal().toString().split(' ')[0]} 至 ${dateRange!.end.toLocal().toString().split(' ')[0]}'),
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
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (selectedSort != null) {
                  widget.controller.sortProducts(selectedSort!);
                }
                // 应用筛选条件
                widget.controller.applyFilters(
                  name: nameFilterController.text,
                  priceRange: priceRangeController.text,
                  dateRange: dateRange,
                );
                setState(() {});
                Navigator.pop(context);
              },
              child: const Text('应用'),
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

  const _CustomFloatingButton({
    required this.onPressed,
    required this.icon,
  });

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
