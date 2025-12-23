import 'package:flutter/material.dart';

/// 时间选择组件
///
/// 功能特性：
/// - 点击弹出时间选择器
/// - 统一的样式和主题适配
/// - 显示标签和时间值
class TimePickerField extends StatelessWidget {
  /// 标签文本
  final String label;

  /// 当前时间值
  final TimeOfDay time;

  /// 时间变化的回调
  final ValueChanged<TimeOfDay>? onTimeChanged;

  /// 是否启用
  final bool enabled;

  /// 主题色
  final Color primaryColor;

  const TimePickerField({
    super.key,
    required this.label,
    required this.time,
    this.onTimeChanged,
    this.enabled = true,
    this.primaryColor = const Color(0xFF607AFB),
  });

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _selectTime(BuildContext context) async {
    if (!enabled || onTimeChanged == null) return;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: time,
    );

    if (picked != null) {
      onTimeChanged!(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: enabled ? () => _selectTime(context) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800]!.withOpacity(0.2) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(time),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.grey[900],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
