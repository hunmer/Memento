import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 提醒时间管理组件
///
/// 功能特性：
/// - 显示提醒时间列表
/// - 添加新提醒（日期+时间选择器）
/// - 删除提醒
class RemindersField extends StatefulWidget {
  /// 提醒时间列表
  final List<DateTime> reminders;

  /// 删除提醒的回调
  final Function(int index) onRemoveReminder;

  /// 添加提醒后的回调（返回新的提醒列表）
  final Function(List<DateTime> newReminders)? onReminderAdded;

  /// 字段标签
  final String? labelText;

  /// 占位提示文本（无提醒时显示）
  final String? hintText;

  /// 主题色
  final Color primaryColor;

  const RemindersField({
    super.key,
    required this.reminders,
    required this.onRemoveReminder,
    this.onReminderAdded,
    this.labelText,
    this.hintText,
    this.primaryColor = const Color(0xFF607AFB),
  });

  @override
  State<RemindersField> createState() => _RemindersFieldState();
}

class _RemindersFieldState extends State<RemindersField> {
  late List<DateTime> _reminders;

  @override
  void initState() {
    super.initState();
    _reminders = List.from(widget.reminders);
  }

  @override
  void didUpdateWidget(RemindersField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reminders != oldWidget.reminders) {
      _reminders = List.from(widget.reminders);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();

    return InkWell(
      onTap: () => _showRemindersModal(context, locale),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (widget.labelText != null)
              Text(
                widget.labelText!,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              )
            else
              Icon(Icons.alarm, size: 20, color: Theme.of(context).colorScheme.onSurface),
            Expanded(
              child: Text(
                _getDisplayText(locale),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 17,
                  color: _reminders.isNotEmpty
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 获取显示文本
  String _getDisplayText(String locale) {
    if (_reminders.isEmpty) {
      return widget.hintText ?? '无';
    }
    final first = _reminders.first;
    final formatted = DateFormat.yMMMEd(locale).add_jm().format(first);
    if (_reminders.length > 1) {
      return '$formatted (+${_reminders.length - 1})';
    }
    return formatted;
  }

  /// 显示提醒管理模态框
  Future<void> _showRemindersModal(BuildContext context, String locale) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (modalContext) => StatefulBuilder(
        builder: (modalContext, setModalState) {
          return Container(
            padding: const EdgeInsets.all(16),
            height: 450,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.labelText ?? '提醒',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _addReminder(setModalState),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: _reminders.isEmpty
                      ? Center(
                          child: Text(
                            widget.hintText ?? '暂无提醒',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _reminders.length,
                          itemBuilder: (context, index) {
                            final r = _reminders[index];
                            return ListTile(
                              leading: const Icon(Icons.alarm),
                              title: Text(
                                DateFormat.yMMMEd(locale)
                                    .add_jm()
                                    .format(r),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  setState(() => _reminders.removeAt(index));
                                  widget.onRemoveReminder(index);
                                  setModalState(() {});
                                },
                              ),
                            );
                          },
                        ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  /// 添加提醒
  Future<void> _addReminder(StateSetter setModalState) async {
    final baseDate = _reminders.isNotEmpty
        ? _reminders.last
        : DateTime.now();

    // 选择日期
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: baseDate,
      firstDate: DateTime.now(),
      lastDate: baseDate.add(const Duration(days: 365)),
    );

    if (pickedDate == null) return;

    // 选择时间
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    // 组合日期和时间
    final reminderDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() => _reminders.add(reminderDateTime));
    widget.onReminderAdded?.call(_reminders);
    setModalState(() {});
  }
}
