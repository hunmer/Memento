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
  }

  Future<void> _initializeData() async {
    if (!_isInitialized) {
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('物品兑换'),
        actions: [
          if (_selectedIndex == 1)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showClearConfirmation(context),
            ),
          if (_selectedIndex == 0 || _selectedIndex == 1)
            IconButton(
              icon: const Icon(Icons.sort),
              onPressed: _showSortDialog,
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
            icon: BadgeIcon(
              icon: const Icon(Icons.shopping_bag),
              count: widget.controller.products.length,
            ),
            label: '商品列表',
          ),
          BottomNavigationBarItem(
            icon: BadgeIcon(
              icon: const Icon(Icons.inventory),
              count: widget.controller.userItems.length,
            ),
            label: '我的物品',
          ),
          BottomNavigationBarItem(
            icon: BadgeIcon(
              icon: const Icon(Icons.history),
              count: widget.controller.currentPoints,
              isPoints: true,
            ),
            label: '积分记录',
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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
          key: const PageStorageKey('user_items'),
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

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('排序方式'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('按库存数'),
                onTap: () {
                  widget.controller.sortProducts('stock');
                  setState(() {});
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('按单价'),
                onTap: () {
                  widget.controller.sortProducts('price');
                  setState(() {});
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('按有效兑换期'),
                onTap: () {
                  widget.controller.sortProducts('exchangeEnd');
                  setState(() {});
                  Navigator.pop(context);
                },
              ),
            ],
          ),
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
