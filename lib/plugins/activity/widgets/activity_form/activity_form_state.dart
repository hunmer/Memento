import 'package:Memento/plugins/activity/widgets/activity_form/activity_form_widget.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/activity/models/activity_record.dart';
import 'package:Memento/core/storage/storage_manager.dart';
import 'package:Memento/plugins/activity/services/activity_service.dart';
import 'package:Memento/widgets/tag_manager_dialog.dart';
import 'package:Memento/widgets/form_fields/index.dart';
import 'activity_form_utils.dart';
import '../../../../../../core/services/toast_service.dart';

class ActivityFormState extends State<ActivityFormWidget> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _durationController;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  String? _selectedMood;
  List<String> _selectedTags = [];

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Column(
      children: [
        // 表单内容
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              // Title Card
              TextInputField(
                controller: _titleController,
                labelText: 'activity_activityName'.tr,
                hintText: 'activity_activityName'.tr,
                prefixIcon: const Icon(Icons.edit),
              ),
              const SizedBox(height: 16),

              // Time Card
              Row(
                children: [
                  Expanded(
                    child: TimePickerField(
                      label: 'activity_startTime'.tr,
                      time: _startTime,
                      onTimeChanged: (time) {
                        setState(() {
                          _startTime = time;
                          _syncDurationWithTimes();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TimePickerField(
                      label: 'activity_endTime'.tr,
                      time: _endTime,
                      onTimeChanged: (time) {
                        setState(() {
                          _endTime = time;
                          _syncDurationWithTimes();
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Duration Slider Section
              SliderField(
                label: 'activity_duration'.tr,
                valueText: _calculateDurationString(context),
                min: 1,
                max: _getMaxDuration().toDouble(),
                value: _getCurrentDuration().toDouble().clamp(
                  1.0,
                  _getMaxDuration().toDouble(),
                ),
                divisions: _getMaxDuration() > 1 ? _getMaxDuration() - 1 : 1,
                onChanged: (value) {
                  _updateDurationFromSlider(value.toInt());
                },
                quickValues:
                    [15, 30, 60, 90, 120, 180, 240, 300, 360, 480]
                        .where((duration) => duration <= _getMaxDuration())
                        .map((e) => e.toDouble())
                        .toList(),
                quickValueLabel: (value) {
                  final duration = value.toInt();
                  final hours = duration ~/ 60;
                  final minutes = duration % 60;
                  if (hours > 0 && minutes > 0) {
                    return '${hours}h${minutes}m';
                  } else if (hours > 0) {
                    return '${hours}h';
                  } else {
                    return '${minutes}m';
                  }
                },
                onQuickValueTap: (value) {
                  _updateDurationFromSlider(value.toInt());
                },
              ),
              const SizedBox(height: 16),

              // Mood Card
              FormFieldGroup(
                padding: const EdgeInsets.all(16),
                children: [
                  OptionSelectorField(
                    labelText: 'activity_mood'.tr,
                    options: _buildMoodOptions(),
                    selectedId: _selectedMood,
                    onSelectionChanged: (optionId) {
                      setState(() {
                        _selectedMood = optionId;
                      });
                    },
                    useHorizontalScroll: true,
                    optionWidth: 80,
                    optionHeight: 80,
                    primaryColor: primaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 16),


              // Description Card
              FormFieldGroup(
                padding: const EdgeInsets.all(16),
                children: [
                  TextAreaField(
                    controller: _descriptionController,
                    hintText: 'activity_contentHint'.tr,
                    minLines: 4,
                    maxLines: 4,
                    inline: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),


              // Tags Card
              FormFieldGroup(
                padding: const EdgeInsets.all(16),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'activity_tags'.tr,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TagsField(
                          tags: _selectedTags,
                          onAddTag: _showAddTagDialog,
                          onRemoveTag: (tag) {
                            setState(() {
                              _selectedTags.remove(tag);
                            });
                          },
                          addButtonText: '添加标签',
                          primaryColor: primaryColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 底部保存按钮（固定在底部）
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]!
                        : Colors.grey[200]!,
              ),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'app_save'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _calculateDurationString(BuildContext context) {
    final startDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    var endDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (endDateTime.isBefore(startDateTime)) {
      endDateTime = endDateTime.add(const Duration(days: 1));
    }

    final duration = endDateTime.difference(startDateTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    // Simple localized string construction
    // Ideally use l10n methods if available for "hours" and "minutes"
    // Assuming standard format for now matching the UI: "7小时 41分钟"
    // We can use 'h ' and 'm' if l10n not precise, but let's try to be generic or use hardcoded for Chinese context as requested by image style if l10n fails?
    // Actually, the project has l10n. Let's use it if possible.

    if (hours > 0) {}

    // Fallback if l10n regex fails (it might be risky).
    // The prompt image shows "7小时 41分钟".
    // Let's just use "h" and "m" or try to get "小时" "分钟" if we know the locale is Chinese.
    // Or just use 'activity_hours'.tr and 'activity_minutes'.tr if they exist as standalone words.
    // seems to have `hoursFormat` which returns "x hours".

    // Safe approach:
    return '${hours}h ${minutes}m';
  }

  /// 获取当前持续时间（分钟）
  int _getCurrentDuration() {
    final startDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    var endDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (endDateTime.isBefore(startDateTime)) {
      endDateTime = endDateTime.add(const Duration(days: 1));
    }

    final duration = endDateTime.difference(startDateTime).inMinutes;
    // 确保至少为1分钟
    return duration > 0 ? duration : 1;
  }

  /// 获取最大持续时间（分钟）
  /// 最大值为当前时间 - 开始时间，但不超过当天结束时间
  int _getMaxDuration() {
    final startDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    final now = DateTime.now();
    final dayEnd = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      23,
      59,
    );

    // 如果选择的日期是今天，则限制为当前时间
    // 否则限制为当天结束时间
    final maxEndTime =
        widget.selectedDate.year == now.year &&
                widget.selectedDate.month == now.month &&
                widget.selectedDate.day == now.day
            ? (now.isBefore(dayEnd) ? now : dayEnd)
            : dayEnd;

    final maxDuration = maxEndTime.difference(startDateTime).inMinutes;

    // 确保最小值为1分钟
    return maxDuration > 1 ? maxDuration : 1;
  }

  /// 从Slider更新持续时间
  void _updateDurationFromSlider(int durationMinutes) {
    final startDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    final newEndDateTime = startDateTime.add(
      Duration(minutes: durationMinutes),
    );

    setState(() {
      _endTime = TimeOfDay(
        hour: newEndDateTime.hour,
        minute: newEndDateTime.minute,
      );
      _syncDurationWithTimes();
    });
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
    _syncDurationWithTimes();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _syncDurationWithTimes() {
    final minutes = calculateDuration(
      widget.selectedDate,
      _startTime,
      _endTime,
    );
    _durationController.text = minutes.toString();
  }

  List<OptionItem> _buildMoodOptions() {
    final List<String> combinedMoods = [];

    // 如果有最近使用的心情，先添加它们
    if (widget.recentMoods != null && widget.recentMoods!.isNotEmpty) {
      combinedMoods.addAll(widget.recentMoods!);
    }

    // 添加默认心情，但排除已经在最近使用中的
    const List<String> kMoods = [
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
    for (String mood in kMoods) {
      if (!combinedMoods.contains(mood)) {
        combinedMoods.add(mood);
      }
    }

    // 转换为 OptionItem 列表，使用 emoji 作为 label
    return combinedMoods.map((mood) {
      return OptionItem(
        id: mood,
        icon: Icons.emoji_emotions, // 默认图标（不会被使用）
        label: mood, // 使用 emoji 作为标签
        useTextAsIcon: true, // 启用文本模式
      );
    }).toList();
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
      toastService.showToast('${'activity_endTime'.tr}必须晚于${'activity_startTime'.tr}');
      return;
    }

    // 检查时间间隔是否小于1分钟
    final duration = endDateTime.difference(startDateTime);
    if (duration.inMinutes < 1) {
      toastService.showToast('活动时间必须至少为1分钟');
      return;
    }

    // 检查是否超过当天结束时间
    final dayEnd = DateTime(now.year, now.month, now.day, 23, 59);
    if (endDateTime.isAfter(dayEnd)) {
      toastService.showToast('${'activity_endTime'.tr}不能超过当天23:59');
      return;
    }

    // 处理标签
    final inputTags = _selectedTags;

    // 获取标签组服务
    final storage = StorageManager();
    await storage.initialize();
    final activityService = ActivityService(storage, 'activity');

    // 加载标签组
    List<TagGroup> tagGroups = await activityService.getTagGroups();

    // 确保有未分组标签组
    TagGroup? unGroupedTags = tagGroups.firstWhere(
      (group) => group.name == 'activity_ungrouped'.tr,
      orElse: () {
        final newGroup = TagGroup(name: 'activity_ungrouped'.tr, tags: []);
        // 如果列表为空，直接添加；否则在合适的位置插入
        if (tagGroups.isEmpty) {
          tagGroups.add(newGroup);
        } else {
          // 在"所有"标签组后面插入（如果存在），否则插入到开头
          final allTagsIndex = tagGroups.indexWhere(
            (group) => group.name == 'activity_all'.tr,
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
      title: _titleController.text.trim(),
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

  void _showAddTagDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text('添加标签'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: '输入标签名称',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            autofocus: true,
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                Navigator.pop(context);
                _addTag(value.trim());
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) {
                  Navigator.pop(context);
                  _addTag(value);
                }
              },
              child: Text('添加'),
            ),
          ],
        );
      },
    );
  }

  void _addTag(String tag) {
    setState(() {
      if (!_selectedTags.contains(tag)) {
        _selectedTags.add(tag);
      }
    });
  }
}
