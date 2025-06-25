import 'dart:io';
import 'dart:typed_data';
import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:Memento/widgets/image_picker_dialog.dart';
import '../models/product.dart';
import '../controllers/store_controller.dart';

class AddProductPage extends StatefulWidget {
  final StoreController controller;
  final Product? product;

  const AddProductPage({super.key, required this.controller, this.product});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descController = TextEditingController();
  String? _imageUrl;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _priceController.text = widget.product!.price.toString();
      _stockController.text = widget.product!.stock.toString();
      _descController.text = widget.product!.description;
      _imageUrl = widget.product!.image;
    }
  }

  Future<void> _pickImage() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) =>
              ImagePickerDialog(enableCrop: true, cropAspectRatio: 1.0),
    );

    if (result != null) {
      setState(() {
        _imageUrl = result['url'];
        _imageBytes = result['bytes'];
      });
    }
  }

  Future<void> _confirmArchive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('确认存档'),
            content: const Text('确定要将这个商品存档吗？存档后可以在筛选器中查看。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('存档'),
              ),
            ],
          ),
    );

    if (confirmed == true && widget.product != null) {
      await widget.controller.archiveProduct(widget.product!);
      Navigator.pop(context);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('确认删除'),
            content: const Text('确定要删除这个商品吗？此操作不可撤销。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('删除', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      widget.controller.products.removeWhere((p) => p.id == widget.product!.id);
      await widget.controller.saveProducts();
      await widget.controller.saveToStorage(); // 保存所有相关数据
      widget.controller.notifyListeners(); // 通知UI更新
      Navigator.pop(context);
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final product =
          widget.product != null
              ? Product(
                id: widget.product!.id,
                name: _nameController.text,
                description: _descController.text,
                image: _imageUrl ?? widget.product!.image,
                stock: int.parse(_stockController.text),
                price: int.parse(_priceController.text),
                exchangeStart: widget.product!.exchangeStart,
                exchangeEnd: widget.product!.exchangeEnd,
                useDuration: widget.product!.useDuration,
              )
              : Product(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: _nameController.text,
                description: _descController.text,
                image: _imageUrl ?? '',
                stock: int.parse(_stockController.text),
                price: int.parse(_priceController.text),
                exchangeStart: DateTime.now(),
                exchangeEnd: DateTime.now().add(const Duration(days: 30)),
                useDuration: 30,
              );

      if (widget.product != null) {
        widget.controller.products.removeWhere((p) => p.id == product.id);
      }
      widget.controller.addProduct(product);
      await widget.controller.saveProducts();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加商品'),
        actions: [
          if (widget.product != null) ...[
            IconButton(
              icon: const Icon(Icons.archive),
              onPressed: _confirmArchive,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
            ),
          ],
          IconButton(icon: const Icon(Icons.check), onPressed: _submit),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 图片选择
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _buildImagePreview(),
                ),
              ),
              const SizedBox(height: 20),
              // 商品名称
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '商品名称',
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
              // 价格
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: '价格(积分)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入价格';
                  }
                  if (int.tryParse(value) == null) {
                    return '请输入有效数字';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // 库存
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: '库存数量',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入库存数量';
                  }
                  if (int.tryParse(value) == null) {
                    return '请输入有效数字';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // 描述
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: '商品描述',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 判断是否为网络图片
  bool isNetworkImage(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  // 构建加载指示器
  Widget _buildLoadingIndicator() {
    return const Center(child: CircularProgressIndicator());
  }

  // 构建错误图片显示
  Widget _buildErrorImage() {
    return const Icon(Icons.broken_image, size: 48);
  }

  // 构建图片预览
  Widget _buildImagePreview() {
    if (_imageBytes != null) {
      return Image.memory(_imageBytes!, fit: BoxFit.cover);
    } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      return FutureBuilder<String>(
        future: ImageUtils.getAbsolutePath(_imageUrl!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              final imagePath = snapshot.data!;
              return isNetworkImage(imagePath)
                  ? Image.network(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) => _buildErrorImage(),
                  )
                  : Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) => _buildErrorImage(),
                  );
            }
          }
          return _buildLoadingIndicator();
        },
      );
    }
    return const Icon(Icons.add_a_photo, size: 50);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descController.dispose();
    super.dispose();
  }
}
