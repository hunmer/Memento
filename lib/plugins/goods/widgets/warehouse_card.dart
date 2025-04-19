import 'dart:io';
import 'package:flutter/material.dart';
import '../models/warehouse.dart';
import 'package:intl/intl.dart';

class WarehouseCard extends StatelessWidget {
  final Warehouse warehouse;
  final VoidCallback? onTap;

  const WarehouseCard({super.key, required this.warehouse, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: _buildIcon()),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(
                    warehouse.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${warehouse.items.length} 件物品',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      if (_calculateTotalValue() > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '¥${_formatCurrency(_calculateTotalValue())}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    // 如果有图片，优先显示图片
    if (warehouse.imageUrl != null && warehouse.imageUrl!.isNotEmpty) {
      return AspectRatio(
        aspectRatio: 1.0,
        child:
            warehouse.imageUrl!.startsWith('file://')
                ? Image.file(
                  File(warehouse.imageUrl!.replaceFirst('file://', '')),
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => _buildDefaultIcon(),
                )
                : Image.network(
                  warehouse.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => _buildDefaultIcon(),
                ),
      );
    }

    // 否则显示图标
    return _buildDefaultIcon();
  }

  Widget _buildDefaultIcon() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: warehouse.iconColor,
      ),
      child: Icon(warehouse.icon, size: 48, color: Colors.white),
    );
  }

  double _calculateTotalValue() {
    double total = 0;
    for (var item in warehouse.items) {
      if (item.purchasePrice != null) {
        total += item.purchasePrice!;
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
