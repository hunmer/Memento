import 'dart:io';

import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/plugins/store/l10n/store_localizations.dart';
import 'package:Memento/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/store/models/user_item.dart';
import 'package:Memento/plugins/store/controllers/store_controller.dart';
import 'package:Memento/core/services/toast_service.dart';

class UserItemDetailPage extends StatefulWidget {
  final StoreController controller;
  final List<UserItem> items;
  final int initialIndex;

  const UserItemDetailPage({
    super.key,
    required this.controller,
    required this.items,
    this.initialIndex = 0,
  });

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
        title: Text(StoreLocalizations.of(context).itemDetailsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.redeem),
            onPressed: () {
              final currentItem = widget.items[_currentIndex];
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: Text(
                        StoreLocalizations.of(context).useConfirmationTitle,
                      ),
                      content: Text(
                        StoreLocalizations.of(context).useConfirmationMessage
                            .replaceFirst('%s', currentItem.productName),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(AppLocalizations.of(context)!.cancel),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _useCurrentItem();
                          },
                          child: Text(AppLocalizations.of(context)!.ok),
                        ),
                      ],
                    ),
              );
            },
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
                  GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            _currentIndex == i
                                ? Theme.of(context).primaryColor
                                : Colors.grey.withValues(alpha: 0.3),
                        border: Border.all(
                          color:
                              _currentIndex == i
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color:
                                _currentIndex == i
                                    ? Colors.white
                                    : Colors.grey[700],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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
            child:
                item.productImage.isEmpty
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
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          const Icon(
                                            Icons.broken_image,
                                            size: 48,
                                          ),
                                )
                                : Image.file(
                                  File(imagePath),
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          const Icon(
                                            Icons.broken_image,
                                            size: 48,
                                          ),
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
            label: StoreLocalizations.of(context).productNameLabel,
            value: item.productName,
          ),
          _buildDetailRow(
            icon: Icons.calendar_today,
            label: StoreLocalizations.of(context).purchaseDateLabel,
            value: _formatDate(item.purchaseDate),
          ),
          _buildDetailRow(
            icon: Icons.calendar_today,
            label: StoreLocalizations.of(context).expiryDateLabel,
            value: _formatDate(item.expireDate),
          ),
          _buildDetailRow(
            icon: Icons.attach_money,
            label: StoreLocalizations.of(context).purchasePriceLabel,
            value:
                '${item.purchasePrice}${StoreLocalizations.of(context).points}',
          ),
          _buildDetailRow(
            icon: Icons.layers,
            label: StoreLocalizations.of(context).remainingQuantityLabel,
            value: '${item.remaining}',
          ),
          const SizedBox(height: 20),
          // 物品描述
          if (item.productSnapshot['description'] != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  StoreLocalizations.of(context).descriptionLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
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
          Text(StoreLocalizations.of(context).labelColon(label), style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _useCurrentItem() async {
    final item = widget.items[_currentIndex];
    if (await widget.controller.useItem(item)) {
      Navigator.pop(context);
      Toast.success(StoreLocalizations.of(context).useSuccessMessage);
    } else {
      Toast.error(StoreLocalizations.of(context).itemExpiredMessage);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool isNetworkImage(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }
}
