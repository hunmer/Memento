import 'package:flutter/material.dart';
import 'package:Memento/widgets/smooth_bottom_sheet.dart';

/// Chip 选项数据模型
class ChipOption {
  /// 选项ID
  final String id;

  /// 显示标签
  final String label;

  /// 图标（可选）
  final IconData? icon;

  /// 颜色（可选）
  final Color? color;

  const ChipOption({
    required this.id,
    required this.label,
    this.icon,
    this.color,
  });
}

/// Chip 选择器字段组件
///
/// 使用 ActionChip 和底部弹出层实现选项选择
/// 适用于心情、天气等选项选择场景
class ChipSelectorField extends StatelessWidget {
  /// 当前选中的选项ID
  final String? selectedId;

  /// 选项列表
  final List<ChipOption> options;

  /// 占位提示
  final String hintText;

  /// 选择器标题
  final String selectorTitle;

  /// 是否启用
  final bool enabled;

  /// 值变化回调
  final ValueChanged<String?> onValueChanged;

  /// 选中背景色
  final Color? selectedBackgroundColor;

  /// 选中前景色
  final Color? selectedForegroundColor;

  /// 图标（显示在字段前）
  final IconData? icon;

  const ChipSelectorField({
    super.key,
    required this.options,
    required this.onValueChanged,
    this.selectedId,
    this.hintText = '选择',
    this.selectorTitle = '选择',
    this.enabled = true,
    this.selectedBackgroundColor,
    this.selectedForegroundColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final selectedOption = options.firstWhere(
      (opt) => opt.id == selectedId,
      orElse: () => const ChipOption(id: '', label: ''),
    );

    return GestureDetector(
      onTap: enabled ? () => _showSelector(context) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selectedOption.color?.withOpacity(0.1) ??
              (selectedId != null ? Colors.orange.shade50 : null),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 20,
                color: selectedOption.color ?? Colors.orange.shade600,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              selectedId != null ? selectedOption.label : hintText,
              style: TextStyle(
                color: selectedOption.color ?? Colors.orange.shade600,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
            if (enabled) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                size: 20,
                color: (selectedOption.color ?? Colors.orange.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSelector(BuildContext context) {
    SmoothBottomSheet.show(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectorTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((opt) {
                final isSelected = selectedId == opt.id;
                return ActionChip(
                  label: Text(opt.label),
                  backgroundColor: isSelected
                      ? (selectedBackgroundColor ?? Colors.orange.shade100)
                      : null,
                  onPressed: () {
                    onValueChanged(opt.id);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
