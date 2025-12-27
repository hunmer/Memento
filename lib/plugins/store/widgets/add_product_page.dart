import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/widgets/form_fields/form_builder_wrapper.dart';
import 'package:Memento/widgets/form_fields/config.dart';
import 'package:Memento/widgets/form_fields/types.dart';
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
  final _formKey = GlobalKey<FormBuilderWrapperState>();
  final TextEditingController _pointsRatioController = TextEditingController();
  final TextEditingController _targetPriceController = TextEditingController();
  FormBuilderWrapperState? _formWrapperState;

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
    _pointsRatioController.text = _getPointsRatio().toString();
  }

  @override
  void dispose() {
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
    final priceValue = values['price'];
    final stockValue = values['stock'];

    final product =
        widget.product != null
            ? Product(
              id: widget.product!.id,
              name: values['name'] as String,
              description: values['description'] as String? ?? '',
              image: imageUrl.isEmpty ? widget.product!.image : imageUrl,
              stock: int.tryParse(stockValue?.toString() ?? '0') ?? 0,
              price: int.tryParse(priceValue?.toString() ?? '0') ?? 0,
              exchangeStart: widget.product!.exchangeStart,
              exchangeEnd: widget.product!.exchangeEnd,
              useDuration: widget.product!.useDuration,
            )
            : Product(
              id: const Uuid().v4(),
              name: values['name'] as String,
              description: values['description'] as String? ?? '',
              image: imageUrl,
              stock: int.tryParse(stockValue?.toString() ?? '0') ?? 0,
              price: int.tryParse(priceValue?.toString() ?? '0') ?? 0,
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

                  // 保存比率配置
                  _savePointsRatio(ratio);

                  // 更新表单中的 price 字段
                  _formWrapperState?.patchValue({'price': points.toString()});

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
            onPressed: () => _formWrapperState?.submitForm(),
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
              child: FormBuilderWrapper(
                key: _formKey,
                config: FormConfig(
                  fields: [
                    // 图片选择
                    FormFieldConfig(
                      name: 'image',
                      type: FormFieldType.imagePicker,
                      initialValue: widget.product?.image,
                      extra: {
                        'previewWidth': double.infinity,
                        'previewHeight': 200.0,
                        'borderRadius': 12.0,
                        'showShadow': true,
                        'showLabel': false,
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
                    // 价格（带计算器按钮）
                    FormFieldConfig(
                      name: 'price',
                      type: FormFieldType.number,
                      labelText: 'store_priceLabel'.tr,
                      initialValue: widget.product?.price.toString() ?? '0',
                      prefixIcon: Icons.stars,
                      suffixButtons: [
                        InputGroupButton(
                          icon: Icons.calculate,
                          tooltip: '积分计算器',
                          onPressed: _showPointsCalculator,
                        ),
                      ],
                    ),
                    // 库存
                    FormFieldConfig(
                      name: 'stock',
                      type: FormFieldType.number,
                      labelText: 'store_stockLabel'.tr,
                      initialValue: widget.product?.stock.toString() ?? '0',
                      prefixIcon: Icons.inventory_2,
                    ),
                    // 描述
                    FormFieldConfig(
                      name: 'description',
                      type: FormFieldType.textArea,
                      labelText: 'store_descriptionLabel'.tr,
                      initialValue: widget.product?.description ?? '',
                    ),
                  ],
                  onSubmit: _submit,
                  fieldSpacing: 16,
                  showSubmitButton: false,
                  showResetButton: false,
                ),
                onStateReady: (state) => _formWrapperState = state,
              ),
            ),
          );
        },
      ),
    );
  }
}
