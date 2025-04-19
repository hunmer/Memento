import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../../../../widgets/circle_icon_picker.dart';
import '../image_picker_widget.dart';
import '../tag_input_field.dart';
import '../custom_fields_list.dart';
import '../controllers/form_controller.dart';
import '../utils/image_utils.dart';

class BasicInfoTab extends StatelessWidget {
  final GoodsItemFormController controller;
  final Function() onStateChanged;
  final Function()? onDelete;
  final bool showDeleteButton;

  const BasicInfoTab({
    super.key,
    required this.controller,
    required this.onStateChanged,
    this.onDelete,
    this.showDeleteButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBasicInfoCard(context),
        const SizedBox(height: 16),
        _buildPriceStockCard(),
        const SizedBox(height: 16),
        _buildTagsCard(),
        const SizedBox(height: 16),
        _buildCustomFieldsCard(),
        if (showDeleteButton && onDelete != null) ...[
          const SizedBox(height: 16),
          _buildDeleteButton(context),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBasicInfoCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildImageSection(context),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.nameController,
              decoration: const InputDecoration(
                labelText: '商品名称',
                hintText: '输入商品名称',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入商品名称';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.descriptionController,
              decoration: const InputDecoration(
                labelText: '商品描述',
                hintText: '输入商品描述',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleIconPicker(
            currentIcon: controller.icon ?? Icons.image,
            backgroundColor: controller.iconColor ?? Colors.blue,
            onIconSelected: (icon) {
              controller.icon = icon;
              onStateChanged();
            },
            onColorSelected: (color) {
              controller.iconColor = color;
              onStateChanged();
            },
          ),
          const SizedBox(width: 24),
          Card(
            elevation: 2,
            child: ImagePickerWidget(
              imagePath: controller.imagePath,
              onImageSelected: (path) async {
                if (path.isNotEmpty) {
                  final imageFile = File(path);
                  final imageBytes = await imageFile.readAsBytes();
                  await _showCropDialog(context, imageBytes);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceStockCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller.priceController,
                decoration: const InputDecoration(
                  labelText: '价格',
                  hintText: '输入价格',
                  prefixText: '¥',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入价格';
                  }
                  if (double.tryParse(value) == null) {
                    return '请输入有效的价格';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: controller.stockController,
                decoration: const InputDecoration(
                  labelText: '库存',
                  hintText: '输入库存',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入库存';
                  }
                  if (int.tryParse(value) == null) {
                    return '请输入有效的库存数量';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TagInputField(
          tags: controller.tags,
          onTagsChanged: (tags) {
            controller.tags = tags;
            onStateChanged();
          },
        ),
      ),
    );
  }

  Widget _buildCustomFieldsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: CustomFieldsList(
          fields: controller.customFields,
          onFieldsChanged: (fields) {
            controller.customFields = fields;
            onStateChanged();
          },
        ),
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                title: const Text('确认删除'),
                content: const Text('确定要删除这个物品吗？此操作不可恢复。'),
                actions: [
                  TextButton(
                    child: const Text('取消'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  TextButton(
                    child: const Text(
                      '删除',
                      style: TextStyle(color: Colors.red),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      onDelete?.call();
                    },
                  ),
                ],
              ),
        );
      },
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red),
      ),
      child: const Text('删除商品'),
    );
  }

  Future<void> _showCropDialog(
    BuildContext context,
    Uint8List imageBytes,
  ) async {
    final cropController = CropController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        '裁剪图片',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 300,
                      height: 300,
                      child: Crop(
                        controller: cropController,
                        image: imageBytes,
                        aspectRatio: 1,
                        onCropped: (result) async {
                          switch (result) {
                            case CropSuccess(:final croppedImage):
                              // 删除旧图片
                              await ImageUtils.deleteImage(
                                controller.imagePath,
                              );
                              // 保存新图片
                              final newPath = await ImageUtils.saveImage(
                                croppedImage,
                              );
                              controller.imagePath = newPath;
                              onStateChanged();
                              Navigator.of(context).pop();
                            case CropFailure(:final cause):
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('裁剪失败: $cause')),
                              );
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('取消'),
                          ),
                          ElevatedButton(
                            onPressed: () => cropController.crop(),
                            child: const Text('确定'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
