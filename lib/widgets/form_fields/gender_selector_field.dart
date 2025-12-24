import 'package:flutter/material.dart';
import 'package:Memento/plugins/contact/models/contact_model.dart';

/// 性别选择器字段
///
/// 功能特性：
/// - 支持男/女性别选择
/// - 统一的 Material Design 3 样式
/// - 可选性别（支持 null）
class GenderSelectorField extends StatelessWidget {
  /// 当前选中的性别
  final ContactGender? selectedGender;

  /// 性别变更回调
  final Function(ContactGender?) onGenderChanged;

  /// 是否启用
  final bool enabled;

  const GenderSelectorField({
    super.key,
    this.selectedGender,
    required this.onGenderChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          _buildGenderOption(
            context,
            ContactGender.male,
            Icons.male,
            'Male',
            theme.colorScheme.primary,
          ),
          _buildGenderOption(
            context,
            ContactGender.female,
            Icons.female,
            'Female',
            theme.colorScheme.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption(
    BuildContext context,
    ContactGender gender,
    IconData icon,
    String label,
    Color color,
  ) {
    final theme = Theme.of(context);
    final isSelected = selectedGender == gender;

    return Expanded(
      child: GestureDetector(
        onTap: enabled
            ? () {
                // 切换性别：如果已选中则取消选择，否则选中
                onGenderChanged(isSelected ? null : gender);
              }
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? theme.cardColor : null,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
