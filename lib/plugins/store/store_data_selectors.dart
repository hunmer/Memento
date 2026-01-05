part of 'store_plugin.dart';

// ==================== 数据选择器注册 ====================

/// 注册数据选择器
void _registerDataSelectors() {
  final selectorService = PluginDataSelectorService.instance;

  // 注册积分目标配置选择器（表单类型）
  selectorService.registerSelector(
    SelectorDefinition(
      id: 'store.pointsGoalForm',
      pluginId: StorePlugin.instance.id,
      name: '积分目标配置',
      description: '设置每日积分目标',
      icon: Icons.flag,
      color: Colors.orange,
      searchable: false,
      selectionMode: SelectionMode.single,
      steps: [
        // 直接使用自定义表单视图
        SelectorStep(
          id: 'goal_input',
          title: '设置每日积分目标',
          viewType: SelectorViewType.customForm,
          isFinalStep: true,
          dataLoader: (_) async {
            // 返回空列表，因为使用自定义UI
            return [];
          },
          customFormBuilder: (context, previousSelections, onComplete) {
            return _CustomGoalInputForm(
              onComplete: onComplete,
            );
          },
        ),
      ],
    ),
  );

  // 注册商品选择器
  selectorService.registerSelector(
    SelectorDefinition(
      id: 'store.product',
      pluginId: StorePlugin.instance.id,
      name: 'store_productSelectorName'.tr,
      description: 'store_productSelectorDesc'.tr,
      icon: StorePlugin.instance.icon,
      color: StorePlugin.instance.color,
      searchable: true,
      selectionMode: SelectionMode.single,
      steps: [
        SelectorStep(
          id: 'product',
          title: 'store_selectProduct'.tr,
          viewType: SelectorViewType.grid,
          isFinalStep: true,
          dataLoader: (_) async {
            return StorePlugin.instance.controller.products.map((product) {
              // 构建副标题：价格 + 库存
              final subtitle =
                  '${product.price} ${'store_points'.tr} · ${'store_stockLabel'.tr}: ${product.stock}';

              return SelectableItem(
                id: product.id,
                title: product.name,
                subtitle: subtitle,
                icon: Icons.shopping_bag,
                rawData: product.toJson(),
              );
            }).toList();
          },
          searchFilter: (items, query) {
            if (query.isEmpty) return items;
            final lowerQuery = query.toLowerCase();
            return items.where((item) {
              final matchesTitle = item.title.toLowerCase().contains(
                lowerQuery,
              );
              final productData = item.rawData as Map<String, dynamic>;
              final description = productData['description'] as String? ?? '';
              final matchesDescription = description.toLowerCase().contains(
                lowerQuery,
              );
              return matchesTitle || matchesDescription;
            }).toList();
          },
        ),
      ],
    ),
  );

  // 注册用户物品选择器
  selectorService.registerSelector(
    SelectorDefinition(
      id: 'store.userItem',
      pluginId: StorePlugin.instance.id,
      name: 'store_userItemSelectorName'.tr,
      description: 'store_userItemSelectorDesc'.tr,
      icon: Icons.inventory_2,
      color: StorePlugin.instance.color,
      searchable: true,
      selectionMode: SelectionMode.single,
      steps: [
        SelectorStep(
          id: 'userItem',
          title: 'store_selectUserItem'.tr,
          viewType: SelectorViewType.list,
          isFinalStep: true,
          dataLoader: (_) async {
            return StorePlugin.instance.controller.userItems.map((item) {
              final productSnapshot = item.productSnapshot;
              final productName =
                  productSnapshot['name'] as String? ?? '未知物品';
              final remaining = item.remaining;
              final expireDate = item.expireDate;
              final remainingDays =
                  expireDate.difference(DateTime.now()).inDays;

              // 构建副标题：剩余次数 + 过期信息
              String subtitle;
              if (remainingDays < 0) {
                subtitle = '$remaining ${'store_times'.tr} · 已过期';
              } else if (remainingDays <= 7) {
                subtitle =
                    '$remaining ${'store_times'.tr} · 剩余 $remainingDays 天';
              } else {
                subtitle = '$remaining ${'store_times'.tr}';
              }

              return SelectableItem(
                id: item.id,
                title: productName,
                subtitle: subtitle,
                icon: Icons.inventory_2,
                rawData: item.toJson(),
              );
            }).toList();
          },
          searchFilter: (items, query) {
            if (query.isEmpty) return items;
            final lowerQuery = query.toLowerCase();
            return items.where((item) {
              final matchesTitle = item.title.toLowerCase().contains(
                lowerQuery,
              );
              final itemData = item.rawData as Map<String, dynamic>;
              final productSnapshot =
                  itemData['productSnapshot'] as Map<String, dynamic>? ?? {};
              final description =
                  productSnapshot['description'] as String? ?? '';
              final matchesDescription = description.toLowerCase().contains(
                lowerQuery,
              );
              return matchesTitle || matchesDescription;
            }).toList();
          },
        ),
      ],
    ),
  );
}

/// 自定义目标输入表单
class _CustomGoalInputForm extends StatefulWidget {
  final Function(dynamic) onComplete;

  const _CustomGoalInputForm({
    required this.onComplete,
  });

  @override
  State<_CustomGoalInputForm> createState() => _CustomGoalInputFormState();
}

class _CustomGoalInputFormState extends State<_CustomGoalInputForm> {
  final TextEditingController _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isValid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final value = int.tryParse(_controller.text);
      if (value != null && value > 0) {
        widget.onComplete({'goal': value});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 说明文字
          Icon(
            Icons.flag,
            size: 64,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            '设置你的每日积分目标',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '输入一个正整数作为你的每日目标',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // 输入框
          TextFormField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: '目标积分',
              hintText: '例如：50',
              prefixIcon: const Icon(Icons.emoji_events),
              suffixText: '积分',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入目标值';
              }
              final number = int.tryParse(value);
              if (number == null) {
                return '请输入有效的数字';
              }
              if (number <= 0) {
                return '目标值必须大于0';
              }
              if (number > 10000) {
                return '目标值不能超过10000';
              }
              return null;
            },
            onChanged: (value) {
              // 更新按钮状态
              final isValid = _formKey.currentState?.validate() ?? false;
              if (_isValid != isValid) {
                setState(() {
                  _isValid = isValid;
                });
              }
            },
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),

          // 推荐目标
          Text(
            '推荐目标：',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [20, 50, 100, 200].map((value) {
              return FilledButton.tonal(
                onPressed: () {
                  _controller.text = value.toString();
                  setState(() {
                    _isValid = true;
                  });
                  _submit();
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(60, 36),
                ),
                child: Text('$value'),
              );
            }).toList(),
          ),
          const Spacer(),

          // 确定按钮
          FilledButton(
            onPressed: _isValid ? _submit : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: theme.colorScheme.primary,
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
