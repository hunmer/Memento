part of 'goods_plugin.dart';

// 注册数据选择器
void _registerDataSelectors() {
  final pluginDataSelectorService = PluginDataSelectorService.instance;

  // 注册仓库选择器（单级）
  pluginDataSelectorService.registerSelector(
    SelectorDefinition(
      id: 'goods.warehouse',
      pluginId: GoodsPlugin.instance.id,
      name: '选择仓库',
      icon: GoodsPlugin.instance.icon,
      color: GoodsPlugin.instance.color,
      steps: [
        SelectorStep(
          id: 'warehouse',
          title: '选择仓库',
          viewType: SelectorViewType.list,
          isFinalStep: true,
          dataLoader: (_) async {
            return GoodsPlugin.instance.warehouses
                .map(
                  (warehouse) => SelectableItem(
                    id: warehouse.id,
                    title: warehouse.title,
                    subtitle: '${warehouse.items.length} 件物品',
                    icon: warehouse.icon,
                    color: warehouse.iconColor,
                    rawData: warehouse.toJson(),
                  ),
                )
                .toList();
          },
        ),
      ],
    ),
  );

  // 注册物品选择器（两级：仓库 → 物品）
  pluginDataSelectorService.registerSelector(
    SelectorDefinition(
      id: 'goods.item',
      pluginId: GoodsPlugin.instance.id,
      name: '选择物品',
      icon: GoodsPlugin.instance.icon,
      color: GoodsPlugin.instance.color,
      steps: [
        // 第一级：选择仓库
        SelectorStep(
          id: 'warehouse',
          title: '选择仓库',
          viewType: SelectorViewType.list,
          isFinalStep: false,
          dataLoader: (_) async {
            return GoodsPlugin.instance.warehouses
                .map(
                  (warehouse) => SelectableItem(
                    id: warehouse.id,
                    title: warehouse.title,
                    subtitle: '${warehouse.items.length} 件物品',
                    icon: warehouse.icon,
                    color: warehouse.iconColor,
                    rawData: warehouse.toJson(),
                  ),
                )
                .toList();
          },
        ),
        // 第二级：选择物品
        SelectorStep(
          id: 'item',
          title: '选择物品',
          viewType: SelectorViewType.list,
          isFinalStep: true,
          dataLoader: (previousSelections) async {
            final warehouse = Warehouse.fromJson(
              previousSelections['warehouse'] as Map<String, dynamic>,
            );
            // 传递 warehouseId 到 rawData 中
            return _getAllItemsRecursively(warehouse.items, warehouse.id);
          },
        ),
      ],
    ),
  );

  // 注册物品列表配置选择器（自定义表单）
  pluginDataSelectorService.registerSelector(
    SelectorDefinition(
      id: 'goods.list.config',
      pluginId: GoodsPlugin.instance.id,
      name: 'goods_listConfigSelectorName'.tr,
      icon: Icons.tune,
      searchable: false,
      color: GoodsPlugin.instance.color,
      steps: [
        SelectorStep(
          id: 'config',
          title: 'goods_listConfigSelectorName'.tr,
          viewType: SelectorViewType.customForm,
          dataLoader: (_) async => [],
          isFinalStep: true,
          customFormBuilder: (context, previousSelections, onComplete) {
            return _GoodsListConfigForm(
              onComplete: (config) {
                onComplete(config);
              },
            );
          },
        ),
      ],
    ),
  );
}

// 递归获取所有物品（包含子物品），转换为 SelectableItem 列表
List<SelectableItem> _getAllItemsRecursively(
  List<GoodsItem> items,
  String warehouseId, {
  String prefix = '',
  // 添加 warehouseId 参数
}) {
  List<SelectableItem> result = [];
  for (var item in items) {
    // 直接构建包含 warehouseId 的 rawData
    final itemJson = <String, dynamic>{
      'id': item.id,
      'title': item.title,
      'imageUrl': item.imageUrl,
      'thumbUrl': item.thumbUrl,
      'iconData': item.icon?.codePoint,
      'iconColor': item.iconColor?.value,
      'tags': item.tags,
      'purchaseDate': item.purchaseDate?.toIso8601String(),
      'expirationDate': item.expirationDate?.toIso8601String(),
      'purchasePrice': item.purchasePrice,
      'quantity': item.quantity,
      'status': item.status,
      'usageRecords': item.usageRecords.map((record) => record.toJson()).toList(),
      'customFields': item.customFields.map((field) => field.toJson()).toList(),
      'notes': item.notes,
      'subItems': item.subItems.map((subItem) => subItem.toJson()).toList(),
      'warehouseId': warehouseId,  // 添加 warehouseId
    };

    result.add(
      SelectableItem(
        id: item.id,
        title: prefix.isNotEmpty ? '$prefix${item.title}' : item.title,
        subtitle:
            item.purchasePrice != null
                ? '¥${item.purchasePrice!.toStringAsFixed(2)}'
                : null,
        icon: item.icon,
        color: item.iconColor,
        rawData: itemJson,
      ),
    );
    // 递归处理子物品
    if (item.subItems.isNotEmpty) {
      result.addAll(
        _getAllItemsRecursively(
          item.subItems,
          warehouseId,
          prefix: '$prefix${item.title} > ',
        ),
      );
    }
  }
  return result;
}

