
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/goods/widgets/goods_item_form/index.dart';
import '../models/user_item.dart';
import '../models/product.dart';

class UserItemCard extends StatelessWidget {
  final UserItem item;
  final int count;
  final VoidCallback onUse;

  const UserItemCard({
    Key? key,
    required this.item,
    required this.count,
    required this.onUse,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 物品图片
              AspectRatio(
                aspectRatio: 16 / 9,
                child: item.productImage.isEmpty 
                    ? _buildErrorImage()
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
                                          _buildErrorImage(),
                                    )
                                  : Image.file(
                                      File(imagePath),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          _buildErrorImage(),
                                    );
                            }
                            return _buildErrorImage();
                          }
                          return _buildLoadingIndicator();
                        },
                      ),
              ),
              // 物品信息
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '物品ID: ${item.id}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '剩余使用次数: ${item.remaining}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '同类物品数: $count',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '有效期至: ${_formatDate(item.expireDate)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // 使用按钮
          Positioned(
            bottom: 12,
            right: 12,
            child: FloatingActionButton.small(
              onPressed: onUse,
              child: const Icon(Icons.check),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool isNetworkImage(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  Widget _buildLoadingIndicator() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorImage() {
    return const Icon(Icons.broken_image, size: 48);
  }
}
