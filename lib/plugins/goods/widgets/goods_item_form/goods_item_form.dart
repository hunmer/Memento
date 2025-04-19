import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../models/goods_item.dart';
import '../../models/usage_record.dart';
import '../../models/custom_field.dart';
import '../../../../widgets/circle_icon_picker.dart';
import 'image_picker_widget.dart';
import 'tag_input_field.dart';
import 'usage_records_list.dart';
import 'custom_fields_list.dart';

class GoodsItemForm extends StatefulWidget {
  final GoodsItem? initialData;
  final Function(GoodsItem) onSubmit;
  final Function(GoodsItem)? onDelete;

  const GoodsItemForm({
    super.key,
    this.initialData,
    required this.onSubmit,
    this.onDelete,
  });

  @override
  State<GoodsItemForm> createState() => _GoodsItemFormState();
}

class _GoodsItemFormState extends State<GoodsItemForm>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  IconData? _icon;
  Color? _iconColor;
  String? _imagePath;
  List<String> _tags = [];
  List<UsageRecord> _usageRecords = [];
  List<CustomField> _customFields = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _stockController.text = '1'; // 设置库存默认值为1
    if (widget.initialData != null) {
      final item = widget.initialData!;
      _nameController.text = item.title;
      _descriptionController.text = item.notes ?? '';
      _priceController.text = (item.purchasePrice ?? 0).toString();
      _stockController.text = '0'; // 由于原模型没有stock字段，默认为0
      _icon = item.icon;
      _iconColor = item.iconColor;
      _imagePath = item.imageUrl;
      _tags = List<String>.from(item.tags);
      _usageRecords = List<UsageRecord>.from(item.usageRecords);
      _customFields = List<CustomField>.from(item.customFields);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('编辑物品'),
          bottom: TabBar(tabs: [Tab(text: '基本信息'), Tab(text: '使用记录')]),
          actions: [
            if (widget.initialData != null && widget.onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  showDialog(
                    context: context,
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
                              child: const Text('删除'),
                              onPressed: () {
                                Navigator.pop(context); // 关闭确认对话框
                                widget.onDelete!(widget.initialData!);
                              },
                            ),
                          ],
                        ),
                  );
                },
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: TabBarView(
            children: [_buildBasicInfoTab(), _buildUsageRecordsTab()],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 基础信息部分
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 图标和图片选择
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 图标选择
                      CircleIconPicker(
                        currentIcon: _icon ?? Icons.image,
                        backgroundColor: _iconColor ?? Colors.blue,
                        onIconSelected: (icon) {
                          setState(() {
                            _icon = icon;
                          });
                        },
                        onColorSelected: (color) {
                          setState(() {
                            _iconColor = color;
                          });
                        },
                      ),
                      const SizedBox(width: 24),
                      // 图片选择
                      Card(
                        elevation: 2,
                        child: ImagePickerWidget(
                          imagePath: _imagePath,
                          onImageSelected: (path) async {
                            if (path.isNotEmpty) {
                              final imageFile = File(path);
                              final imageBytes = await imageFile.readAsBytes();
                              await _showCropDialog(imageBytes);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
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
                  controller: _descriptionController,
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
        ),
        const SizedBox(height: 16),
        // 价格与库存
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
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
                        controller: _stockController,
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
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 标签
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TagInputField(
              tags: _tags,
              onTagsChanged: (tags) {
                setState(() {
                  _tags = tags;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 自定义字段
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: CustomFieldsList(
              fields: _customFields,
              onFieldsChanged: (fields) {
                setState(() {
                  _customFields = fields;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        // 提交按钮
        ElevatedButton(
          onPressed: _submitForm,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('保存商品'),
          ),
        ),
      ],
    );
  }

  Widget _buildUsageRecordsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UsageRecordsList(
                  records: _usageRecords,
                  onRecordsChanged: (records) {
                    setState(() {
                      _usageRecords = records;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final goodsItem = GoodsItem(
        id:
            widget.initialData?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: _nameController.text,
        notes: _descriptionController.text,
        purchasePrice: double.parse(_priceController.text),
        icon: _icon ?? Icons.image,
        iconColor: _iconColor ?? Colors.blue,
        imageUrl: _imagePath,
        tags: _tags,
        purchaseDate: widget.initialData?.purchaseDate ?? DateTime.now(),
        usageRecords: _usageRecords,
        customFields: _customFields,
      );

      widget.onSubmit(goodsItem);
    }
  }

  Future<void> _showCropDialog(Uint8List imageBytes) async {
    final cropController = CropController();

    await showDialog(
      context: context,
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
                        onCropped: (result) {
                          switch (result) {
                            case CropSuccess(:final croppedImage):
                              // 保存裁剪后的图片
                              _saveAndSetCroppedImage(croppedImage);
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

  Future<Uint8List> _compressImage(
    Uint8List imageData, {
    int maxWidth = 800,
    int quality = 85,
  }) async {
    try {
      // 解码图片
      final codec = await ui.instantiateImageCodec(imageData);
      final frame = await codec.getNextFrame();
      final originalImage = frame.image;

      // 计算新的宽度和高度，保持宽高比
      double ratio = originalImage.width / originalImage.height;
      int targetWidth = originalImage.width;
      int targetHeight = originalImage.height;

      if (targetWidth > maxWidth) {
        targetWidth = maxWidth;
        targetHeight = (maxWidth / ratio).round();
      }

      // 创建缩放后的图片
      final ui.Image resizedImage = await originalImage
          .toByteData(format: ui.ImageByteFormat.rawRgba)
          .then((byteData) async {
            final completer = Completer<ui.Image>();
            ui.decodeImageFromPixels(
              byteData!.buffer.asUint8List(),
              originalImage.width,
              originalImage.height,
              ui.PixelFormat.rgba8888,
              completer.complete,
            );
            return completer.future;
          });

      // 将图片编码为JPEG格式，并应用质量压缩
      final byteData = await resizedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final compressedData = byteData!.buffer.asUint8List();

      // 释放资源
      originalImage.dispose();
      resizedImage.dispose();

      return compressedData;
    } catch (e) {
      debugPrint('压缩图片失败: $e');
      return imageData; // 如果压缩失败，返回原图
    }
  }

  Future<void> _saveAndSetCroppedImage(Uint8List croppedData) async {
    // 压缩图片
    final compressedData = await _compressImage(croppedData);

    try {
      // 获取应用文档目录
      final appDir = await getApplicationDocumentsDirectory();

      // 创建商品图片存储目录
      final goodsImageDir = Directory('${appDir.path}/goods_images');
      if (!await goodsImageDir.exists()) {
        await goodsImageDir.create(recursive: true);
      }

      // 生成唯一的文件名
      final fileName = 'goods_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final imagePath = path.join(goodsImageDir.path, fileName);

      // 保存裁剪后的图片到永久存储
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(compressedData);

      // 如果有旧图片且不是默认图片，则删除
      if (_imagePath != null &&
          _imagePath!.isNotEmpty &&
          _imagePath!.contains('goods_images')) {
        try {
          final oldFile = File(_imagePath!);
          if (await oldFile.exists()) {
            await oldFile.delete();
          }
        } catch (e) {
          // 忽略删除旧文件的错误
          debugPrint('删除旧图片失败: $e');
        }
      }

      setState(() {
        _imagePath = imageFile.path;
      });

      debugPrint('图片已保存到: $imagePath');
    } catch (e) {
      debugPrint('保存图片失败: $e');
      // 如果永久存储失败，回退到临时存储
      final tempDir = await Directory.systemTemp.createTemp('cropped_images');
      final tempFile = File(
        '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await tempFile.writeAsBytes(compressedData);

      setState(() {
        _imagePath = tempFile.path;
      });
    }
  }

  // 此处已在上面定义过dispose方法，无需重复
}
