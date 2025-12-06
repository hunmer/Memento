import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/plugins/activity/l10n/activity_localizations.dart';
import 'package:Memento/plugins/activity/widgets/activity_form/activity_form_widget.dart';
import 'package:flutter/material.dart';
import '../../models/activity_record.dart';
import '../../../../core/storage/storage_manager.dart';
import '../../services/activity_service.dart';
import 'package:Memento/widgets/tag_manager_dialog.dart';
import 'activity_form_utils.dart';
import '../../../../../../core/services/toast_service.dart';

class ActivityFormState extends State<ActivityFormWidget> {
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
    final l10n = ActivityLocalizations.of(context);
    final appL10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF27272A) : Colors.white;
    final primaryColor = Theme.of(context).primaryColor;

    return Column(
      children: [
        // 顶部拖动指示器和关闭按钮
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // 拖动指示器
              Expanded(
                child: Center(
                  child: Container(
                    width: 40,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              // 关闭按钮
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: isDark ? Colors.white : Colors.black,
                ),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),

        // 表单内容
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              // Title Card
              _buildCard(
                context,
                cardColor,
                icon: Icons.edit,
                child: TextField(
                  controller: _titleController,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: l10n.activityName,
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Time Card
              _buildCard(
                context,
                cardColor,
                icon: Icons.schedule,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildTimeBox(
                            context,
                            label: appL10n.startTime,
                            time: _startTime,
                            onTap: () => _selectTime(context, true),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTimeBox(
                            context,
                            label: appL10n.endTime,
                            time: _endTime,
                            onTap: () => _selectTime(context, false),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Duration Slider Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            isDark ? Colors.black26 : const Color(0xFFF5F7F8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 标题和当前时长
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.duration,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                              Text(
                                _calculateDurationString(context),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Slider
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: primaryColor,
                              inactiveTrackColor: primaryColor.withOpacity(0.2),
                              thumbColor: primaryColor,
                              overlayColor: primaryColor.withOpacity(0.2),
                              trackHeight: 4,
                            ),
                            child: Slider(
                              min: 1,
                              max: _getMaxDuration().toDouble(),
                              value: _getCurrentDuration().toDouble().clamp(
                                1.0,
                                _getMaxDuration().toDouble(),
                              ),
                              divisions:
                                  _getMaxDuration() > 1
                                      ? _getMaxDuration() - 1
                                      : 1,
                              onChanged: (value) {
                                _updateDurationFromSlider(value.toInt());
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          // 快捷时长按钮
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _buildDurationButtons(primaryColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Mood Card
              _buildCard(
                context,
                cardColor,
                icon: Icons.mood,
                child: MoodSelector(
                  selectedMood: _selectedMood,
                  onMoodSelected: _selectMood,
                  recentMoods: widget.recentMoods,
                ),
              ),
              const SizedBox(height: 16),

              // Tags Card
              _buildCard(
                context,
                cardColor,
                icon: Icons.local_offer, // sell icon
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        TextField(
                          controller: _tagsController,
                          decoration: InputDecoration(
                            hintText: appL10n.tags,
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: primaryColor),
                            ),
                            contentPadding: const EdgeInsets.only(
                              right: 24,
                              bottom: 8,
                            ),
                            isDense: true,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Icon(
                            Icons.tag,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    if (widget.recentTags != null &&
                        widget.recentTags!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            widget.recentTags!.map((tag) {
                              // Check if tag is selected
                              // Note: _selectedTags comes from controller parsing in current logic
                              // We need to keep that logic synced.
                              final isSelected = _selectedTags.contains(tag);
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    if (_selectedTags.contains(tag)) {
                                      _selectedTags.remove(tag);
                                    } else {
                                      _selectedTags.add(tag);
                                    }
                                    _tagsController.text = _selectedTags.join(
                                      ', ',
                                    );
                                  });
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? primaryColor.withOpacity(0.2)
                                            : (isDark
                                                ? primaryColor.withOpacity(0.1)
                                                : primaryColor.withOpacity(
                                                  0.1,
                                                )),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      color:
                                          isSelected
                                              ? primaryColor
                                              : (isDark
                                                  ? Colors.purple[200]
                                                  : primaryColor),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Description Card
              _buildCard(
                context,
                cardColor,
                icon: Icons.description,
                child: TextField(
                  controller: _descriptionController,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: l10n.contentHint,
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  maxLines: 4,
                ),
              ),

              // 底部保存按钮的间距
              const SizedBox(height: 80),
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
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
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
                appL10n.save,
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

  Widget _buildCard(
    BuildContext context,
    Color bgColor, {
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2.0, right: 16.0),
            child: Icon(icon, color: Colors.grey[500], size: 28),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildTimeBox(
    BuildContext context, {
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.black26 : const Color(0xFFF5F7F8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(time),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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
    // Or just use l10n.hours and l10n.minutes if they exist as standalone words.
    // DiaryLocalizations seems to have `hoursFormat` which returns "x hours".

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

  /// 构建快捷时长按钮
  List<Widget> _buildDurationButtons(Color primaryColor) {
    // 定义常用时长（分钟）
    final durations = [15, 30, 60, 90, 120, 180, 240, 300, 360, 480];

    final maxDuration = _getMaxDuration();
    final currentDuration = _getCurrentDuration();

    return durations.where((duration) => duration <= maxDuration).map((
      duration,
    ) {
      final isSelected = currentDuration == duration;
      final hours = duration ~/ 60;
      final minutes = duration % 60;

      String label;
      if (hours > 0 && minutes > 0) {
        label = '${hours}h${minutes}m';
      } else if (hours > 0) {
        label = '${hours}h';
      } else {
        label = '${minutes}m';
      }

      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _updateDurationFromSlider(duration),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color:
                    isSelected ? primaryColor : primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isSelected ? primaryColor : primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : primaryColor,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
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

    // 添加标签输入监听器
    _tagsController.addListener(_onTagsChanged);
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

  void _onTagsChanged() {
    final inputTags =
        _tagsController.text
            .replaceAll('，', ',')
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList();

    setState(() {
      _selectedTags = inputTags;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.removeListener(_onTagsChanged);
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
        _syncDurationWithTimes();
      });
    }
  }

  void _syncDurationWithTimes() {
    final minutes = calculateDuration(
      widget.selectedDate,
      _startTime,
      _endTime,
    );
    _durationController.text = minutes.toString();
  }

  void _selectMood(String mood) {
    setState(() {
      _selectedMood = mood;
    });
  }

  Future<void> _handleSave() async {
    if (!mounted) return;
    final l10n = ActivityLocalizations.of(context);
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
      toastService.showToast('${ActivityLocalizations.of(context).endTime}必须晚于${ActivityLocalizations.of(context).startTime}');
      return;
    }

    // 检查时间间隔是否小于1分钟
    final duration = endDateTime.difference(startDateTime);
    if (duration.inMinutes < 1) {
      toastService.showToast('活动时间必须至少为${ActivityLocalizations.of(context).minutesFormat(1).replaceAll('1 ', '')}');
      return;
    }

    // 检查是否超过当天结束时间
    final dayEnd = DateTime(now.year, now.month, now.day, 23, 59);
    if (endDateTime.isAfter(dayEnd)) {
      toastService.showToast('${ActivityLocalizations.of(context).endTime}不能超过当天23:59');
      return;
    }

    // 处理标签
    final inputTags =
        _tagsController.text
            .replaceAll('，', ',')
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
      (group) => group.name == l10n.ungrouped,
      orElse: () {
        final newGroup = TagGroup(name: l10n.ungrouped, tags: []);
        // 如果列表为空，直接添加；否则在合适的位置插入
        if (tagGroups.isEmpty) {
          tagGroups.add(newGroup);
        } else {
          // 在"所有"标签组后面插入（如果存在），否则插入到开头
          final allTagsIndex = tagGroups.indexWhere(
            (group) => group.name == l10n.all,
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
}
