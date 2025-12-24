import 'package:flutter/material.dart';

/// 订阅周期选择器字段
///
/// 显示三个快捷按钮：月度(30天)、季度(90天)、年度(365天)
/// 并在下方显示自定义天数输入框
class SubscriptionCycleField extends StatelessWidget {
  /// 当前选中的天数
  final int currentDays;

  /// 天数变化回调
  final ValueChanged<int> onDaysChanged;

  /// 是否启用
  final bool enabled;

  /// 月度按钮文本
  final String monthlyLabel;

  /// 季度按钮文本
  final String quarterlyLabel;

  /// 年度按钮文本
  final String yearlyLabel;

  const SubscriptionCycleField({
    super.key,
    required this.currentDays,
    required this.onDaysChanged,
    this.enabled = true,
    this.monthlyLabel = '月度',
    this.quarterlyLabel = '季度',
    this.yearlyLabel = '年度',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: _buildCycleButton(
                context,
                monthlyLabel,
                30,
                currentDays == 30,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCycleButton(
                context,
                quarterlyLabel,
                90,
                currentDays == 90,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCycleButton(
                context,
                yearlyLabel,
                365,
                currentDays >= 360,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleButton(
    BuildContext context,
    String label,
    int days,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: enabled ? () => onDaysChanged(days) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3))
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
