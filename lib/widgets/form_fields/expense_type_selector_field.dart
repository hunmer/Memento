import 'package:flutter/material.dart';

/// 收支类型选择器组件
///
/// 用于账单编辑界面选择收入/支出类型
class ExpenseTypeSelectorField extends StatelessWidget {
  /// 是否为支出（true=支出，false=收入）
  final bool isExpense;

  /// 类型变化回调
  final ValueChanged<bool> onTypeChanged;

  /// 支出颜色
  final Color expenseColor;

  /// 收入颜色
  final Color incomeColor;

  const ExpenseTypeSelectorField({
    super.key,
    required this.isExpense,
    required this.onTypeChanged,
    this.expenseColor = const Color(0xFFE74C3C),
    this.incomeColor = const Color(0xFF2ECC71),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;
    final selectedBgColor = isDark ? const Color(0xFF1F2937) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: unselectedColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeButton(
              context: context,
              label: '支出',
              isSelected: isExpense,
              activeColor: expenseColor,
              bgOnSelected: selectedBgColor,
              onTap: () => onTypeChanged(true),
            ),
          ),
          Expanded(
            child: _buildTypeButton(
              context: context,
              label: '收入',
              isSelected: !isExpense,
              activeColor: incomeColor,
              bgOnSelected: selectedBgColor,
              onTap: () => onTypeChanged(false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required Color activeColor,
    required Color bgOnSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? bgOnSelected : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            )
          ] : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? activeColor : Colors.grey,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
