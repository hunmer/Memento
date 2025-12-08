import 'dart:io';

import 'package:Memento/plugins/goods/l10n/goods_localizations.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/goods/models/goods_item.dart';
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
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !(Platform.isAndroid || Platform.isIOS),
        title: Text(
          widget.initialData == null
              ? GoodsLocalizations.of(context).addItem
              : GoodsLocalizations.of(context).editItem,
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
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: Text(
              GoodsLocalizations.of(context).save,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}