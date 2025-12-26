import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/widgets/smooth_bottom_sheet.dart';
import 'package:Memento/core/route/route_history_manager.dart';
import 'package:Memento/plugins/goods/models/goods_item.dart';
import 'package:Memento/plugins/goods/goods_plugin.dart';
import 'controllers/form_controller.dart';
import 'widgets/basic_info_tab.dart';

/// 物品表单抽屉页面
///
/// 使用 SmoothBottomSheet 实现抽屉式表单
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

  /// 显示物品表单抽屉
  ///
  /// [context] - 上下文
  /// [initialData] - 初始数据（编辑模式）
  /// [onSubmit] - 提交回调
  /// [onDelete] - 删除回调（编辑模式）
  static Future<T?> show<T>({
    required BuildContext context,
    GoodsItem? initialData,
    required Function(GoodsItem) onSubmit,
    Function(GoodsItem)? onDelete,
  }) {
    return SmoothBottomSheet.show<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder:
          (context) => GoodsItemForm(
            initialData: initialData,
            onSubmit: onSubmit,
            onDelete: onDelete,
          ),
    );
  }

  @override
  State<GoodsItemForm> createState() => _GoodsItemFormState();
}

class _GoodsItemFormState extends State<GoodsItemForm> {
  late GoodsItemFormController _formController;

  @override
  void initState() {
    super.initState();
    _formController = GoodsItemFormController(initialData: widget.initialData);

    // 设置路由上下文
    _updateRouteContext();
  }

  /// 更新路由上下文,使"询问当前上下文"功能能获取到当前编辑的物品信息
  void _updateRouteContext() {
    if (widget.initialData != null) {
      final result = GoodsPlugin.instance.findGoodsItemById(
        widget.initialData!.id,
      );
      RouteHistoryManager.updateCurrentContext(
        pageId: "/goods/item_dialog_edit",
        title: '物品 - 编辑: ${widget.initialData!.title}',
        params: {
          'itemId': widget.initialData!.id,
          'itemName': widget.initialData!.title,
          'warehouseId': result?.warehouseId ?? '',
        },
      );
    } else {
      RouteHistoryManager.updateCurrentContext(
        pageId: "/goods/item_dialog_new",
        title: '物品 - 新建物品',
        params: {},
      );
    }
  }

  @override
  void dispose() {
    _formController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formController.validate()) {
      final goodsItem = _formController.buildGoodsItem(widget.initialData?.id);
      widget.onSubmit(goodsItem);
      if (mounted) Navigator.pop(context);
    }
  }

  void _handleDelete() {
    if (widget.initialData != null && widget.onDelete != null) {
      widget.onDelete!(widget.initialData!);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title =
        widget.initialData == null ? 'goods_addItem'.tr : 'goods_editItem'.tr;
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      // 最大高度不超过屏幕的 80%
      height: screenHeight * 0.8,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题栏
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // 删除按钮（编辑模式且有删除回调时显示）
                if (widget.initialData != null && widget.onDelete != null)
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.error,
                    ),
                    onPressed: _handleDelete,
                    tooltip: 'goods_deleteProduct'.tr,
                  ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          const Divider(height: 1),

          // 表单内容
          Expanded(
            child: Form(
              key: _formController.formKey,
              child: BasicInfoTab(
                controller: _formController,
                onStateChanged: () => setState(() {}),
              ),
            ),
          ),

          // 底部保存按钮
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 0,
              ),
              child: Text(
                'goods_save'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],

       
      ),
    );
  }
}
