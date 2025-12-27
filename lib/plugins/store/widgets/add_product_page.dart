import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:uuid/uuid.dart';
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
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _pointsRatioController = TextEditingController();
  final TextEditingController _targetPriceController = TextEditingController();

  // 获取积分比率配置
  double _getPointsRatio() {
    final ratio = widget.controller.plugin.settings['points_to_rmb_ratio'];
    if (ratio == null) {
      return 100.0; // 默认 100 积分 = 1 元
    }
    return ratio is double ? ratio : (ratio as int).toDouble();
  }

  // 保存积分比率配置
  Future<void> _savePointsRatio(double ratio) async {
    await widget.controller.plugin.updateSettings({
      'points_to_rmb_ratio': ratio,
    });
  }

  @override
  void initState() {
    super.initState();
    // 初始化控制器值
    _priceController.text = widget.product?.price.toString() ?? '0';
    _stockController.text = widget.product?.stock.toString() ?? '0';
    _pointsRatioController.text = _getPointsRatio().toString();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _stockController.dispose();
    _pointsRatioController.dispose();
    _targetPriceController.dispose();
    super.dispose();
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
      await widget.controller.saveToStorage();
      widget.controller.notifyListeners();
      Navigator.pop(context);
    }
  }

  Future<void> _submit(Map<String, dynamic> values) async {
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

  /// 显示积分计算器弹窗
  void _showPointsCalculator() {
    final double ratio = _getPointsRatio();
    _pointsRatioController.text = ratio.toString();
    _targetPriceController.clear();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('积分计算器'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 积分与人民币比率
                TextFormField(
                  controller: _pointsRatioController,
                  decoration: const InputDecoration(
                    labelText: '积分 : 人民币 比率',
                    hintText: '例如: 100 表示 100积分=1元',
                    prefixIcon: Icon(Icons.calculate),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                // 目标商品价格
                TextFormField(
                  controller: _targetPriceController,
                  decoration: const InputDecoration(
                    labelText: '目标商品价格 (元)',
                    hintText: '输入商品价格',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('app_cancel'.tr),
              ),
              FilledButton(
                onPressed: () {
                  final ratio = double.tryParse(_pointsRatioController.text) ?? 100.0;
                  final targetPrice = double.tryParse(_targetPriceController.text) ?? 0.0;

                  if (targetPrice <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('请输入有效的价格')),
                    );
                    return;
                  }

                  // 计算积分 = 价格 * 比率
                  final points = (targetPrice * ratio).round();
                  _priceController.text = points.toString();

                  // 保存比率配置
                  _savePointsRatio(ratio);

                  // 更新表单中的 price 字段
                  _formKey.currentState?.patchValue({'price': points.toString()});

                  Navigator.pop(context);
                },
                child: const Text('计算并填入'),
              ),
            ],
          ),
    );
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
            onPressed: () {
              _formKey.currentState?.save();
              final values = _formKey.currentState?.value ?? {};
              _submit(values);
            },
            tooltip: 'store_saveButton'.tr,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
              child: FormBuilder(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 图片选择（占满宽度）
                    _buildImagePicker(context),
                    const SizedBox(height: 16),
                    // 商品名称
                    FormBuilderTextField(
                      name: 'name',
                      initialValue: widget.product?.name ?? '',
                      decoration: InputDecoration(
                        labelText: 'store_productNameLabel'.tr,
                      ),
                      validator:
                          (value) =>
                              value == null || value.isEmpty ? 'store_productNameRequired'.tr : null,
                    ),
                    const SizedBox(height: 16),
                    // 价格和库存（平分宽度）
                    Row(
                      children: [
                        // 积分输入框
                        Expanded(
                          child: FormBuilderTextField(
                            name: 'price',
                            initialValue: _priceController.text,
                            decoration: InputDecoration(
                              labelText: 'store_priceLabel'.tr,
                              prefixIcon: const Icon(Icons.stars),
                            ),
                            keyboardType: TextInputType.number,
                            valueTransformer: (value) => int.tryParse(value ?? '0'),
                          ),
                        ),
                        // 计算器图标按钮
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: IconButton(
                            icon: const Icon(Icons.calculate, color: Colors.blue),
                            onPressed: _showPointsCalculator,
                            tooltip: '积分计算器',
                          ),
                        ),
                        // 库存输入框
                        Expanded(
                          child: FormBuilderTextField(
                            name: 'stock',
                            initialValue: _stockController.text,
                            decoration: InputDecoration(
                              labelText: 'store_stockLabel'.tr,
                              prefixIcon: const Icon(Icons.inventory_2),
                            ),
                            keyboardType: TextInputType.number,
                            valueTransformer: (value) => int.tryParse(value ?? '0'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 描述
                    FormBuilderTextField(
                      name: 'description',
                      initialValue: widget.product?.description ?? '',
                      decoration: InputDecoration(
                        labelText: 'store_descriptionLabel'.tr,
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5,
                      minLines: 3,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建图片选择器（使用 ImagePickerField）
  Widget _buildImagePicker(BuildContext context) {
    return ImagePickerField(
      labelText: null,
      currentImage: widget.product?.image,
      previewWidth: double.infinity,
      previewHeight: 200.0,
      borderRadius: 12.0,
      showShadow: true,
      onImageChanged: (result) {
        // 图片选择后的处理
        _formKey.currentState?.patchValue({'image': result});
      },
    );
  }
}
