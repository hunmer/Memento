import 'package:flutter/material.dart';
import 'package:Memento/widgets/form_fields/form_field_wrapper.dart';

/// 所有可用事件的默认列表
const List<EventOption> kDefaultAvailableEvents = [
  // Todo 插件事件
  EventOption(
    eventName: 'task_added',
    category: 'Todo',
    description: '任务已创建',
  ),
  EventOption(
    eventName: 'task_deleted',
    category: 'Todo',
    description: '任务已删除',
  ),
  EventOption(
    eventName: 'task_completed',
    category: 'Todo',
    description: '任务已完成',
  ),

  // Calendar Album 插件事件
  EventOption(
    eventName: 'calendar_entry_added',
    category: 'Calendar Album',
    description: '日记条目已创建',
  ),
  EventOption(
    eventName: 'calendar_entry_updated',
    category: 'Calendar Album',
    description: '日记条目已更新',
  ),
  EventOption(
    eventName: 'calendar_entry_deleted',
    category: 'Calendar Album',
    description: '日记条目已删除',
  ),
  EventOption(
    eventName: 'calendar_tag_added',
    category: 'Calendar Album',
    description: '标签已添加',
  ),
  EventOption(
    eventName: 'calendar_tag_deleted',
    category: 'Calendar Album',
    description: '标签已删除',
  ),

  // Notes 插件事件
  EventOption(
    eventName: 'note_added',
    category: 'Notes',
    description: '笔记已创建',
  ),
  EventOption(
    eventName: 'note_updated',
    category: 'Notes',
    description: '笔记已更新',
  ),
  EventOption(
    eventName: 'note_deleted',
    category: 'Notes',
    description: '笔记已删除',
  ),

  // Habits 插件事件
  EventOption(
    eventName: 'habit_data_changed',
    category: 'Habits',
    description: '习惯数据已变更',
  ),
  EventOption(
    eventName: 'habit_timer_started',
    category: 'Habits',
    description: '习惯计时器已启动',
  ),
  EventOption(
    eventName: 'habit_timer_stopped',
    category: 'Habits',
    description: '习惯计时器已停止',
  ),

  // Checkin 插件事件
  EventOption(
    eventName: 'checkin_deleted',
    category: 'Checkin',
    description: '打卡记录已删除',
  ),

  // Bill 插件事件
  EventOption(
    eventName: 'bill_added',
    category: 'Bill',
    description: '账单已添加',
  ),
  EventOption(
    eventName: 'bill_deleted',
    category: 'Bill',
    description: '账单已删除',
  ),
  EventOption(
    eventName: 'account_added',
    category: 'Bill',
    description: '账户已添加',
  ),
  EventOption(
    eventName: 'account_deleted',
    category: 'Bill',
    description: '账户已删除',
  ),

  // Tracker 插件事件
  EventOption(
    eventName: 'onRecordAdded',
    category: 'Tracker',
    description: '记录已添加',
  ),

  // Calendar 插件事件
  EventOption(
    eventName: 'calendar_event_added',
    category: 'Calendar',
    description: '日历事件已创建',
  ),
  EventOption(
    eventName: 'calendar_event_updated',
    category: 'Calendar',
    description: '日历事件已更新',
  ),
  EventOption(
    eventName: 'calendar_event_deleted',
    category: 'Calendar',
    description: '日历事件已删除',
  ),
  EventOption(
    eventName: 'calendar_event_completed',
    category: 'Calendar',
    description: '日历事件已完成',
  ),

  // Database 插件事件
  EventOption(
    eventName: 'database_added',
    category: 'Database',
    description: '数据库已创建',
  ),
  EventOption(
    eventName: 'database_updated',
    category: 'Database',
    description: '数据库已更新',
  ),
  EventOption(
    eventName: 'database_deleted',
    category: 'Database',
    description: '数据库已删除',
  ),
  EventOption(
    eventName: 'database_record_added',
    category: 'Database',
    description: '数据库记录已添加',
  ),
  EventOption(
    eventName: 'database_record_updated',
    category: 'Database',
    description: '数据库记录已更新',
  ),
  EventOption(
    eventName: 'database_record_deleted',
    category: 'Database',
    description: '数据库记录已删除',
  ),

  // Day 插件事件
  EventOption(
    eventName: 'memorial_day_added',
    category: 'Day',
    description: '纪念日已创建',
  ),
  EventOption(
    eventName: 'memorial_day_updated',
    category: 'Day',
    description: '纪念日已更新',
  ),
  EventOption(
    eventName: 'memorial_day_deleted',
    category: 'Day',
    description: '纪念日已删除',
  ),

  // Activity 插件事件
  EventOption(
    eventName: 'activity_added',
    category: 'Activity',
    description: '活动已添加',
  ),
  EventOption(
    eventName: 'activity_updated',
    category: 'Activity',
    description: '活动已更新',
  ),
  EventOption(
    eventName: 'activity_deleted',
    category: 'Activity',
    description: '活动已删除',
  ),

  // Goods 插件事件
  EventOption(
    eventName: 'goods_added',
    category: 'Goods',
    description: '物品已添加',
  ),
  EventOption(
    eventName: 'goods_deleted',
    category: 'Goods',
    description: '物品已删除',
  ),

  // Timer 插件事件
  EventOption(
    eventName: 'timer_item_changed',
    category: 'Timer',
    description: '计时器状态变化',
  ),
  EventOption(
    eventName: 'timer_task_changed',
    category: 'Timer',
    description: '计时任务状态变化',
  ),
  EventOption(
    eventName: 'timer_item_progress',
    category: 'Timer',
    description: '计时器进度更新',
  ),

  // Contact 插件事件
  EventOption(
    eventName: 'contact_created',
    category: 'Contact',
    description: '联系人已创建',
  ),

  // Chat 插件事件
  EventOption(
    eventName: 'onMessageUpdated',
    category: 'Chat',
    description: '消息已更新',
  ),
  EventOption(
    eventName: 'userAvatarUpdated',
    category: 'Chat',
    description: '用户头像已更新',
  ),

  // Agent Chat 插件事件
  EventOption(
    eventName: 'agent_chat_conversation_added',
    category: 'Agent Chat',
    description: '会话已创建',
  ),
  EventOption(
    eventName: 'agent_chat_conversation_updated',
    category: 'Agent Chat',
    description: '会话已更新',
  ),
  EventOption(
    eventName: 'agent_chat_conversation_deleted',
    category: 'Agent Chat',
    description: '会话已删除',
  ),

  // Store 插件事件
  EventOption(
    eventName: 'store_product_added',
    category: 'Store',
    description: '商品已添加',
  ),
  EventOption(
    eventName: 'store_product_archived',
    category: 'Store',
    description: '商品已归档',
  ),
  EventOption(
    eventName: 'store_product_restored',
    category: 'Store',
    description: '商品已恢复',
  ),
  EventOption(
    eventName: 'store_user_item_added',
    category: 'Store',
    description: '用户物品已添加',
  ),
  EventOption(
    eventName: 'store_user_item_used',
    category: 'Store',
    description: '用户物品已使用',
  ),
  EventOption(
    eventName: 'store_user_item_deleted',
    category: 'Store',
    description: '用户物品已删除',
  ),
  EventOption(
    eventName: 'store_points_changed',
    category: 'Store',
    description: '积分已变化',
  ),

  // Nodes 插件事件
  EventOption(
    eventName: 'nodes_notebook_added',
    category: 'Nodes',
    description: '笔记本已添加',
  ),
  EventOption(
    eventName: 'nodes_notebook_updated',
    category: 'Nodes',
    description: '笔记本已更新',
  ),
  EventOption(
    eventName: 'nodes_notebook_deleted',
    category: 'Nodes',
    description: '笔记本已删除',
  ),
  EventOption(
    eventName: 'nodes_node_added',
    category: 'Nodes',
    description: '节点已添加',
  ),
  EventOption(
    eventName: 'nodes_node_updated',
    category: 'Nodes',
    description: '节点已更新',
  ),
  EventOption(
    eventName: 'nodes_node_deleted',
    category: 'Nodes',
    description: '节点已删除',
  ),

  // OpenAI 插件事件
  EventOption(
    eventName: 'openai_agent_added',
    category: 'OpenAI',
    description: 'AI助手已添加',
  ),
  EventOption(
    eventName: 'openai_agent_updated',
    category: 'OpenAI',
    description: 'AI助手已更新',
  ),
  EventOption(
    eventName: 'openai_agent_deleted',
    category: 'OpenAI',
    description: 'AI助手已删除',
  ),
];

