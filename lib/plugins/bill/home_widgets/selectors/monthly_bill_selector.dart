library;

/// 月份账单配置选择器表单

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../bill_colors.dart';

/// 月份账单配置表单
class MonthlyBillSelector extends StatefulWidget {
  final Function(Map<String, dynamic>) onComplete;

  const MonthlyBillSelector({super.key, required this.onComplete});

  @override
  State<MonthlyBillSelector> createState() => _MonthlyBillSelectorState();
}

class _MonthlyBillSelectorState extends State<MonthlyBillSelector> {
  // 选择的月份
  DateTime _selectedMonth = DateTime.now();

  // 可选的账户
  String? _selectedAccountId;

  // 月份选项（过去12个月）
  List<DateTime> get _monthOptions {
    final now = DateTime.now();
    return List.generate(
      12,
      (index) => DateTime(now.year, now.month - index, 1),
    );
  }

  String _formatMonth(DateTime month) {
    return DateFormat('yyyy年MM月').format(month);
  }

  void _confirm() {
    widget.onComplete({
      'month': DateFormat('yyyy-MM').format(_selectedMonth),
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
                  Icon(Icons.calendar_month, color: billColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'bill_monthlySelectorTitle'.tr,
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
                  // 月份选择
                  Text(
                    'bill_selectMonth'.tr,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: _monthOptions.map((month) {
                        final isSelected =
                            month.year == _selectedMonth.year &&
                            month.month == _selectedMonth.month;
                        return ListTile(
                          title: Text(_formatMonth(month)),
                          trailing: isSelected
                              ? Icon(Icons.check, color: billColor)
                              : null,
                          selected: isSelected,
                          selectedTileColor: billColor.withOpacity(0.1),
                          onTap: () {
                            setState(() => _selectedMonth = month);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 快捷按钮
                  Wrap(
                    spacing: 8,
                    children: [
                      ActionChip(
                        label: Text('bill_thisMonth'.tr),
                        onPressed: () {
                          setState(() => _selectedMonth = DateTime.now());
                        },
                      ),
                      ActionChip(
                        label: Text('bill_lastMonth'.tr),
                        onPressed: () {
                          final now = DateTime.now();
                          setState(() {
                            _selectedMonth = DateTime(now.year, now.month - 1, 1);
                          });
                        },
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
