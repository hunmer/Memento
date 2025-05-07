import 'package:flutter/material.dart';
import '../../models/goods_item.dart';
import '../../goods_plugin.dart';
import 'goods_item_form.dart';

class GoodsItemFormPage extends StatefulWidget {
  final String itemId;
  final Function(GoodsItem)? onSaved;

  const GoodsItemFormPage({
    super.key,
    required this.itemId,
    this.onSaved,
  });

  @override
  State<GoodsItemFormPage> createState() => _GoodsItemFormPageState();
}

class _GoodsItemFormPageState extends State<GoodsItemFormPage> {
  GoodsItem? _item;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  Future<void> _loadItem() async {
    setState(() => _isLoading = true);
    try {
      // 使用GoodsPlugin的公共方法查找物品及其子物品
      final result = GoodsPlugin.instance.findGoodsItemById(widget.itemId);
      
      if (result != null) {
        setState(() {
          _item = result.item;
          _isLoading = false;
        });
      } else {
        // 如果在所有仓库中都找不到，设置为null
        setState(() {
          _item = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading item: $e');
      setState(() {
        _item = null;
        _isLoading = false;
      });
    }
  }

  void _handleSubmit(GoodsItem item) async {
    try {
      // 更新物品
      if (_item != null) {
        // 使用GoodsPlugin的公共方法查找物品所在的仓库
        final result = GoodsPlugin.instance.findGoodsItemById(item.id);
        
        if (result != null) {
          // 保存当前物品
          await GoodsPlugin.instance.saveGoodsItem(result.warehouseId, item);
          
          // 如果是子物品，查找并刷新父物品
          final parentResult = GoodsPlugin.instance.findParentGoodsItem(item.id);
          if (parentResult != null) {
            // 保存父物品以更新价格等信息
            await GoodsPlugin.instance.saveGoodsItem(
              parentResult.warehouseId, 
              parentResult.item
            );
          }
          
          if (widget.onSaved != null) {
            widget.onSaved!(item);
          }
          Navigator.of(context).pop(true);
          return;
        }
      }
    } catch (e) {
      debugPrint('Error updating item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存失败')),
      );
    }
  }

  void _handleDelete(GoodsItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个物品吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // 从所有仓库中查找并删除物品
        for (final warehouse in GoodsPlugin.instance.warehouses) {
          final exists = warehouse.items.any((i) => i.id == item.id);
          if (exists) {
            await GoodsPlugin.instance.deleteGoodsItem(warehouse.id, item.id);
            if (mounted) {
              Navigator.of(context).pop(true);
            }
            return;
          }
        }
      } catch (e) {
        debugPrint('Error deleting item: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('删除失败')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_item == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('物品不存在'),
        ),
        body: const Center(
          child: Text('未找到指定物品'),
        ),
      );
    }

    return GoodsItemForm(
      initialData: _item,
      onSubmit: _handleSubmit,
      onDelete: _handleDelete,
    );
  }
}