/// 事件选项
class EventOption {
  final String eventName;
  final String category;
  final String description;

  const EventOption({
    required this.eventName,
    required this.category,
    required this.description,
  });
}

/// 事件多选字段
///
/// 功能特性：
/// - 显示事件多选对话框
/// - 显示已选事件数量
/// - 支持自定义可用事件列表
class EventMultiSelectField extends FormFieldWrapper {
  /// 可用事件列表
  final List<EventOption> availableEvents;

  /// 对话框标题
  final String? dialogTitle;

  /// 前缀图标
  final IconData? prefixIcon;

  /// 值变化回调
  @override
  final ValueChanged<dynamic>? onChanged;

  const EventMultiSelectField({
    super.key,
    required super.name,
    this.availableEvents = kDefaultAvailableEvents,
    this.dialogTitle,
    super.initialValue,
    this.prefixIcon,
    this.onChanged,
    super.enabled = true,
  });

  @override
  State<EventMultiSelectField> createState() => _EventMultiSelectFieldState();
}

class _EventMultiSelectFieldState
    extends FormFieldWrapperState<EventMultiSelectField> {
  late List<String> _selectedEvents;

  @override
  void initState() {
    super.initState();
    _selectedEvents = List<String>.from(widget.initialValue ?? []);
  }

  String get _selectedEventsText {
    if (_selectedEvents.isEmpty) return '未选择';
    return '已选择 ${_selectedEvents.length} 个事件';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, color: Colors.deepPurple)
            : const Icon(Icons.event, color: Colors.deepPurple),
        title: const Text('监听的事件'),
        subtitle: Text(_selectedEventsText),
        trailing: const Icon(Icons.chevron_right),
        onTap: widget.enabled ? _showEventSelector : null,
      ),
    );
  }

  Future<void> _showEventSelector() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => EventSelectorDialog(
        availableEvents: widget.availableEvents,
        initialSelectedEvents: _selectedEvents,
        dialogTitle: widget.dialogTitle ?? '选择事件',
      ),
    );

    if (result != null) {
      setState(() {
        _selectedEvents = result;
      });
      widget.onChanged?.call(_selectedEvents);
    }
  }

  @override
  dynamic getValue() => _selectedEvents;
}

