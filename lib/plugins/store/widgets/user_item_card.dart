import 'package:get/get.dart';

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/goods/widgets/goods_item_form/index.dart';
import 'package:Memento/plugins/store/models/user_item.dart';

class UserItemCard extends StatelessWidget {
  final UserItem item;
  final int count;
  final VoidCallback onUse;

  const UserItemCard({
    super.key,
    required this.item,
    required this.count,
    required this.onUse,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final isExpired = now.isAfter(item.expireDate);
    final daysUntilExpire = item.expireDate.difference(now).inDays;
    final isExpiringSoon = daysUntilExpire <= 7 && daysUntilExpire >= 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (!isExpired) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('store_confirmUse'.tr),
                  content: Text(
                    'store_confirmUseMessage'.tr
                        .replaceFirst('%s', item.productName),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('app_cancel'.tr),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onUse();
                      },
                      child: Text('app_confirm'.tr),
                    ),
                  ],
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.only(
              left: 12,
              right: 12,
              top: 12,
              bottom: 8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section with Badge
                Stack(
                  children: [
                    SizedBox(
                      height: 100, // 给图片区域固定高度
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Center(  // 添加居中对齐
                          child: item.productImage.isEmpty
                              ? _buildErrorImage()
                              : FutureBuilder<String>(
                                  future: ImageUtils.getAbsolutePath(item.productImage),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.done) {
                                      if (snapshot.hasData) {
                                        final imagePath = snapshot.data!;
                                        return isNetworkImage(imagePath)
                                            ? Image.network(
                                                imagePath,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (context, error, stackTrace) =>
                                                        _buildErrorImage(),
                                              )
                                            : Image.file(
                                                File(imagePath),
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (context, error, stackTrace) =>
                                                        _buildErrorImage(),
                                              );
                                      }
                                      return _buildErrorImage();
                                    }
                                    return _buildLoadingIndicator();
                                  },
                                ),
                        ),
                      ),
                    ),
                    // Badge showing count
                    if (count > 1)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    // Expiry Status Badge
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isExpired
                              ? Colors.red
                              : isExpiringSoon
                                  ? Colors.orange
                                  : Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isExpired
                              ? '已过期'
                              : isExpiringSoon
                                  ? '即将过期'
                                  : '有效',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Title
                Text(
                  item.productName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Purchase Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '💰',
                          style: TextStyle(
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '购买价格',
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                    Text(
                      '${item.purchasePrice}积分',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Remaining Uses
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '🔢',
                          style: TextStyle(
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '剩余次数',
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isExpired
                            ? Colors.grey
                            : theme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${item.remaining}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Divider
                Divider(height: 1, color: theme.dividerColor.withOpacity(0.2)),
                const SizedBox(height: 8),

                // Purchase Date & Expiry Date
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '购买日期',
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                        ),
                        Text(
                          _formatDate(item.purchaseDate),
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '过期日期',
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                        ),
                        Text(
                          _formatDate(item.expireDate),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: isExpired
                                ? Colors.red
                                : isExpiringSoon
                                    ? Colors.orange
                                    : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Days Until Expiry
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '剩余天数',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isExpired
                                ? Colors.grey
                                : isExpiringSoon
                                    ? Colors.orange
                                    : Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isExpired
                              ? '已过期'
                              : '$daysUntilExpire天',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: isExpired
                                ? Colors.grey
                                : isExpiringSoon
                                    ? Colors.orange
                                    : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().substring(2)}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  bool isNetworkImage(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  Widget _buildLoadingIndicator() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorImage() {
    return Container(
      color: Colors.grey[200],
      width: double.infinity,
      height: double.infinity,
      child: const Icon(
        Icons.broken_image,
        size: 48,
        color: Colors.grey,
      ),
    );
  }
}
