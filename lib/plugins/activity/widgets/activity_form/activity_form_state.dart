import 'package:Memento/plugins/activity/widgets/activity_form/activity_form_widget.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/activity/models/activity_record.dart';
import 'package:Memento/core/storage/storage_manager.dart';
import 'package:Memento/plugins/activity/services/activity_service.dart';
import 'package:Memento/widgets/form_fields/index.dart';
import 'package:Memento/plugins/activity/models/tag_group.dart';
import 'activity_form_utils.dart';
import '../../../../../../core/services/toast_service.dart';

class ActivityFormState extends State<ActivityFormWidget> {
  // 存储时间和滑块值的引用，用于联动
  TimeOfDay? _currentStartTime;
  TimeOfDay? _currentEndTime;
  int? _currentDuration;

  // 存储字段值
  String? _titleValue;
  String? _descriptionValue;
  String? _moodValue;
  List<String>? _tagsValue;

  // 从历史记录加载的最近标签
  List<String> _recentTags = [];

  @override
  void didUpdateWidget(ActivityFormWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 检测初始时间的变化
    final startTimeChanged =
        oldWidget.initialStartTime != widget.initialStartTime;
    final endTimeChanged = oldWidget.initialEndTime != widget.initialEndTime;

    if (startTimeChanged || endTimeChanged) {
      // 重新计算时间
      final initialStartTime = getInitialTime(
        activityTime: widget.activity?.startTime,
        initialTime: widget.initialStartTime,
        lastActivityEndTime: widget.lastActivityEndTime,
        selectedDate: widget.selectedDate,
        isStartTime: true,
      );

      final initialEndTime = getInitialTime(
        activityTime: widget.activity?.endTime,
        initialTime: widget.initialEndTime,
        selectedDate: widget.selectedDate,
        isStartTime: false,
      );

      setState(() {
        if (startTimeChanged) {
          _currentStartTime = initialStartTime;
        }
        if (endTimeChanged) {
          _currentEndTime = initialEndTime;
        }
        // 重新计算持续时间
        if (_currentStartTime != null && _currentEndTime != null) {
          _currentDuration = calculateDuration(
            widget.selectedDate,
            _currentStartTime!,
            _currentEndTime!,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    // 初始化时间
    final initialStartTime = getInitialTime(
      activityTime: widget.activity?.startTime,
      initialTime: widget.initialStartTime,
      lastActivityEndTime: widget.lastActivityEndTime,
      selectedDate: widget.selectedDate,
      isStartTime: true,
    );

    final initialEndTime = getInitialTime(
      activityTime: widget.activity?.endTime,
      initialTime: widget.initialEndTime,
      selectedDate: widget.selectedDate,
      isStartTime: false,
    );

    _currentStartTime ??= initialStartTime;
    _currentEndTime ??= initialEndTime;
    _currentDuration ??= calculateDuration(
      widget.selectedDate,
      initialStartTime,
      initialEndTime,
    );

    // 初始化字段值
    _titleValue ??= widget.activity?.title ?? '';
    _descriptionValue ??= widget.activity?.description;
    _moodValue ??=
        widget.activity?.mood ??
        (widget.recentMoods?.isNotEmpty == true
            ? widget.recentMoods!.first
            : '😊');
    _tagsValue ??= widget.activity?.tags ?? _recentTags;

    // 构建字段配置
    final fieldConfigs = [
      // 标题输入
      FormFieldConfig(
        name: 'title',
        type: FormFieldType.text,
        labelText: 'activity_activityName'.tr,
        hintText: 'activity_activityName'.tr,
        initialValue: widget.activity?.title ?? '',
        prefixIcon: Icons.edit,
        onChanged: (value) => _titleValue = value as String?,
      ),

      // 心情选择
      FormFieldConfig(
        name: 'mood',
        type: FormFieldType.optionSelector,
        labelText: 'activity_mood'.tr,
        initialValue:
            widget.activity?.mood ?? '',
        options: _buildMoodOptions(),
        useHorizontalScroll: true,
        optionWidth: 80,
        optionHeight: 80,
        primaryColor: primaryColor,
        onChanged: (value) => _moodValue = value as String?,
      ),

      // 描述输入
      FormFieldConfig(
        name: 'description',
        type: FormFieldType.textArea,
        labelText: 'activity_content'.tr,
        hintText: 'activity_contentHint'.tr,
        initialValue: widget.activity?.description ?? '',
        extra: {'minLines': 4, 'maxLines': 4},
        onChanged: (value) => _descriptionValue = value as String?,
      ),

      // 标签选择
      FormFieldConfig(
        name: 'tags',
        type: FormFieldType.tags,
        labelText: 'activity_tags'.tr,
        hintText: '添加标签',
        initialTags: widget.activity?.tags ?? [],
        extra: {
          'primaryColor': primaryColor,
          'labelText': 'activity_tags'.tr,
          'quickSelectTags': _recentTags,
        },
        onChanged: (value) => _tagsValue = value as List<String>?,
      ),
    ];

    return Column(
      children: [
        // 表单内容
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              FormBuilderWrapper(
                config: FormConfig(
                  fieldSpacing: 16,
                  showSubmitButton: false,
                  showResetButton: false,
                  fields: fieldConfigs,
                  onSubmit: (values) {},
                ),
                contentBuilder: (context, fields) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // 标题输入 (fields[0])
                      fields[0],
                      const SizedBox(height: 16),

                      // 时间选择行（自定义，不在 fields 中）
                      Row(
                        children: [
                          Expanded(
                            child: TimePickerField(
                              label: 'activity_startTime'.tr,
                              time: _currentStartTime!,
                              onTimeChanged: (time) {
                                setState(() {
                                  _currentStartTime = time;
                                  _updateDurationFromTimes();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TimePickerField(
                              label: 'activity_endTime'.tr,
                              time: _currentEndTime!,
                              onTimeChanged: (time) {
                                setState(() {
                                  _currentEndTime = time;
                                  _updateDurationFromTimes();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 持续时间滑块（自定义，不在 fields 中）
                      SliderField(
                        label: 'activity_duration'.tr,
                        valueText: _calculateDurationString(context),
                        min: 1,
                        max: _getMaxDuration().toDouble(),
                        value: _currentDuration!.toDouble().clamp(
                          1.0,
                          _getMaxDuration().toDouble(),
                        ),
                        divisions:
                            _getMaxDuration() > 1 ? _getMaxDuration() - 1 : 1,
                        onChanged: (value) {
                          setState(() {
                            _updateDurationFromSlider(value.toInt());
                          });
                        },
                        quickValues:
                            [15, 30, 60, 90, 120, 180, 240, 300, 360, 480]
                                .where(
                                  (duration) => duration <= _getMaxDuration(),
                                )
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
                          setState(() {
                            _updateDurationFromSlider(value.toInt());
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // 标签选择 (fields[3])
                      fields[3],
                      const SizedBox(height: 16),

                      // 心情选择 (fields[1])
                      fields[1],
                      const SizedBox(height: 16),

                      // 描述输入 (fields[2])
                      fields[2],
                      const SizedBox(height: 16),
                    ],
                  );
                },
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
              onPressed: _handleSaveWithValidation,
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

  /// 构建心情选项列表
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
        icon: Icons.emoji_emotions,
        label: mood,
        useTextAsIcon: true,
      );
    }).toList();
  }

  /// 计算持续时间字符串
  String _calculateDurationString(BuildContext context) {
    if (_currentStartTime == null || _currentEndTime == null) {
      return '0h 0m';
    }

    final startDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _currentStartTime!.hour,
      _currentStartTime!.minute,
    );
    var endDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _currentEndTime!.hour,
      _currentEndTime!.minute,
    );

    if (endDateTime.isBefore(startDateTime)) {
      endDateTime = endDateTime.add(const Duration(days: 1));
    }

    final duration = endDateTime.difference(startDateTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    return '${hours}h ${minutes}m';
  }

  /// 获取当前持续时间（分钟）
  int _getCurrentDuration() {
    if (_currentStartTime == null || _currentEndTime == null) {
      return 60;
    }

    final startDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _currentStartTime!.hour,
      _currentStartTime!.minute,
    );
    var endDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _currentEndTime!.hour,
      _currentEndTime!.minute,
    );

    if (endDateTime.isBefore(startDateTime)) {
      endDateTime = endDateTime.add(const Duration(days: 1));
    }

    final duration = endDateTime.difference(startDateTime).inMinutes;
    return duration > 0 ? duration : 1;
  }

  /// 获取最大持续时间（分钟）
  int _getMaxDuration() {
    if (_currentStartTime == null) {
      return 60;
    }

    final startDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _currentStartTime!.hour,
      _currentStartTime!.minute,
    );

    final now = DateTime.now();
    final dayEnd = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      23,
      59,
    );

    final maxEndTime =
        widget.selectedDate.year == now.year &&
                widget.selectedDate.month == now.month &&
                widget.selectedDate.day == now.day
            ? (now.isBefore(dayEnd) ? now : dayEnd)
            : dayEnd;

    final maxDuration = maxEndTime.difference(startDateTime).inMinutes;
    return maxDuration > 1 ? maxDuration : 1;
  }

  /// 从滑块更新持续时间
  void _updateDurationFromSlider(int durationMinutes) {
    if (_currentStartTime == null) return;

    final startDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _currentStartTime!.hour,
      _currentStartTime!.minute,
    );

    final newEndDateTime = startDateTime.add(
      Duration(minutes: durationMinutes),
    );

    _currentEndTime = TimeOfDay(
      hour: newEndDateTime.hour,
      minute: newEndDateTime.minute,
    );
    _currentDuration = durationMinutes;
  }

  /// 从时间更新持续时间
  void _updateDurationFromTimes() {
    _currentDuration = _getCurrentDuration();
  }

  /// 带验证的保存处理
  void _handleSaveWithValidation() async {
    // 验证时间
    if (_currentEndTime == null || _currentStartTime == null) {
      toastService.showToast('请选择活动时间');
      return;
    }

    final now = widget.selectedDate;
    final startDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _currentStartTime!.hour,
      _currentStartTime!.minute,
    );
    final endDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _currentEndTime!.hour,
      _currentEndTime!.minute,
    );

    // 检查时间是否有效
    if (endDateTime.isBefore(startDateTime)) {
      toastService.showToast(
        '${'activity_endTime'.tr}必须晚于${'activity_startTime'.tr}',
      );
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

    // 准备表单值
    final values = <String, dynamic>{
      'title': _titleValue!.trim(),
      'description': _descriptionValue,
      'mood': _moodValue,
      'tags': _tagsValue ?? [],
    };

    // 调用实际保存方法
    await _handleSave(values);
  }

  /// 实际保存处理
  Future<void> _handleSave(Map<String, dynamic> values) async {
    if (!mounted) return;

    final now = widget.selectedDate;
    final startDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _currentStartTime!.hour,
      _currentStartTime!.minute,
    );
    final endDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _currentEndTime!.hour,
      _currentEndTime!.minute,
    );

    // 处理标签
    final inputTags = values['tags'] as List<String>? ?? [];

    // 获取标签组服务
    final storage = StorageManager();
    await storage.initialize();
    final activityService = ActivityService(storage, 'activity');

    // 加载标签组
    final tagGroups = await activityService.getTagGroups();

    // 确保有未分组标签组
    var unGroupedTags = tagGroups.firstWhere(
      (group) => group.name == 'activity_ungrouped'.tr,
      orElse: () {
        final newGroup = TagGroup(name: 'activity_ungrouped'.tr, tags: []);
        if (tagGroups.isEmpty) {
          tagGroups.add(newGroup);
        } else {
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
      title: values['title'] as String,
      description:
          (values['description'] as String?)?.isEmpty == true
              ? null
              : values['description'] as String?,
      tags: inputTags,
      mood: values['mood'] as String?,
    );

    await widget.onSave(activity);
  }

  @override
  void initState() {
    super.initState();
    _loadRecentTags();
  }

  /// 从历史记录加载最近标签
  Future<void> _loadRecentTags() async {
    final storage = StorageManager();
    await storage.initialize();
    final activityService = ActivityService(storage, 'activity');
    final recentTags = await activityService.getRecentTags();
    if (mounted) {
      setState(() {
        _recentTags = recentTags;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
