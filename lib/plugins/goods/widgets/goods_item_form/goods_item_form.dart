import 'package:get/get.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:Memento/core/route/route_history_manager.dart';
import 'package:Memento/plugins/goods/models/goods_item.dart';
import 'package:Memento/plugins/goods/goods_plugin.dart';
import 'controllers/form_controller.dart';
import 'widgets/basic_info_tab.dart';

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
      final result = GoodsPlugin.instance.findGoodsItemById(widget.initialData!.id);
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
    }
  }

  void _handleDelete() {
    if (widget.initialData != null && widget.onDelete != null) {
      widget.onDelete!(widget.initialData!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: !(Platform.isAndroid || Platform.isIOS),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        title: Text(
          widget.initialData == null
              ? 'goods_addItem'.tr
              : 'goods_editItem'.tr,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formController.formKey,
        child: BasicInfoTab(
          controller: _formController,
          onStateChanged: () => setState(() {}),
          onDelete: widget.onDelete != null ? _handleDelete : null,
          showDeleteButton: widget.initialData != null,
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}