import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/plugins/timer/models/timer_item.dart';
import 'package:Memento/plugins/timer/views/add_timer_item_dialog.dart';
import 'package:Memento/core/services/timer/models/timer_state.dart';

/// 计时器列表字段组件
///
/// 显示和管理子计时器列表，支持添加、编辑、删除操作
class TimerItemsField extends StatelessWidget {
  /// 计时器列表
  final List<TimerItem> timerItems;

  /// 添加计时器的回调
  final VoidCallback onAdd;

  /// 编辑计时器的回调
  final Function(int index, TimerItem timer) onEdit;

  /// 删除计时器的回调
  final Function(int index) onRemove;

  /// 添加按钮文本
  final String addButtonText;

  /// 是否启用
  final bool enabled;

  /// 主题色
  final Color? primaryColor;

  const TimerItemsField({
    super.key,
    required this.timerItems,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
    this.addButtonText = 'timer_addTimer',
    this.enabled = true,
    this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 计时器列表标题
        Text(
          '子计时器',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),

        // 空状态提示
        if (timerItems.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Text(
                '暂无子计时器',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),

        // 计时器列表
        ...timerItems.asMap().entries.map((entry) {
          final index = entry.key;
          final timer = entry.value;
          return _buildSubTimerItem(context, timer, index, isDark);
        }),

        const SizedBox(height: 12),

        // 添加按钮
        InkWell(
          onTap: enabled ? onAdd : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add,
                  size: 20,
                  color: isDark ? Colors.white : Colors.grey[700],
                ),
                const SizedBox(width: 8),
                Text(
                  addButtonText.tr,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubTimerItem(BuildContext context, TimerItem timer, int index, bool isDark) {
    String typeText;
    switch (timer.type) {
      case TimerType.countUp:
        typeText = 'timer_countUpTimer'.tr;
        break;
      case TimerType.countDown:
        typeText = 'timer_countDownTimer'.tr;
        break;
      case TimerType.pomodoro:
        typeText = 'timer_pomodoroTimer'.tr;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800]!.withValues(alpha: 0.5) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.drag_indicator,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timer.name.isEmpty ? typeText : timer.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  _formatDuration(timer.duration),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          if (enabled) ...[
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              color: isDark ? Colors.grey[500] : Colors.grey[500],
              onPressed: () async {
                final result = await showDialog<TimerItem>(
                  context: context,
                  builder: (context) => AddTimerItemDialog(initialItem: timer),
                );
                if (result != null) {
                  onEdit(index, result);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              color: isDark ? Colors.grey[500] : Colors.grey[500],
              onPressed: () => onRemove(index),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '${seconds}s';
    }
  }
}
