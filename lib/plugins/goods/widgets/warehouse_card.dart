import 'dart:io';
import 'package:flutter/material.dart';
import '../models/warehouse.dart';
import 'package:intl/intl.dart';
import '../../../utils/image_utils.dart';

class WarehouseCard extends StatelessWidget {
  final Warehouse warehouse;
  final VoidCallback? onTap;

  const WarehouseCard({super.key, required this.warehouse, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildCoverImage(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 96,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        warehouse.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            warehouse.icon,
                            size: 18,
                            color: warehouse.iconColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${warehouse.items.length} 件物品',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '总价值',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '¥${_formatCurrency(_calculateTotalValue())}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImage() {
    if (warehouse.imageUrl == null || warehouse.imageUrl!.isEmpty) {
      return _buildDefaultCover();
    }

    if (warehouse.imageUrl!.startsWith('http://') ||
        warehouse.imageUrl!.startsWith('https://')) {
      return SizedBox(
        height: double.infinity,
        child: Image.network(
          warehouse.imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error loading network image: $error');
            return _buildDefaultCover();
          },
        ),
      );
    }

    return FutureBuilder<String>(
      future: ImageUtils.getAbsolutePath(warehouse.imageUrl),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final file = File(snapshot.data!);
          if (file.existsSync()) {
            return SizedBox(
              height: double.infinity,
              child: Image.file(
                file,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Error loading local image: $error');
                  return _buildDefaultCover();
                },
              ),
            );
          }
        }
        return _buildDefaultCover();
      },
    );
  }

  Widget _buildDefaultCover() {
    return Container(
      decoration: BoxDecoration(
        color: warehouse.iconColor.withAlpha(204), // 0.8 * 255 ≈ 204
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            warehouse.iconColor,
            warehouse.iconColor.withAlpha(178), // 0.7 * 255 ≈ 178
          ],
        ),
      ),
      child: Center(
        child: Icon(
          warehouse.icon,
          size: 48,
          color: Colors.white.withAlpha(204), // 0.8 * 255 ≈ 204
        ),
      ),
    );
  }

  double _calculateTotalValue() {
    double total = 0;
    for (var item in warehouse.items) {
      if (item.purchasePrice != null) {
        total += item.purchasePrice!;
      }
      // 计算子物品的价值
      if (item.subItems.isNotEmpty) {
        for (var subItem in item.subItems) {
          if (subItem.purchasePrice != null) {
            total += subItem.purchasePrice!;
          }
        }
      }
    }
    return total;
  }

  String _formatCurrency(double value) {
    // 使用NumberFormat格式化货币，如果有intl包
    try {
      return NumberFormat('#,##0.00', 'zh_CN').format(value);
    } catch (e) {
      // 如果没有intl包或发生错误，使用简单格式化
      return value.toStringAsFixed(2);
    }
  }
}
