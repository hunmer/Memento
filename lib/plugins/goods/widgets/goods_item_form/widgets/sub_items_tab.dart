import 'dart:io';
import 'package:Memento/plugins/goods/widgets/goods_item_form/index.dart';
import 'package:flutter/material.dart';
import '../../../models/goods_item.dart';
import '../../goods_item_selector_dialog.dart';

class SubItemsTab extends StatefulWidget {
  final GoodsItemFormController controller;
  final VoidCallback onStateChanged;

  const SubItemsTab({
    super.key,
    required this.controller,
    required this.onStateChanged,
  });

  @override
  State<SubItemsTab> createState() => _SubItemsTabState();
}

class _SubItemsTabState extends State<SubItemsTab> {
  void _showItemSelector() async {
    final selectedItem = await showDialog<GoodsItem>(
      context: context,
      builder: (context) => GoodsItemSelectorDialog(
        excludeItemId: widget.controller.initialData?.id,
        excludeItemIds: widget.controller.subItems.map((e) => e.id).toList(),
      ),
    );

    if (selectedItem != null) {
      // 添加子物品并从原仓库中删除
      await widget.controller.addSubItem(selectedItem);
      setState(() {
        widget.onStateChanged();
      });
    }
  }

  void _removeSubItem(GoodsItem item) {
    setState(() {
      widget.controller.removeSubItem(item);
      widget.onStateChanged();
    });
  }

  void _editSubItem(GoodsItem item) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => GoodsItemFormPage(
          itemId: item.id,
          onSaved: (savedItem) {
            // 更新子物品状态
            widget.controller.updateSubItem(savedItem);
            widget.onStateChanged();
          },
        ),
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }
  
  Future<Widget> _buildLeadingWidget(GoodsItem item) async {
    // 如果有图片，优先显示图片
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      final imagePath = await ImageUtils.getAbsolutePath(item.imageUrl!);
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.file(
          File(imagePath),
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // 如果图片加载失败，显示图标
            return Icon(item.icon, color: item.iconColor);
          },
        ),
      );
    }
    // 没有图片则显示图标
    return Icon(item.icon, color: item.iconColor);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '子物品列表',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: 8),
              Text(
                widget.controller.subItems.isEmpty
                    ? '(无)'
                    : '(${widget.controller.subItems.length})',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _showItemSelector,
                icon: const Icon(Icons.add),
                label: const Text('添加子物品'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.controller.subItems.isNotEmpty) ...[
            Expanded(
              child: ListView.builder(
                itemCount: widget.controller.subItems.length,
                itemBuilder: (context, index) {
                  final item = widget.controller.subItems[index];
                  return Card(
                    child: ListTile(
                      onTap: () => _editSubItem(item),
                      leading: FutureBuilder<Widget>(
                        future: _buildLeadingWidget(item),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                            return snapshot.data!;
                          }
                          // 显示加载中的占位符
                          return const SizedBox(
                            width: 40,
                            height: 40,
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        },
                      ),
                      title: Text(item.title),
                      subtitle: item.totalPrice != null
                          ? Text('￥${item.totalPrice?.toStringAsFixed(2)}')
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        color: Theme.of(context).colorScheme.error,
                        onPressed: () => _removeSubItem(item),
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Text('暂无子物品'),
              ),
            ),
        ],
      ),
    );
  }
}