import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/route/route_history_manager.dart';
import 'package:Memento/plugins/goods/models/goods_item.dart';
import 'package:Memento/plugins/goods/goods_plugin.dart';
import 'goods_item_form.dart';
import 'package:Memento/core/services/toast_service.dart';

class GoodsItemFormPage extends StatefulWidget {
  final String itemId;
  final Function(GoodsItem)? onSaved;

  const GoodsItemFormPage({super.key, required this.itemId, this.onSaved});

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
        // 加载完成后设置路由上下文
        _updateRouteContext();
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

  /// 更新路由上下文,使"询问当前上下文"功能能获取到当前物品信息
  void _updateRouteContext() {
    if (_item != null) {
      final result = GoodsPlugin.instance.findGoodsItemById(_item!.id);
      RouteHistoryManager.updateCurrentContext(
        pageId: "/goods/item_form",
        title: '物品 - 编辑: ${_item!.title}',
        params: {
          'itemId': _item!.id,
          'itemName': _item!.title,
          'warehouseId': result?.warehouseId ?? '',
        },
      );
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
          final parentResult = GoodsPlugin.instance.findParentGoodsItem(
            item.id,
          );
          if (parentResult != null) {
            // 保存父物品以更新价格等信息
            await GoodsPlugin.instance.saveGoodsItem(
              parentResult.warehouseId,
              parentResult.item,
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
      toastService.showToast('goods_saveFailed'.tr);
    }
  }

  void _handleDelete(GoodsItem item) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          'goods_confirmDelete'.tr,
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: Text(
          'goods_confirmDeleteItem'.tr,
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('goods_cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'goods_delete'.tr,
              style: TextStyle(color: theme.colorScheme.error),
            ),
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
        toastService.showToast(
          'goods_saveFailed'.tr,
          type: ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_item == null) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
          elevation: 0,
          title: Text('goods_itemNotFound'.tr),
        ),
        body: Center(child: Text('goods_itemNotExist'.tr)),
      );
    }

    return GoodsItemForm(
      initialData: _item,
      onSubmit: _handleSubmit,
      onDelete: _handleDelete,
    );
  }
}
