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
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(flex: 2, child: _buildCoverImage()),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Icon(
                          warehouse.icon,
                          color: warehouse.iconColor,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            warehouse.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${warehouse.items.length} 件物品',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    if (_calculateTotalValue() > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.monetization_on_outlined,
                            size: 16,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '¥${_formatCurrency(_calculateTotalValue())}',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
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
      if (item.subItems != null && item.subItems!.isNotEmpty) {
        for (var subItem in item.subItems!) {
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