/// 物品列表配置表单
class _GoodsListConfigForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onComplete;

  const _GoodsListConfigForm({required this.onComplete});

  @override
  State<_GoodsListConfigForm> createState() => _GoodsListConfigFormState();
}

class _GoodsListConfigFormState extends State<_GoodsListConfigForm> {
  String? _selectedWarehouseId;
  final Set<String> _selectedTags = {};
  DateTime? _startDate;
  DateTime? _endDate;
  String? _dateType; // 'purchase' 或 'expiration'

  List<Warehouse> _warehouses = [];
  List<String> _allTags = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final plugin = GoodsPlugin.instance;

    setState(() {
      _warehouses = List.from(plugin.warehouses);

      // 获取所有标签
      final tagsSet = <String>{};
      for (final warehouse in _warehouses) {
        for (final item in warehouse.items) {
          tagsSet.addAll(item.tags);
          _collectTagsFromSubItems(item.subItems, tagsSet);
        }
      }
      _allTags = tagsSet.toList()..sort();

      _isLoading = false;
    });
  }

  void _collectTagsFromSubItems(List<GoodsItem> items, Set<String> tagsSet) {
    for (final item in items) {
      tagsSet.addAll(item.tags);
      if (item.subItems.isNotEmpty) {
        _collectTagsFromSubItems(item.subItems, tagsSet);
      }
    }
  }

  void _confirm() {
    widget.onComplete({
      'warehouseId': _selectedWarehouseId,
      'tags': _selectedTags.toList(),
      'startDate': _startDate?.toIso8601String(),
      'endDate': _endDate?.toIso8601String(),
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 配置选项
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildTitleInput(),
                  const SizedBox(height: 16),
                  _buildWarehouseSelector(),
                  const SizedBox(height: 16),
                  _buildTagSelector(),
                  const SizedBox(height: 16),
                  _buildDateTypeSelector(),
                  if (_dateType != null) ...[
                    const SizedBox(height: 16),
                    _buildDateRangeSelector(),
                  ],
                ],
              ),
            ),
            // 底部按钮
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('goods_cancel'.tr),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _confirm,
                      child: Text('goods_confirm'.tr),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'goods_widgetTitle'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            filled: true,
            hintText: 'goods_widgetTitleHint'.tr,
          ),
          onChanged: (value) {
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildWarehouseSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'goods_selectWarehouse'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedWarehouseId ?? 'all',
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            filled: true,
          ),
          items: [
            DropdownMenuItem(value: 'all', child: Text('goods_allItems'.tr)),
            ..._warehouses.map((warehouse) {
              final itemCount = _countItems(warehouse.items);
              return DropdownMenuItem(
                value: warehouse.id,
                child: Text('${warehouse.title} • $itemCount'),
              );
            }),
          ],
          onChanged: (value) {
            setState(
              () => _selectedWarehouseId = value == 'all' ? null : value,
            );
          },
        ),
      ],
    );
  }

  int _countItems(List<GoodsItem> items) {
    int count = items.length;
    for (final item in items) {
      count += _countItems(item.subItems);
    }
    return count;
  }

  Widget _buildTagSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'goods_selectTagsTitle'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_allTags.isEmpty)
          Text(
            'goods_noTags'.tr,
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _allTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                  );
                }).toList(),
          ),
      ],
    );
  }

  Widget _buildDateTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'goods_selectDateTypeTitle'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: Text('goods_purchaseDate'.tr),
                selected: _dateType == 'purchase',
                onSelected: (selected) {
                  setState(() => _dateType = selected ? 'purchase' : null);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceChip(
                label: Text('goods_expirationDate'.tr),
                selected: _dateType == 'expiration',
                onSelected: (selected) {
                  setState(() => _dateType = selected ? 'expiration' : null);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateRangeSelector() {
    final label =
        _dateType == 'purchase'
            ? 'goods_purchaseDateRange'.tr
            : 'goods_expirationDateRange'.tr;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label (${'goods_optional'.tr})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (date != null) setState(() => _startDate = date);
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _startDate == null
                      ? 'goods_startDate'.tr
                      : DateFormat('yyyy-MM-dd').format(_startDate!),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (date != null) setState(() => _endDate = date);
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _endDate == null
                      ? 'goods_endDate'.tr
                      : DateFormat('yyyy-MM-dd').format(_endDate!),
                ),
              ),
            ),
          ],
        ),
        if (_startDate != null || _endDate != null)
          TextButton.icon(
            onPressed:
                () => setState(() {
                  _startDate = null;
                  _endDate = null;
                }),
            icon: const Icon(Icons.clear, size: 16),
            label: Text('goods_clear'.tr),
          ),
      ],
    );
  }
}
