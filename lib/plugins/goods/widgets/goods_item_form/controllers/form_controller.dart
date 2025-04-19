import 'package:flutter/material.dart';
import '../../../models/goods_item.dart';
import '../../../models/usage_record.dart';
import '../../../models/custom_field.dart';

class GoodsItemFormController {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();

  IconData? icon;
  Color? iconColor;
  String? imagePath;
  List<String> tags = [];
  List<UsageRecord> usageRecords = [];
  List<CustomField> customFields = [];

  GoodsItemFormController({GoodsItem? initialData}) {
    stockController.text = '1'; // 设置库存默认值为1
    if (initialData != null) {
      nameController.text = initialData.title;
      descriptionController.text = initialData.notes ?? '';
      priceController.text = (initialData.purchasePrice ?? 0).toString();
      stockController.text = '0'; // 由于原模型没有stock字段，默认为0
      icon = initialData.icon;
      iconColor = initialData.iconColor;
      // 处理初始图片路径，如果不是以 file:// 开头，则添加
      if (initialData.imageUrl != null &&
          !initialData.imageUrl!.startsWith('file://')) {
        imagePath = 'file://${initialData.imageUrl}';
      } else {
        imagePath = initialData.imageUrl;
      }
      tags = List<String>.from(initialData.tags);
      usageRecords = List<UsageRecord>.from(initialData.usageRecords);
      customFields = List<CustomField>.from(initialData.customFields);
    }
  }

  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    stockController.dispose();
  }

  bool validate() {
    return formKey.currentState?.validate() ?? false;
  }

  GoodsItem buildGoodsItem(String? existingId) {
    // 处理图片路径，移除 file:// 前缀
    String? processedImagePath = imagePath;
    if (processedImagePath != null &&
        processedImagePath.startsWith('file://')) {
      processedImagePath = processedImagePath.replaceFirst('file://', '');
    }

    return GoodsItem(
      id: existingId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: nameController.text,
      notes: descriptionController.text,
      purchasePrice: double.parse(priceController.text),
      icon: icon ?? Icons.image,
      iconColor: iconColor ?? Colors.blue,
      imageUrl: processedImagePath,
      tags: tags,
      purchaseDate: DateTime.now(),
      usageRecords: usageRecords,
      customFields: customFields,
    );
  }
}
