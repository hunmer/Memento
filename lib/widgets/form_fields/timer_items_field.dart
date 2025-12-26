import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/plugins/timer/models/timer_item.dart';
import 'package:Memento/plugins/timer/views/add_timer_item_dialog.dart';
import 'package:Memento/core/services/timer/models/timer_state.dart';
import 'builders/index.dart' show createRoundedContainerDecoration;

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
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 计时器列表标题
        Text(
          '子计时器',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
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
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ),

        // 计时器列表
        ...timerItems.asMap().entries.map((entry) {
          final index = entry.key;
          final timer = entry.value;
          return _buildSubTimerItem(context, timer, index);
        }),

        const SizedBox(height: 12),

        // 添加按钮
        InkWell(
          onTap: enabled ? onAdd : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: createRoundedContainerDecoration(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  addButtonText.tr,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubTimerItem(BuildContext context, TimerItem timer, int index) {
    final theme = Theme.of(context);

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
      decoration: createRoundedContainerDecoration(context),
      child: Row(
        children: [
          Icon(
            Icons.drag_indicator,
            color: theme.colorScheme.onSurfaceVariant,
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
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  _formatDuration(timer.duration),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (enabled) ...[
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              color: theme.colorScheme.onSurfaceVariant,
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
              color: theme.colorScheme.onSurfaceVariant,
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
