import 'package:flutter/material.dart';

/// 日期范围选择器字段组件
///
/// 使用 showDateRangePicker 提供日期范围选择功能
class DateRangeField extends StatelessWidget {
  /// 开始日期
  final DateTime? startDate;

  /// 结束日期
  final DateTime? endDate;

  /// 是否启用
  final bool enabled;

  /// 占位提示文本
  final String? placeholder;

  /// 范围描述文本（如"选择日期范围"）
  final String? rangeLabelText;

  /// 日期变化回调（返回 DateTimeRange）
  final ValueChanged<DateTimeRange?> onDateRangeChanged;

  /// 首次允许选择的日期
  final DateTime? firstDate;

  /// 最后允许选择的日期
  final DateTime? lastDate;

  const DateRangeField({
    super.key,
    this.startDate,
    this.endDate,
    this.enabled = true,
    this.placeholder,
    this.rangeLabelText,
    required this.onDateRangeChanged,
    this.firstDate,
    this.lastDate,
  });

  /// 格式化日期显示
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 构建显示文本
  String _buildDisplayText() {
    if (endDate != null) {
      return '${_formatDate(startDate!)} 至 ${_formatDate(endDate!)}';
    } else if (startDate != null) {
      return _formatDate(startDate!);
    }
    return placeholder ?? '选择日期范围';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? _selectDateRange : null,
      child: Container(
        height: 50,
        padding: const EdgeInsets.only(left: 10, right: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _buildDisplayText(),
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (rangeLabelText != null)
              Text(
                rangeLabelText!,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 显示日期范围选择器
  Future<void> _selectDateRange() async {
    final context = WidgetsBinding.instance.focusManager.primaryFocus?.context;
    if (context == null) return;

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange:
          endDate != null
              ? DateTimeRange(start: startDate!, end: endDate!)
              : startDate != null
              ? DateTimeRange(start: startDate!, end: startDate!)
              : null,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime(2100),
    );

    if (picked != null) {
      onDateRangeChanged(picked);
    }
  }
}
