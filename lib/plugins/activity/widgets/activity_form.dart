import 'package:flutter/material.dart';
import '../models/activity_record.dart';
import 'tag_manager_dialog.dart';
import '../../../core/storage/storage_manager.dart';
import '../services/activity_service.dart';
import '../../../plugins/diary/l10n/diary_localizations.dart';

class ActivityForm extends StatefulWidget {
  final ActivityRecord? activity;
  final Function(ActivityRecord) onSave;
  final DateTime selectedDate;
  final DateTime? initialStartTime;
  final DateTime? initialEndTime;
  final DateTime? lastActivityEndTime;

  const ActivityForm({
    super.key,
    this.activity,
    required this.onSave,
    required this.selectedDate,
    this.initialStartTime,
    this.initialEndTime,
    this.lastActivityEndTime,
  });

  @override
  State<ActivityForm> createState() => _ActivityFormState();
}

class _ActivityFormState extends State<ActivityForm> {
  late DiaryLocalizations l10n;
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
      // 如果有最后一个活动的结束时间，使用它作为开始时间
      // 否则使用当天的 00:00
      if (widget.lastActivityEndTime != null) {
        _startTime = TimeOfDay.fromDateTime(widget.lastActivityEndTime!);
      } else {
        final today = DateTime(
          widget.selectedDate.year,
          widget.selectedDate.month,
          widget.selectedDate.day,
        );
        _startTime = TimeOfDay.fromDateTime(today);
      }

      // 直接使用当前时间作为结束时间
      final now = DateTime.now();
      _endTime = TimeOfDay.fromDateTime(now);
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

