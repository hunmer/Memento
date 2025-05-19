import 'package:Memento/plugins/activity/widgets/activity_form/activity_form_widget.dart';
import 'package:flutter/material.dart';
import '../../models/activity_record.dart';
import '../../../../core/storage/storage_manager.dart';
import '../../services/activity_service.dart';
import '../../../../plugins/diary/l10n/diary_localizations.dart';
import 'package:Memento/widgets/tag_manager_dialog.dart';
import 'activity_form_utils.dart';
import 'activity_time_section.dart';

class ActivityFormState extends State<ActivityFormWidget> {
  late DiaryLocalizations l10n;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _tagsController;
  late TextEditingController _durationController;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  String? _selectedMood;
  List<String> _selectedTags = [];
  
  @override
  Widget build(BuildContext context) {
    l10n = DiaryLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activity == null ? l10n.addActivity : l10n.editActivity),
        actions: [
          TextButton(
            onPressed: _handleSave,
            child: Text(
              l10n.save,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题输入
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: l10n.activityName,
                hintText: l10n.unnamedActivity,
                border: const OutlineInputBorder(),
              ),
              maxLines: 1,
            ),
            
            const SizedBox(height: 16),
            
            // 时间选择部分
            ActivityTimeSection(
              startTime: _startTime,
              endTime: _endTime,
              selectedDate: widget.selectedDate,
              durationController: _durationController,
              onSelectTime: (isStartTime) => _selectTime(context, isStartTime),
              onDurationChanged: _handleDurationChanged,
            ),
            
            const SizedBox(height: 16),
            
            // 心情选择器
            MoodSelector(
              selectedMood: _selectedMood,
              onMoodSelected: _selectMood,
              recentMoods: widget.recentMoods,
            ),
            
            const SizedBox(height: 16),
            
            // 标签输入
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _tagsController,
                  decoration: InputDecoration(
                    labelText: l10n.tags,
                    hintText: l10n.tagsHint,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.tag),
                      onPressed: _openTagManager,
                      tooltip: l10n.tagManagement,
                    ),
                  ),
                  maxLines: 1,
                ),
                if (widget.recentTags != null && widget.recentTags!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.only(left: 4.0, bottom: 4.0),
                    child: Text(
                      '最近使用的标签',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.recentTags!.map((tag) {
                      final isSelected = _selectedTags.contains(tag);
                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (!_selectedTags.contains(tag)) {
                              _selectedTags.add(tag);
                              _tagsController.text = _selectedTags.join(', ');
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).primaryColor.withAlpha(50)
                                : Colors.grey.withAlpha(30),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[700],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 描述输入
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: l10n.activityDescription,
                hintText: l10n.contentHint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
          ],
        ),
      ),
    );
  }

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

    // 加载最近使用的心情和标签
    if (widget.recentMoods != null && widget.recentMoods!.isNotEmpty) {
      _selectedMood ??= widget.recentMoods!.first;
    }

    // 设置开始时间
    _startTime = getInitialTime(
      activityTime: activity?.startTime,
      initialTime: widget.initialStartTime,
      lastActivityEndTime: widget.lastActivityEndTime,
      selectedDate: widget.selectedDate,
      isStartTime: true,
    );

    // 设置结束时间
    _endTime = getInitialTime(
      activityTime: activity?.endTime,
      initialTime: widget.initialEndTime,
      selectedDate: widget.selectedDate,
      isStartTime: false,
    );
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

  void _handleDurationChanged(String durationText) {
    final minutes = int.tryParse(durationText);
    if (minutes != null && minutes > 0) {
      setState(() {
        final startDateTime = DateTime(
          widget.selectedDate.year,
          widget.selectedDate.month,
          widget.selectedDate.day,
          _startTime.hour,
          _startTime.minute,
        );
        final newEndDateTime = startDateTime.add(Duration(minutes: minutes));
        _endTime = TimeOfDay(
          hour: newEndDateTime.hour,
          minute: newEndDateTime.minute,
        );
        _durationController.text = minutes.toString();
      });
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('结束时间必须晚于开始时间')),
      );
      return;
    }

    // 检查时间间隔是否小于1分钟
    final duration = endDateTime.difference(startDateTime);
    if (duration.inMinutes < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('活动时间必须至少为1分钟')),
      );
      return;
    }

    // 检查是否超过当天结束时间
    final dayEnd = DateTime(now.year, now.month, now.day, 23, 59);
    if (endDateTime.isAfter(dayEnd)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('活动结束时间不能超过当天23:59')),
      );
      return;
    }

    // 处理标签
    final inputTags = _tagsController.text
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
      title: _titleController.text.trim().isEmpty
          ? l10n.unnamedActivity
          : _titleController.text.trim(),
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
      tags: inputTags,
      mood: _selectedMood,
    );

    widget.onSave(activity);
    Navigator.of(context).pop();
  }

  void _openTagManager() async {
    // 获取标签组服务
    final storage = StorageManager();
    await storage.initialize();
    final activityService = ActivityService(storage, 'activity');

    // 加载保存的标签组
    List<TagGroup> tagGroups = await activityService.getTagGroups();

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

    if (!mounted) return;
    
    final result = await showDialog<List<String>>(
      context: context,
      builder: (BuildContext dialogContext) => TagManagerDialog(
        groups: tagGroups,
        selectedTags: _selectedTags,
        onGroupsChanged: (groups) async {
          await activityService.saveTagGroups(groups);
        },
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedTags = result;
        _tagsController.text = _selectedTags.join(', ');
      });
    }
  }

  void _selectMood(String mood) {
    setState(() {
      _selectedMood = mood;
    });
  }
}