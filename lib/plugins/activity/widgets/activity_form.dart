import 'package:flutter/material.dart';
import '../models/activity_record.dart';
import 'tag_manager_dialog.dart';

class ActivityForm extends StatefulWidget {
  final ActivityRecord? activity;
  final Function(ActivityRecord) onSave;
  final DateTime selectedDate;
  final DateTime? initialStartTime;
  final DateTime? initialEndTime;

  const ActivityForm({
    super.key,
    this.activity,
    required this.onSave,
    required this.selectedDate,
    this.initialStartTime,
    this.initialEndTime,
  });

  @override
  State<ActivityForm> createState() => _ActivityFormState();
}

class _ActivityFormState extends State<ActivityForm> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _tagsController;
  late TextEditingController _durationController;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  String? _selectedMood;
  List<String> _selectedTags = [];

  // 常用的心情emoji列表
  final List<String> _moods = [
    '😊',
    '😃',
    '🙂',
    '😐',
    '😢',
    '😡',
    '😴',
    '🤔',
    '😎',
    '🥳',
  ];

  @override
  void initState() {
    super.initState();
    final activity = widget.activity;

    _titleController = TextEditingController(text: activity?.title ?? '');
    _descriptionController = TextEditingController(
      text: activity?.description ?? '',
    );
    _selectedTags = activity?.tags ?? [];
    _tagsController = TextEditingController(text: _selectedTags.join(', '));
    _durationController = TextEditingController(text: '60');
    _selectedMood = activity?.mood;

    if (activity != null) {
      _startTime = TimeOfDay.fromDateTime(activity.startTime);
      _endTime = TimeOfDay.fromDateTime(activity.endTime);
    } else if (widget.initialStartTime != null &&
        widget.initialEndTime != null) {
      // 使用提供的初始开始和结束时间
      _startTime = TimeOfDay.fromDateTime(widget.initialStartTime!);
      _endTime = TimeOfDay.fromDateTime(widget.initialEndTime!);
    } else {
      // 使用当前时间作为默认值
      final now = DateTime.now();
      _startTime = TimeOfDay.fromDateTime(widget.initialStartTime ?? now);
      _endTime = TimeOfDay.fromDateTime(
        widget.initialEndTime ?? now.add(const Duration(hours: 1)),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  int _calculateDuration() {
    final startDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    // 处理跨天情况
    final duration =
        endDateTime.isAfter(startDateTime)
            ? endDateTime.difference(startDateTime)
            : endDateTime
                .add(const Duration(days: 1))
                .difference(startDateTime);

    return duration.inMinutes;
  }

  void _handleSave() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入活动标题')));
      return;
    }

    // 创建DateTime对象
    final now = widget.selectedDate;
    final startDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _endTime.hour,
      _endTime.minute,
    );

    // 检查时间是否有效
    if (endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('结束时间必须晚于开始时间')));
      return;
    }

    // 使用已选择的标签
    final tags = _selectedTags;

    // 创建活动记录
    final activity = ActivityRecord(
      startTime: startDateTime,
      endTime: endDateTime,
      title: _titleController.text,
      description:
          _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
      tags: tags,
      mood: _selectedMood,
    );

    widget.onSave(activity);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.activity == null ? '新建活动' : '编辑活动',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '活动标题',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // 时间范围和间隔控制
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 开始时间
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: InkWell(
                        onTap: () => _selectTime(context, true),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '开始',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 间隔时间按钮
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: TextButton(
                        onPressed: () async {
                          final result = await showDialog<String>(
                            context: context,
                            builder:
                                (BuildContext context) => AlertDialog(
                                  title: const Text('修改时间间隔'),
                                  content: TextField(
                                    controller: _durationController,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    decoration: const InputDecoration(
                                      labelText: '间隔（分钟）',
                                      border: OutlineInputBorder(),
                                      alignLabelWithHint: true,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.of(context).pop(),
                                      child: const Text('取消'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(
                                          context,
                                        ).pop(_durationController.text);
                                      },
                                      child: const Text('确定'),
                                    ),
                                  ],
                                ),
                          );

                          if (result != null) {
                            final minutes = int.tryParse(result);
                            if (minutes != null && minutes > 0) {
                              setState(() {
                                final startDateTime = DateTime(
                                  widget.selectedDate.year,
                                  widget.selectedDate.month,
                                  widget.selectedDate.day,
                                  _startTime.hour,
                                  _startTime.minute,
                                );
                                final newEndDateTime = startDateTime.add(
                                  Duration(minutes: minutes),
                                );
                                _endTime = TimeOfDay(
                                  hour: newEndDateTime.hour,
                                  minute: newEndDateTime.minute,
                                );
                                _durationController.text = minutes.toString();
                              });
                            }
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          backgroundColor: Theme.of(
                            context,
                          ).primaryColor.withAlpha(25),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '间隔',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_calculateDuration()}分钟',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 结束时间
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: InkWell(
                        onTap: () => _selectTime(context, false),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '结束',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '描述（可选）',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagsController,
                      decoration: const InputDecoration(
                        labelText: '标签（用逗号分隔）',
                        border: OutlineInputBorder(),
                        hintText: '例如: 工作, 学习, 运动',
                      ),
                      readOnly: true,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.label),
                    onPressed: () async {
                      // 示例标签组
                      final tagGroups = [
                        TagGroup(
                          name: '工作',
                          tags: ['会议', '编程', '写作', '阅读', '学习'],
                        ),
                        TagGroup(
                          name: '生活',
                          tags: ['运动', '购物', '休息', '娱乐', '社交'],
                        ),
                        TagGroup(name: '健康', tags: ['锻炼', '冥想', '饮食', '睡眠']),
                      ];

                      final result = await showDialog<List<String>>(
                        context: context,
                        builder:
                            (BuildContext context) => TagManagerDialog(
                              groups: tagGroups,
                              selectedTags: _selectedTags,
                            ),
                      );

                      if (result != null) {
                        setState(() {
                          _selectedTags = result;
                          _tagsController.text = _selectedTags.join(', ');
                        });
                      }
                    },
                    tooltip: '选择标签',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 心情选择器
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '选择心情',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children:
                        _moods.map((emoji) {
                          final isSelected = _selectedMood == emoji;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedMood = isSelected ? null : emoji;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? Theme.of(
                                          context,
                                        ).primaryColor.withOpacity(0.2)
                                        : null,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? Theme.of(context).primaryColor
                                          : Colors.transparent,
                                ),
                              ),
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _handleSave,
                    child: const Text('保存'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
