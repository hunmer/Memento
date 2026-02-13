library;

/// 账单统计配置选择器表单

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../bill_colors.dart';

/// 账单统计配置表单
class BillStatsSelector extends StatefulWidget {
  final Function(Map<String, dynamic>) onComplete;

  const BillStatsSelector({super.key, required this.onComplete});

  @override
  State<BillStatsSelector> createState() => _BillStatsSelectorState();
}

class _BillStatsSelectorState extends State<BillStatsSelector> {
  // 统计类型
  String _selectedType = 'expense';

  // 日期范围
  String _selectedPeriod = '本月';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  // 目标金额
  double _targetAmount = 5000.0;

  // 可选的账户
  String? _selectedAccountId;

  // 周期选项
  final List<String> _periods = ['本周', '本月', '本年', '自定义'];

  @override
  void initState() {
    super.initState();
    _updateDateRange(_selectedPeriod);
  }

  void _updateDateRange(String period) {
    final now = DateTime.now();
    switch (period) {
      case '本周':
        final weekday = now.weekday;
        _startDate = now.subtract(Duration(days: weekday - 1));
        _endDate = _startDate.add(const Duration(days: 6));
        break;
      case '本月':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case '本年':
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year, 12, 31);
        break;
      case '自定义':
        // 保持当前选择的日期
        break;
    }

    // 设置为当天结束
    _endDate = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedPeriod = '自定义';
      });
    }
  }

  void _confirm() {
    widget.onComplete({
      'type': _selectedType,
      'startDate': _startDate.toIso8601String(),
      'endDate': _endDate.toIso8601String(),
      'targetAmount': _targetAmount,
      'accountId': _selectedAccountId,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 标题
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.pie_chart, color: billColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'bill_statsSelectorTitle'.tr,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // 配置选项
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 统计类型选择
                  Text(
                    'bill_selectType'.tr,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'income',
                        label: Text('income'.tr),
                        icon: const Icon(Icons.arrow_downward),
                      ),
                      ButtonSegment(
                        value: 'expense',
                        label: Text('expense'.tr),
                        icon: const Icon(Icons.arrow_upward),
                      ),
                      ButtonSegment(
                        value: 'balance',
                        label: Text('balance'.tr),
                        icon: const Icon(Icons.account_balance),
                      ),
                    ],
                    selected: {_selectedType},
                    onSelectionChanged: (value) {
                      setState(() => _selectedType = value.first);
                    },
                  ),
                  const SizedBox(height: 24),

                  // 时间范围选择
                  Text(
                    'bill_selectPeriod'.tr,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _periods.map((period) {
                      final isSelected = _selectedPeriod == period;
                      return ChoiceChip(
                        label: Text(period),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedPeriod = period;
                            _updateDateRange(period);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),

                  // 日期范围显示/选择
                  InkWell(
                    onTap: _selectDateRange,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outline),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.date_range, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            '${DateFormat('yyyy-MM-dd').format(_startDate)} ~ ${DateFormat('yyyy-MM-dd').format(_endDate)}',
                          ),
                          const Spacer(),
                          if (_selectedPeriod == '自定义')
                            Icon(Icons.edit, size: 16, color: theme.colorScheme.outline),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 目标金额设置
                  Text(
                    'bill_targetAmount'.tr,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _targetAmount,
                          min: 1000,
                          max: 50000,
                          divisions: 49,
                          label: '¥${_targetAmount.toStringAsFixed(0)}',
                          onChanged: (value) {
                            setState(() => _targetAmount = value);
                          },
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: Text(
                          '¥${_targetAmount.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
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
                      child: Text('cancel'.tr),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _confirm,
                      child: Text('confirm'.tr),
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
}
