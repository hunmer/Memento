import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:Memento/core/route/route_history_manager.dart';
import 'package:Memento/plugins/goods/models/warehouse.dart';
import 'package:Memento/plugins/goods/models/goods_item.dart';
import 'package:Memento/plugins/goods/goods_plugin.dart';
import 'package:Memento/plugins/goods/widgets/goods_item_form/goods_item_form.dart';
import 'package:intl/intl.dart';

/// 物品详情页面
class GoodsItemDetailScreen extends StatefulWidget {
  final String itemId;
  final String warehouseId;

  const GoodsItemDetailScreen({
    super.key,
    required this.itemId,
    required this.warehouseId,
  });

  @override
  State<GoodsItemDetailScreen> createState() => _GoodsItemDetailScreenState();
}

class _GoodsItemDetailScreenState extends State<GoodsItemDetailScreen> {
  late GoodsItem _item;
  late Warehouse _warehouse;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _updateRouteContext();
  }

  void _updateRouteContext() {
    RouteHistoryManager.updateCurrentContext(
      pageId: "/goods/item_detail",
      title: '物品详情: ${_item.title}',
      params: {
        'itemId': _item.id,
        'itemTitle': _item.title,
        'warehouseId': _warehouse.id,
        'warehouseName': _warehouse.title,
      },
    );
  }

  Future<void> _loadData() async {
    try {
      final plugin = GoodsPlugin.instance;
      final warehouse = plugin.getWarehouse(widget.warehouseId);

      if (warehouse == null) {
        _showError('仓库不存在');
        return;
      }

      final result = plugin.findGoodsItemById(widget.itemId);
      if (result == null) {
        _showError('物品不存在');
        return;
      }

      if (mounted) {
        setState(() {
          _warehouse = warehouse;
          _item = result.item;
          _isLoading = false;
        });
        _updateRouteContext();
      }
    } catch (e) {
      debugPrint('加载物品详情失败: $e');
      _showError('加载失败: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _showEditDialog() {
    GoodsItemForm.show(
      context: context,
      initialData: _item,
      onSubmit: (item) async {
        await GoodsPlugin.instance.saveGoodsItem(_warehouse.id, item);
        await _loadData();
      },
      onDelete: (item) async {
        await GoodsPlugin.instance.deleteGoodsItem(
          _warehouse.id,
          item.id,
        );
        if (context.mounted) {
          Navigator.pop(context);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('加载中...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(_item.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图片展示
            if (_item.imageUrl != null && _item.imageUrl!.isNotEmpty)
              FutureBuilder<String?>(
                future: _item.getImageUrl(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: FileImage(
                            File(snapshot.data!),
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

            const SizedBox(height: 16),

            // 基本信息卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 价格
                    if (_item.purchasePrice != null)
                      _buildInfoRow(
                        Icons.price_change,
                        '价格',
                        '¥${_item.purchasePrice!.toStringAsFixed(2)}',
                      ),
                    // 购买日期
                    if (_item.purchaseDate != null)
                      _buildInfoRow(
                        Icons.calendar_today,
                        '购买日期',
                        dateFormat.format(_item.purchaseDate!),
                      ),
                    // 数量
                    if (_item.quantity != null)
                      _buildInfoRow(
                        Icons.numbers,
                        '数量',
                        '${_item.quantity}',
                      ),
                    // 状态
                    if (_item.status != null)
                      _buildInfoRow(
                        Icons.flag,
                        '状态',
                        _item.status!,
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 使用记录卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.history),
                        const SizedBox(width: 8),
                        Text(
                          '使用记录',
                          style: theme.textTheme.titleMedium,
                        ),
                        const Spacer(),
                        Text(
                          '${_item.usageRecords.length} 条',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_item.usageRecords.isEmpty)
                      Text(
                        '暂无使用记录',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    else
                      ..._item.usageRecords.map(
                        (record) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.circle, size: 8),
                          title: Text(record.note ?? '无备注'),
                          subtitle: Text(dateFormat.format(record.date)),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 标签
            if (_item.tags.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tag),
                          const SizedBox(width: 8),
                          Text(
                            '标签',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _item.tags.map((tag) {
                          return Chip(
                            label: Text(tag),
                            backgroundColor: theme.colorScheme.secondaryContainer,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // 备注
            if (_item.notes != null && _item.notes!.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.notes),
                          const SizedBox(width: 8),
                          Text(
                            '备注',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _item.notes!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // 自定义字段
            if (_item.customFields.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.build),
                          const SizedBox(width: 8),
                          Text(
                            '自定义字段',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._item.customFields.map(
                        (field) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Text(
                                '${field.key}: ',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  field.value,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 80), // 给 FAB 留空间
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showEditDialog,
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
