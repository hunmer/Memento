
import 'package:Memento/plugins/store/widgets/user_item_card.dart';
import 'package:Memento/plugins/store/widgets/add_product_page.dart';
import 'package:flutter/material.dart';
import '../controllers/store_controller.dart';
import '../models/product.dart';
import 'product_card.dart';

class StoreView extends StatefulWidget {
  final StoreController controller;
  final Function(List<Product>, int)? onDataChanged;

  const StoreView({
    Key? key, 
    required this.controller,
    this.onDataChanged,
  }) : super(key: key);

  @override
  _StoreViewState createState() => _StoreViewState();
}

class _StoreViewState extends State<StoreView> {
  int _selectedIndex = 0;

  Widget _buildBadgeIcon({
    required Widget icon,
    required int count,
    bool isPoints = false,
  }) {
    return Stack(
      children: [
        icon,
        if (count > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                isPoints ? count.toString() : count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('物品兑换'),
        actions: [
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
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: _buildBadgeIcon(
              icon: const Icon(Icons.shopping_bag),
              count: widget.controller.products.length,
            ),
            label: '商品列表',
          ),
          BottomNavigationBarItem(
            icon: _buildBadgeIcon(
              icon: const Icon(Icons.inventory),
              count: widget.controller.userItems.length,
            ),
            label: '我的物品',
          ),
          BottomNavigationBarItem(
            icon: _buildBadgeIcon(
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

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildProductList();
      case 1:
        return _buildUserItems();
      case 2:
        return _buildPointsHistory();
      default:
        return Container();
    }
  }

  void _navigateToAddProduct(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductPage(
          controller: widget.controller,
          onDataChanged: widget.onDataChanged,
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
            onPressed: () {
              if (pointsController.text.isNotEmpty && 
                  reasonController.text.isNotEmpty) {
                widget.controller.addPoints(
                  int.parse(pointsController.text),
                  reasonController.text,
                );
                setState(() {
                  widget.onDataChanged?.call(
                    widget.controller.products,
                    widget.controller.currentPoints,
                  );
                });
                Navigator.pop(context);
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
      return FloatingActionButton(
        onPressed: () => _navigateToAddProduct(context),
        child: const Icon(Icons.add),
      );
    } else if (_selectedIndex == 2) {
      return FloatingActionButton(
        onPressed: () => _showAddPointsDialog(context),
        child: const Icon(Icons.add),
      );
    }
    return Container();
  }

  Widget _buildProductList() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: widget.controller.products.length,
      itemBuilder: (context, index) {
        final product = widget.controller.products[index];
        return ProductCard(
          product: product,
          onExchange: () {
            if (widget.controller.exchangeProduct(product)) {
              setState(() {
                widget.onDataChanged?.call(
                  widget.controller.products,
                  widget.controller.currentPoints,
                );
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('兑换成功')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('兑换失败，请检查积分或库存')),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildUserItems() {
    if (widget.controller.userItems.isEmpty) {
      return const Center(child: Text('暂无物品'));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: widget.controller.userItems.length,
      itemBuilder: (context, index) {
        final item = widget.controller.userItems[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: UserItemCard(
            item: item,
            onUse: () {
              if (widget.controller.useItem(item)) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('使用成功')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('物品已过期')),
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildPointsHistory() {
    if (widget.controller.pointsLogs.isEmpty) {
      return const Center(child: Text('暂无记录'));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: widget.controller.pointsLogs.length,
      itemBuilder: (context, index) {
        final log = widget.controller.pointsLogs[index];
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
