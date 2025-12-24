import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/widgets/form_fields/form_builder_wrapper.dart';
import 'package:Memento/widgets/form_fields/index.dart';
import 'package:Memento/plugins/store/models/product.dart';
import 'package:Memento/plugins/store/controllers/store_controller.dart';

class AddProductPage extends StatefulWidget {
  final StoreController controller;
  final Product? product;

  const AddProductPage({super.key, required this.controller, this.product});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _confirmArchive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('store_confirmArchiveTitle'.tr),
            content: Text('store_confirmArchiveMessage'.tr),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('app_cancel'.tr),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('store_archiveButton'.tr),
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
            title: Text('store_confirmDeleteTitle'.tr),
            content: Text('store_confirmDeleteMessage'.tr),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('app_cancel'.tr),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'store_deleteButton'.tr,
                  style: TextStyle(color: Colors.red),
                ),
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

  Future<void> _submit(Map<String, dynamic> values) async {
    // 处理图片值（可能是 Map 或 String）
    final imageValue = values['image'];
    final imageUrl = imageValue is Map ? (imageValue['url'] as String?) ?? '' : (imageValue as String? ?? '');

    final product =
        widget.product != null
            ? Product(
              id: widget.product!.id,
              name: values['name'] as String,
              description: values['description'] as String? ?? '',
              image: imageUrl.isEmpty ? widget.product!.image : imageUrl,
              stock: int.parse(values['stock'] as String),
              price: int.parse(values['price'] as String),
              exchangeStart: widget.product!.exchangeStart,
              exchangeEnd: widget.product!.exchangeEnd,
              useDuration: widget.product!.useDuration,
            )
            : Product(
              id: const Uuid().v4(),
              name: values['name'] as String,
              description: values['description'] as String? ?? '',
              image: imageUrl,
              stock: int.parse(values['stock'] as String),
              price: int.parse(values['price'] as String),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('store_addProductTitle'.tr),
        actions: [
          if (widget.product != null) ...[
            IconButton(
              icon: const Icon(Icons.archive),
              onPressed: _confirmArchive,
              tooltip: 'store_archiveButton'.tr,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
              tooltip: 'store_deleteButton'.tr,
            ),
          ],
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => _formKey.currentState?.save(),
            tooltip: 'store_saveButton'.tr,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 32,
              ),
              child: FormBuilderWrapper(
                formKey: _formKey,
                config: FormConfig(
                  showSubmitButton: false,
                  fieldSpacing: 16,
                  fields: [
                    // 图片选择
                    FormFieldConfig(
                      name: 'image',
                      type: FormFieldType.imagePicker,
                      initialValue: widget.product?.image,
                      extra: {
                        'enableCrop': true,
                        'cropAspectRatio': 1.0,
                        'saveDirectory': 'store/products',
                      },
                    ),
                    // 商品名称
                    FormFieldConfig(
                      name: 'name',
                      type: FormFieldType.text,
                      labelText: 'store_productNameLabel'.tr,
                      initialValue: widget.product?.name ?? '',
                      required: true,
                      validationMessage: 'store_productNameRequired'.tr,
                    ),
                    // 价格
                    FormFieldConfig(
                      name: 'price',
                      type: FormFieldType.number,
                      labelText: 'store_priceLabel'.tr,
                      initialValue: widget.product?.price.toString() ?? '0',
                      required: true,
                      validationMessage: 'store_priceRequired'.tr,
                    ),
                    // 库存
                    FormFieldConfig(
                      name: 'stock',
                      type: FormFieldType.number,
                      labelText: 'store_stockLabel'.tr,
                      initialValue: widget.product?.stock.toString() ?? '0',
                      required: true,
                      validationMessage: 'store_stockRequired'.tr,
                    ),
                    // 描述
                    FormFieldConfig(
                      name: 'description',
                      type: FormFieldType.textArea,
                      labelText: 'store_descriptionLabel'.tr,
                      initialValue: widget.product?.description ?? '',
                      extra: {
                        'minLines': 3,
                        'maxLines': 5,
                      },
                    ),
                  ],
                  onSubmit: _submit,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
