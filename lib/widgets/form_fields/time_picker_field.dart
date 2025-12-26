import 'package:flutter/material.dart';
import 'builders/index.dart' show createRoundedContainerDecoration;

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
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: enabled ? () => _selectTime(context) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: createRoundedContainerDecoration(context),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(time),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
