import 'dart:io';

import 'package:Memento/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/store/models/user_item.dart';
import 'package:Memento/plugins/store/controllers/store_controller.dart';

class UserItemDetailPage extends StatefulWidget {
  final StoreController controller;
  final List<UserItem> items;
  final int initialIndex;

  const UserItemDetailPage({
    Key? key,
    required this.controller,
    required this.items,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  _UserItemDetailPageState createState() => _UserItemDetailPageState();
}

class _UserItemDetailPageState extends State<UserItemDetailPage> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('物品详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _useCurrentItem,
          ),
        ],
      ),
      body: Column(
        children: [
          // 分页指示器
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < widget.items.length; i++)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == i 
                          ? Theme.of(context).primaryColor 
                          : Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
          // 分页视图
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.items.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                final item = widget.items[index];
                return _buildItemDetail(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemDetail(UserItem item) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 物品图片
          AspectRatio(
            aspectRatio: 16 / 9,
            child: item.productImage.isEmpty 
                ? const Icon(Icons.broken_image, size: 48)
                : FutureBuilder<String>(
                    future: ImageUtils.getAbsolutePath(item.productImage),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        if (snapshot.hasData) {
                          final imagePath = snapshot.data!;
                          return isNetworkImage(imagePath)
                              ? Image.network(
                                  imagePath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image, size: 48),
                                )
                              : Image.file(
                                  File(imagePath),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image, size: 48),
                                );
                        }
                      }
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
          ),
          const SizedBox(height: 20),
          // 物品信息
          _buildDetailRow(
            icon: Icons.shopping_bag,
            label: '物品名称',
            value: item.productName,
          ),
          _buildDetailRow(
            icon: Icons.calendar_today,
            label: '购买日期',
            value: _formatDate(item.purchaseDate),
          ),
          _buildDetailRow(
            icon: Icons.calendar_today,
            label: '过期日期',
            value: _formatDate(item.expireDate),
          ),
          _buildDetailRow(
            icon: Icons.attach_money,
            label: '购买价格',
            value: '${item.purchasePrice}积分',
          ),
          _buildDetailRow(
            icon: Icons.layers,
            label: '剩余数量',
            value: '${item.remaining}',
          ),
          const SizedBox(height: 20),
          // 物品描述
          if (item.productSnapshot['description'] != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '物品描述',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(item.productSnapshot['description']),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _useCurrentItem() async {
    final item = widget.items[_currentIndex];
    if (await widget.controller.useItem(item)) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('使用成功')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('物品已过期')),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool isNetworkImage(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }
}
