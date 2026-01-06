part of 'day_plugin.dart';

  // ==================== 数据选择器注册 ====================

  void _registerDataSelectors() {
    // 纪念日选择器
    pluginDataSelectorService.registerSelector(SelectorDefinition(
      id: 'day.memorial',
      pluginId: DayPlugin.instance.id,
      name: '选择纪念日',
      icon: DayPlugin.instance.icon,
      color: DayPlugin.instance.color,
      searchable: true,
      selectionMode: SelectionMode.single,
      steps: [
        SelectorStep(
          id: 'memorial',
          title: '选择纪念日',
          viewType: SelectorViewType.list,
          isFinalStep: true,
          dataLoader: (_) async {
            return DayPlugin.instance._controller.memorialDays.map((day) {
              // 计算倒计时文本
              String subtitle;
              if (day.isToday) {
                subtitle = '今天';
              } else if (day.daysRemaining > 0) {
                subtitle = '剩余 ${day.daysRemaining} 天';
              } else {
                subtitle = '已过 ${day.daysPassed} 天';
              }

              // 添加日期信息
              subtitle += ' · ${day.formattedTargetDate}';

              return SelectableItem(
                id: day.id,
                title: day.title,
                subtitle: subtitle,
                icon: Icons.event_outlined,
                rawData: day,
              );
            }).toList();
          },
          searchFilter: (items, query) {
            if (query.isEmpty) return items;
            final lowerQuery = query.toLowerCase();
            return items.where((item) =>
              item.title.toLowerCase().contains(lowerQuery)
            ).toList();
          },
        ),
      ],
    ));

    // 日期范围选择器 - 基于天数的范围选择
    pluginDataSelectorService.registerSelector(SelectorDefinition(
      id: 'day.dateRange',
      pluginId: DayPlugin.instance.id,
      name: 'day_dateRangeFilter'.tr,
      icon: Icons.date_range,
      color: DayPlugin.instance.color,
      searchable: false,
      selectionMode: SelectionMode.single,
      steps: [
        SelectorStep(
          id: 'dateRange',
          title: 'day_dateRangeFilter'.tr,
          viewType: SelectorViewType.customForm,
          isFinalStep: true,
          dataLoader: (_) async {
            return [];
          },
          customFormBuilder: (context, previousSelections, onComplete) {
            return _DateRangeSelectionForm(
              onComplete: onComplete,
            );
          },
        ),
      ],
    ));
  }

/// 日期范围选择表单（包含预设选项和自定义输入）
class _DateRangeSelectionForm extends StatefulWidget {
  final Function(dynamic) onComplete;

  const _DateRangeSelectionForm({
    required this.onComplete,
  });

  @override
  State<_DateRangeSelectionForm> createState() =>
      _DateRangeSelectionFormState();
}

class _DateRangeSelectionFormState extends State<_DateRangeSelectionForm> {
  bool _showCustomInput = false;

  // 预设选项
  final List<Map<String, dynamic>> _presetOptions = [
    {
      'id': 'next_7',
      'title': '未来7天',
      'subtitle': '今天起往后7天',
      'icon': Icons.arrow_upward,
      'data': {'startDay': 0, 'endDay': 7, 'title': '未来7天'},
    },
    {
      'id': 'next_30',
      'title': '未来30天',
      'subtitle': '今天起往后30天',
      'icon': Icons.trending_up,
      'data': {'startDay': 0, 'endDay': 30, 'title': '未来30天'},
    },
    {
      'id': 'past_7',
      'title': '过去7天',
      'subtitle': '往前7天到今天',
      'icon': Icons.arrow_downward,
      'data': {'startDay': -7, 'endDay': 0, 'title': '过去7天'},
    },
    {
      'id': 'past_30',
      'title': '过去30天',
      'subtitle': '往前30天到今天',
      'icon': Icons.trending_down,
      'data': {'startDay': -30, 'endDay': 0, 'title': '过去30天'},
    },
    {
      'id': 'around_7',
      'title': '前后7天',
      'subtitle': '往前7天到往后7天',
      'icon': Icons.sync_alt,
      'data': {'startDay': -7, 'endDay': 7, 'title': '前后7天'},
    },
    {
      'id': 'around_30',
      'title': '前后30天',
      'subtitle': '往前30天到往后30天',
      'icon': Icons.all_inclusive,
      'data': {'startDay': -30, 'endDay': 30, 'title': '前后30天'},
    },
    {
      'id': 'all',
      'title': 'day_allDays'.tr,
      'subtitle': '显示所有纪念日',
      'icon': Icons.calendar_today,
      'data': {'startDay': null, 'endDay': null, 'title': 'day_allDays'.tr},
    },
  ];

