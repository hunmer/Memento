import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'dart:io';
import 'package:Memento/plugins/goods/models/goods_item.dart';
import 'package:Memento/plugins/goods/dialogs/add_usage_record_dialog.dart';
import 'package:Memento/plugins/goods/screens/goods_item_history_page.dart';
import 'package:Memento/plugins/goods/goods_plugin.dart';

class GoodsItemCard extends StatefulWidget {
  final GoodsItem item;
  final String? warehouseTitle;
  final String? warehouseId;
  final VoidCallback? onTap;

  const GoodsItemCard({
    super.key,
    required this.item,
    this.warehouseTitle,
    this.warehouseId,
    this.onTap,
  });

  @override
  State<GoodsItemCard> createState() => _GoodsItemCardState();
}

class _GoodsItemCardState extends State<GoodsItemCard> {
  String? _resolvedImageUrl;

  @override
  void initState() {
    super.initState();
    _resolveImageUrl();
  }

  @override
  void didUpdateWidget(GoodsItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.imageUrl != widget.item.imageUrl ||
        oldWidget.item.thumbUrl != widget.item.thumbUrl) {
      _resolveImageUrl();
    }
  }

  Future<void> _resolveImageUrl() async {
    if (widget.item.imageUrl != null) {
      try {
        // 优先使用缩略图进行预览
        final url = await widget.item.getThumbUrl() ?? await widget.item.getImageUrl();
        if (mounted) {
          setState(() {
            _resolvedImageUrl = url;
          });
        }
      } catch (e) {
        debugPrint('获取图片URL失败: $e');
        if (mounted) {
          setState(() {
            _resolvedImageUrl = null;
          });
        }
      }
    }
  }

  void _showMenu() {
    if (widget.warehouseId == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: Text('goods_addUsageRecord'.tr),
            onTap: () async {
              Navigator.pop(context); // Close menu
              final result = await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (context) => const AddUsageRecordDialog(),
              );
              if (result != null) {
                final updatedItem = widget.item.addUsageRecord(
                  result['date'],
                  note: result['note'],
                  duration: result['duration'],
                  location: result['location'],
                );
                await GoodsPlugin.instance.saveGoodsItem(widget.warehouseId!, updatedItem);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: Text('goods_usageHistory'.tr),
            onTap: () {
              Navigator.pop(context); // Close menu
              NavigationHelper.push(context, GoodsItemHistoryPage(
                    item: widget.item,
                    warehouseId: widget.warehouseId!,),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: Text(
              'goods_delete'.tr,
              style: const TextStyle(color: Colors.red),
            ),
            onTap: () async {
              Navigator.pop(context); // Close menu
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('goods_confirmDelete'.tr),
                  content: Text('goods_confirmDeleteItem'.tr),
                  actions: [
                    TextButton(
                      child: Text('goods_cancel'.tr),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    TextButton(
                      child: Text(
                        'goods_delete'.tr,
                        style: const TextStyle(color: Colors.red),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await GoodsPlugin.instance.deleteGoodsItem(widget.warehouseId!, widget.item.id);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = GoodsLocalizations.of(context);
    
    // Calculate daily cost
    double? dailyCost;
    if (widget.item.totalPrice != null && widget.item.purchaseDate != null) {
      final days = DateTime.now().difference(widget.item.purchaseDate!).inDays;
      final effectiveDays = days < 1 ? 1 : days;
      dailyCost = widget.item.totalPrice! / effectiveDays;
    }

    // Usage stats
    final daysOwned = widget.item.purchaseDate != null 
        ? DateTime.now().difference(widget.item.purchaseDate!).inDays 
        : 0;
    final usageCount = widget.item.usageRecords.length;

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
          onTap: widget.onTap,
          onLongPress: _showMenu,
          borderRadius: BorderRadius.circular(16),
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
                // Image Section
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1.5, 
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: widget.item.imageUrl != null 
                            ? _buildImage() 
                            : _buildIcon(),
                      ),
                    ),
                    // Badge (using subItems count as a placeholder for quantity if any)
                    if (widget.item.subItems.isNotEmpty)
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
                            '${widget.item.subItems.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
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
                  widget.item.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 4), 
                
                // Daily Cost
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '¥',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          l10n.dailyCost,
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                    Text(
                      dailyCost != null 
                          ? '¥${dailyCost.toStringAsFixed(3)}/${l10n.day}'
                          : '-',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                    ),
                  ],
                ), 
                
                const SizedBox(height: 4), 
                
                // Category & Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            widget.item.icon ?? Icons.category_outlined,
                            size: 14,
                            color: Colors.purple, 
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              widget.item.tags.isNotEmpty ? widget.item.tags.first : l10n.noItems.replaceAll('没有物品', '未分类').replaceAll('No Items', 'Uncategorized'), // Fallback
                              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '¥${(widget.item.totalPrice ?? 0).toStringAsFixed(0)}',
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
                
                // Usage Stats & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$daysOwned${l10n.days} / $usageCount${l10n.times}',
                       style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.inPlace,
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
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

  Widget _buildIcon() {
    return Container(
      color: widget.item.iconColor ?? Colors.grey[200],
      width: double.infinity,
      height: double.infinity,
      child: Icon(
        widget.item.icon ?? Icons.inventory_2,
        size: 32,
        color: Colors.white,
      ),
    );
  }

  Widget _buildImage() {
    if (_resolvedImageUrl == null) {
      return _buildIcon();
    }
    
    final imageUrl = _resolvedImageUrl!;
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      // 网络图片
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('网络图片加载失败: $error');
          return _buildIcon();
        },
      );
    } else {
      // 本地图片
      try {
        final file = File(imageUrl);
        return Image.file(
          file,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('本地图片加载失败: $error\n路径: $imageUrl');
            return _buildIcon();
          },
        );
      } catch (e) {
        debugPrint('创建File对象失败: $e\n路径: $imageUrl');
        return _buildIcon();
      }
    }
  }
}