  Future<void> _handleSave() async {
    if (!mounted) return;
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

    // 检查时间间隔是否小于1分钟
    final duration = endDateTime.difference(startDateTime);
    if (duration.inMinutes < 1) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('活动时间必须至少为1分钟')));
      return;
    }

    // 检查是否超过当天结束时间
    final dayEnd = DateTime(now.year, now.month, now.day, 23, 59);
    if (endDateTime.isAfter(dayEnd)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('活动结束时间不能超过当天23:59')));
      return;
    }

    // 处理标签
    final inputTags =
        _tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList();

    // 获取标签组服务
    final storage = StorageManager();
    await storage.initialize();
    final activityService = ActivityService(storage, 'activity');

    // 加载标签组
    List<TagGroup> tagGroups = await activityService.getTagGroups();

    // 确保有未分组标签组
    TagGroup? unGroupedTags = tagGroups.firstWhere(
      (group) => group.name == '未分组',
      orElse: () {
        final newGroup = TagGroup(name: '未分组', tags: []);
        // 如果列表为空，直接添加；否则在合适的位置插入
        if (tagGroups.isEmpty) {
          tagGroups.add(newGroup);
        } else {
          // 在"所有"标签组后面插入（如果存在），否则插入到开头
          final allTagsIndex = tagGroups.indexWhere(
            (group) => group.name == '所有',
          );
          if (allTagsIndex != -1) {
            tagGroups.insert(allTagsIndex + 1, newGroup);
          } else {
            tagGroups.insert(0, newGroup);
          }
        }
        return newGroup;
      },
    );

    // 检查新标签并添加到未分组
    for (final tag in inputTags) {
      bool isNewTag = true;
      for (final group in tagGroups) {
        if (group.tags.contains(tag)) {
          isNewTag = false;
          break;
        }
      }
      if (isNewTag && !unGroupedTags.tags.contains(tag)) {
        unGroupedTags.tags.add(tag);
      }
    }

    // 保存更新后的标签组
    await activityService.saveTagGroups(tagGroups);

    // 创建活动记录
    final activity = ActivityRecord(
      startTime: startDateTime,
      endTime: endDateTime,
      title:
          _titleController.text.trim().isEmpty
              ? l10n.unnamedActivity
              : _titleController.text.trim(),
      description:
          _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
      tags: inputTags,
      mood: _selectedMood,
    );

    widget.onSave(activity);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    l10n = DiaryLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activity == null ? l10n.addActivity : l10n.editActivity),
        centerTitle: true,
        leadingWidth: 80, // 为左侧按钮预留足够空间
        leading: Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: TextButton.icon(
            icon: const Icon(Icons.close),
            label: Text(l10n.cancel),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              textStyle: const TextStyle(fontSize: 14),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: TextButton.icon(
              icon: const Icon(Icons.check),
              label: Text(l10n.save),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                textStyle: const TextStyle(fontSize: 14),
              ),
              onPressed: _handleSave,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: l10n.activityName,
                  border: const OutlineInputBorder(),
                  helperText: l10n.unnamedActivity,
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
                            Text(
                              l10n.startTime,
                              style: const TextStyle(
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
                        if (!mounted) return;
                          final result = await showDialog<String>(
                            context: context,
                            builder:
                                (BuildContext context) => AlertDialog(
                                  title: Text(l10n.editInterval),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: Text(l10n.cancelButton),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(int.parse(_durationController.text));
                                      },
                                      child: Text(l10n.confirmButton),
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
                            Text(
                              l10n.interval,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_calculateDuration()}${l10n.minutes}',
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
                            Text(
                              l10n.endTime,
                              style: const TextStyle(
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
                decoration: InputDecoration(
                labelText: l10n.activityDescription,
                border: const OutlineInputBorder(),
              ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagsController,
                      decoration: InputDecoration(
                labelText: l10n.tags,
                border: const OutlineInputBorder(),
                hintText: l10n.tagsHint,
                helperText: l10n.tagsHelperText,
              ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.label),
                    onPressed: () async {
                      // 获取标签组服务
                      final storage = StorageManager();
                      await storage.initialize();
                      final activityService = ActivityService(
                        storage,
                        'activity',
                      );

                      // 加载保存的标签组
                      List<TagGroup> tagGroups =
                          await activityService.getTagGroups();

                      // 确保存在所有和未分组标签组
                      if (!tagGroups.any((group) => group.name == '所有')) {
                        tagGroups.insert(0, TagGroup(name: '所有', tags: []));
                      }
                      if (!tagGroups.any((group) => group.name == '未分组')) {
                        // 检查是否存在"最近使用"标签组
                        final recentIndex = tagGroups.indexWhere(
                          (group) => group.name == '最近使用',
                        );
                        if (recentIndex != -1) {
                          // 在"最近使用"之后插入"未分组"
                          tagGroups.insert(
                            recentIndex + 1,
                            TagGroup(name: '未分组', tags: []),
                          );
                        } else {
                          // 在"所有"之后插入"未分组"
                          final allIndex = tagGroups.indexWhere(
                            (group) => group.name == '所有',
                          );
                          if (allIndex != -1) {
                            tagGroups.insert(
                              allIndex + 1,
                              TagGroup(name: '未分组', tags: []),
                            );
                          } else {
                            // 如果没有"所有"，直接添加到列表末尾
                            tagGroups.add(TagGroup(name: '未分组', tags: []));
                          }
                        }
                      }

                      final result = await showDialog<List<String>>(
                        context: context,
                        builder:
                            (BuildContext context) => TagManagerDialog(
                              groups: tagGroups,
                              selectedTags: _selectedTags,
                              onGroupsChanged: (updatedGroups) async {
                                // 保存更新后的标签组
                                await activityService.saveTagGroups(
                                  updatedGroups,
                                );
                              },
                            ),
                      );

                      if (result != null) {
                        setState(() {
                          _selectedTags = result;
                          _tagsController.text = _selectedTags.join(', ');
                        });
                      }
                    },
                    tooltip: l10n.tags,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 心情选择器
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.selectMood,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                                        ).primaryColor.withAlpha(51)
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
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