  void _selectPreset(Map<String, dynamic> option) {
    widget.onComplete(option['data']);
  }

  void _showCustomInputDialog() {
    setState(() {
      _showCustomInput = true;
    });
  }

  void _hideCustomInputDialog() {
    setState(() {
      _showCustomInput = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showCustomInput) {
      return _CustomDateRangeInputForm(
        onComplete: (data) {
          widget.onComplete(data);
        },
        onCancel: _hideCustomInputDialog,
      );
    }

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 说明文字
        Icon(
          Icons.date_range,
          size: 64,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'day_dateRangeFilter'.tr,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '选择一个预设范围或输入自定义范围',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // 预设选项列表
        Expanded(
          child: ListView.builder(
            itemCount: _presetOptions.length + 1, // +1 for custom button
            itemBuilder: (context, index) {
              // 最后一个显示自定义输入按钮
              if (index == _presetOptions.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('自定义范围'),
                    subtitle: const Text('输入自定义天数范围'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _showCustomInputDialog,
                  ),
                );
              }

              final option = _presetOptions[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  leading: Icon(option['icon']),
                  title: Text(option['title']),
                  subtitle: Text(option['subtitle']),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _selectPreset(option),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 自定义日期范围输入表单
class _CustomDateRangeInputForm extends StatefulWidget {
  final Function(dynamic) onComplete;
  final VoidCallback onCancel;

  const _CustomDateRangeInputForm({
    required this.onComplete,
    required this.onCancel,
  });

  @override
  State<_CustomDateRangeInputForm> createState() =>
      _CustomDateRangeInputFormState();
}

class _CustomDateRangeInputFormState extends State<_CustomDateRangeInputForm> {
  final TextEditingController _startDayController = TextEditingController();
  final TextEditingController _endDayController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isValid = false;

  @override
  void dispose() {
    _startDayController.dispose();
    _endDayController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final startDay = int.tryParse(_startDayController.text);
      final endDay = int.tryParse(_endDayController.text);

      if (startDay != null && endDay != null) {
        String title;
        if (startDay == 0 && endDay > 0) {
          title = '未来$endDay天';
        } else if (startDay < 0 && endDay == 0) {
          title = '过去${startDay.abs()}天';
        } else if (startDay < 0 && endDay > 0) {
          title = '前后$endDay天';
        } else {
          title = '$startDay到$endDay天';
        }

        widget.onComplete({
          'startDay': startDay,
          'endDay': endDay,
          'title': title,
        });
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
          // 标题栏
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onCancel,
              ),
              const Expanded(
                child: Text(
                  '自定义天数范围',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48), // 平衡布局
            ],
          ),
          const SizedBox(height: 16),

          // 说明文字
          Text(
            '输入起始天数和结束天数（负数表示过去，正数表示未来）',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // 起始天数输入框
          TextFormField(
            controller: _startDayController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: '起始天数',
              hintText: '例如：-7',
              prefixIcon: const Icon(Icons.arrow_back),
              suffixText: '天',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入起始天数';
              }
              final number = int.tryParse(value);
              if (number == null) {
                return '请输入有效的数字';
              }
              if (number < -3650 || number > 3650) {
                return '天数范围应在 -3650 到 3650 之间';
              }
              return null;
            },
            onChanged: (_) => _validateForm(),
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),

          // 结束天数输入框
          TextFormField(
            controller: _endDayController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '结束天数',
              hintText: '例如：7',
              prefixIcon: const Icon(Icons.arrow_forward),
              suffixText: '天',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入结束天数';
              }
              final number = int.tryParse(value);
              if (number == null) {
                return '请输入有效的数字';
              }
              if (number < -3650 || number > 3650) {
                return '天数范围应在 -3650 到 3650 之间';
              }
              return null;
            },
            onChanged: (_) => _validateForm(),
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),

          // 推荐范围
          Text(
            '推荐范围：',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              {'start': -7, 'end': 7, 'label': '前后7天'},
              {'start': -30, 'end': 30, 'label': '前后30天'},
              {'start': 0, 'end': 7, 'label': '未来7天'},
              {'start': 0, 'end': 30, 'label': '未来30天'},
            ].map((config) {
              return FilledButton.tonal(
                onPressed: () {
                  _startDayController.text = config['start'].toString();
                  _endDayController.text = config['end'].toString();
                  setState(() {
                    _isValid = true;
                  });
                  _submit();
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(80, 36),
                ),
                child: Text(config['label'] as String),
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

  void _validateForm() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (_isValid != isValid) {
      setState(() {
        _isValid = isValid;
      });
    }
  }
}
