
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:Memento/widgets/image_picker_dialog.dart';
import '../models/product.dart';
import '../controllers/store_controller.dart';

class AddProductPage extends StatefulWidget {
  final StoreController controller;
  final Function(List<Product>, int)? onDataChanged;

  const AddProductPage({
    super.key, 
    required this.controller,
    this.onDataChanged,
  });

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

  Future<void> _pickImage() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ImagePickerDialog(
        enableCrop: true,
        cropAspectRatio: 1.0,
      ),
    );

    if (result != null) {
      setState(() {
        _imageUrl = result['url'];
        _imageBytes = result['bytes'];
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final product = Product(
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

      widget.controller.addProduct(product);
      widget.onDataChanged?.call(
        widget.controller.products,
        widget.controller.currentPoints,
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加商品'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _submit,
          ),
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
                  child: _imageBytes != null
                      ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                      : const Icon(Icons.add_a_photo, size: 50),
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

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descController.dispose();
    super.dispose();
  }
}
