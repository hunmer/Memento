import 'package:Memento/plugins/goods/l10n/goods_localizations.dart';
import 'package:flutter/material.dart';
import '../../models/goods_item.dart';
import 'controllers/form_controller.dart';
import 'widgets/basic_info_tab.dart';
import 'widgets/usage_records_tab.dart';
import 'widgets/sub_items_tab.dart';

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
  late GoodsItemFormController _formController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _formController = GoodsItemFormController(initialData: widget.initialData);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            widget.initialData == null
                ? GoodsLocalizations.of(context)!.addItem
                : GoodsLocalizations.of(context)!.editItem,
          ),
          centerTitle: true,
          leading: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(GoodsLocalizations.of(context)!.cancel),
          ),
          actions: [
            TextButton(
              onPressed: _submitForm,
              child: Text(GoodsLocalizations.of(context)!.save),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: GoodsLocalizations.of(context)!.basicInfo),
              Tab(text: GoodsLocalizations.of(context)!.usageRecords),
              Tab(text: GoodsLocalizations.of(context)!.subItems),
            ],
          ),
        ),
        body: Form(
          key: _formController.formKey,
          child: TabBarView(
            children: [
              BasicInfoTab(
                controller: _formController,
                onStateChanged: () => setState(() {}),
                onDelete: widget.onDelete != null ? _handleDelete : null,
                showDeleteButton: widget.initialData != null,
              ),
              UsageRecordsTab(
                controller: _formController,
                onStateChanged: () => setState(() {}),
              ),
              SubItemsTab(
                controller: _formController,
                onStateChanged: () => setState(() {}),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
