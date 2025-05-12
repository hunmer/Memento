
import 'package:Memento/plugins/store/widgets/user_item_card.dart';
import 'package:flutter/material.dart';
import '../controllers/store_controller.dart';
import 'product_card.dart';

class StoreView extends StatefulWidget {
  final StoreController controller;

  const StoreView({Key? key, required this.controller}) : super(key: key);

  @override
  _StoreViewState createState() => _StoreViewState();
}

class _StoreViewState extends State<StoreView> {
  int _selectedIndex = 0;

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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: '商品列表',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: '我的物品',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
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

  Widget _buildFloatingActionButton() {
    if (_selectedIndex == 0) {
      return FloatingActionButton(
        onPressed: () {
          // TODO: 跳转到添加商品页面
        },
        child: const Icon(Icons.add),
      );
    } else if (_selectedIndex == 2) {
      return FloatingActionButton(
        onPressed: () {
          // TODO: 跳转到添加积分页面
        },
        child: const Icon(Icons.add),
      );
    }
    return Container();
  }

  Widget _buildProductList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: widget.controller.products.length,
      itemBuilder: (context, index) {
        final product = widget.controller.products[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ProductCard(
            product: product,
            onExchange: () {
              if (widget.controller.exchangeProduct(product)) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('兑换成功')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('兑换失败，请检查积分或库存')),
                );
              }
            },
          ),
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