/// 事件选择器对话框
class EventSelectorDialog extends StatefulWidget {
  final List<EventOption> availableEvents;
  final List<String> initialSelectedEvents;
  final String dialogTitle;

  const EventSelectorDialog({
    super.key,
    required this.availableEvents,
    required this.initialSelectedEvents,
    required this.dialogTitle,
  });

  @override
  State<EventSelectorDialog> createState() => EventSelectorDialogState();
}

class EventSelectorDialogState extends State<EventSelectorDialog> {
  late Set<String> _selectedEvents;

  /// 是否有选中的事件
  bool get _hasSelection => _selectedEvents.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _selectedEvents = widget.initialSelectedEvents.toSet();
  }

  /// 全选或反选
  void _toggleSelectAll() {
    setState(() {
      if (_hasSelection) {
        // 反选：清空所有选择
        _selectedEvents.clear();
      } else {
        // 全选：选择所有事件
        _selectedEvents =
            widget.availableEvents.map((e) => e.eventName).toSet();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 按分类分组事件
    final groupedEvents = <String, List<EventOption>>{};
    for (final event in widget.availableEvents) {
      groupedEvents.putIfAbsent(event.category, () => []).add(event);
    }

    return AlertDialog(
      title: Text(widget.dialogTitle),
      content: SizedBox(
        width: 400,
        height: 400,
        child: ListView(
          children: groupedEvents.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  child: Text(
                    entry.key,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                ...entry.value.map((event) {
                  final isSelected = _selectedEvents.contains(event.eventName);
                  return CheckboxListTile(
                    title: Text(event.eventName),
                    subtitle: Text(event.description),
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedEvents.add(event.eventName);
                        } else {
                          _selectedEvents.remove(event.eventName);
                        }
                      });
                    },
                  );
                }),
              ],
            );
          }).toList(),
        ),
      ),
      actions: [
        // 左侧全选/反选按钮
        TextButton.icon(
          onPressed: _toggleSelectAll,
          icon: Icon(_hasSelection ? Icons.deselect : Icons.select_all),
          label: Text(_hasSelection ? '反选' : '全选'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.deepPurple,
          ),
        ),
        const Spacer(),
        // 右侧取消/确定按钮
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, _selectedEvents.toList());
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}
