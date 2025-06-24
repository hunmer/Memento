import 'package:flutter/material.dart';
import '../../../models/goods_item.dart';
import '../../../models/usage_record.dart';
import '../../../models/custom_field.dart';
import '../../../goods_plugin.dart';
import '../../../../../core/event/event_manager.dart';
import '../../../../../core/event/item_event_args.dart';

class GoodsItemFormController {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();

  // 发送事件通知
  void _notifyEvent(String action, GoodsItem item) {
    final eventArgs = ItemEventArgs(
      eventName: 'goods_$action',
      itemId: item.id,
      title: item.title,
      action: action,
    );
    EventManager.instance.broadcast('goods_$action', eventArgs);
  }

  IconData? icon;
  Color? iconColor;
  String? imagePath;
  List<String> tags = [];
  List<UsageRecord> usageRecords = [];
  List<CustomField> customFields = [];
  List<GoodsItem> _subItems = [];

  // 获取子物品列表
  List<GoodsItem> get subItems => _subItems;

  // 初始数据引用，用于排除选择自身
  final GoodsItem? initialData;

  GoodsItemFormController({this.initialData}) {
    stockController.text = '1'; // 设置库存默认值为1
    if (initialData != null) {
      // 使用非空断言操作符 ! 告诉编译器 initialData 此时不为空
      final item = initialData!;
      nameController.text = item.title;
      descriptionController.text = item.notes ?? '';
      priceController.text = (item.purchasePrice ?? 0).toString();
      stockController.text = '0'; // 由于原模型没有stock字段，默认为0
      icon = item.icon;
      iconColor = item.iconColor;
      imagePath = item.imageUrl;
      tags = List<String>.from(item.tags);
      usageRecords = List<UsageRecord>.from(item.usageRecords);
      customFields = List<CustomField>.from(item.customFields);
      _subItems = List<GoodsItem>.from(item.subItems);
    }
  }

  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    stockController.dispose();
  }

  // 添加子物品并从原仓库中删除
  Future<void> addSubItem(GoodsItem item) async {
    // 检查是否已存在相同ID的子物品
    if (_subItems.any((element) => element.id == item.id)) {
      // 如果已存在，先删除旧的
      _subItems.removeWhere((element) => element.id == item.id);
    }

    // 添加新的子物品（保留必要字段）
    final cleanedItem = GoodsItem(
      id: item.id,
      title: item.title,
      notes: item.notes,
      purchasePrice: item.purchasePrice,
      icon: item.icon,
      iconColor: item.iconColor,
      imageUrl: item.imageUrl,
      tags: item.tags,
      purchaseDate: item.purchaseDate,
      usageRecords: [], // 清空使用记录
      customFields: [], // 清空自定义字段
      subItems: [], // 清空子物品的子物品
    );

    _subItems.add(cleanedItem);
    // 发送添加事件
    _notifyEvent('added', cleanedItem);

    // 从原仓库中删除该物品
    try {
      // 遍历所有仓库查找并删除该物品
      for (final warehouse in GoodsPlugin.instance.warehouses) {
        final itemExists = warehouse.items.any((i) => i.id == item.id);
        if (itemExists) {
          await GoodsPlugin.instance.deleteGoodsItem(warehouse.id, item.id);
          break; // 找到并删除后就退出循环
        }
      }
    } catch (e) {
      debugPrint('Error removing item from warehouse: $e');
    }
  }

  // 移除子物品
  void removeSubItem(GoodsItem item) {
    _subItems.removeWhere((element) => element.id == item.id);
    // 发送删除事件
    _notifyEvent('deleted', item);
  }

  // 更新子物品
  void updateSubItem(GoodsItem updatedItem) {
    final index = _subItems.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      _subItems[index] = updatedItem;
    }
  }

  bool validate() {
    return formKey.currentState?.validate() ?? false;
  }

  GoodsItem buildGoodsItem(String? existingId) {
    return GoodsItem(
      id: existingId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: nameController.text,
      notes: descriptionController.text,
      purchasePrice: double.parse(priceController.text),
      icon: icon ?? Icons.image,
      iconColor: iconColor ?? Colors.blue,
      imageUrl: imagePath,
      tags: tags,
      purchaseDate: DateTime.now(),
      usageRecords: usageRecords,
      customFields: customFields,
      subItems: _subItems,
    );
  }
}
