import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/plugins/activity/activity_plugin.dart';
import 'package:Memento/plugins/activity/widgets/activity_form.dart';
import 'package:Memento/plugins/activity/models/activity_record.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/widgets/tags_dialog/models/models.dart';

/// 活动编辑界面
/// 用于创建和编辑活动记录
/// 可作为独立页面或 bottom sheet 内容使用
class ActivityEditScreen extends StatefulWidget {
  final ActivityRecord? activity;
  final DateTime? selectedDate;
  final bool showAsBottomSheet;
  final DateTime? startTime; // 传入预填充的开始时间
  final DateTime? endTime; // 传入预填充的结束时间

  const ActivityEditScreen({
    super.key,
    this.activity,
    this.selectedDate,
    this.showAsBottomSheet = false,
    this.startTime,
    this.endTime,
  });

  @override
  State<ActivityEditScreen> createState() => _ActivityEditScreenState();
}

class _ActivityEditScreenState extends State<ActivityEditScreen> {
  List<String> recentMoods = [];
  List<String> recentTags = [];
  List<TagGroupWithTags> tagGroups = [];
  DateTime? _defaultStartTime;
  DateTime? _defaultEndTime;

  @override
  void initState() {
    super.initState();
    _loadRecentMoodsAndTags();
    _loadTagGroups();
    _initDefaultTimes();
  }

  /// 初始化默认时间
  Future<void> _initDefaultTimes() async {
    // 如果有传入时间，直接使用传入的时间
    if (widget.startTime != null && widget.endTime != null) {
      if (mounted) {
        setState(() {
          _defaultStartTime = widget.startTime;
          _defaultEndTime = widget.endTime;
        });
      }
      return;
    }

    // 如果是编辑模式或已提供 selectedDate，则不需要设置默认时间
    if (widget.activity != null || widget.selectedDate != null) {
      return;
    }

    try {
      // 获取上一个活动
      final lastActivity =
          await ActivityPlugin.instance.activityService.getLastActivity();

      DateTime startTime;
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      if (lastActivity != null) {
        // 使用上一个活动的结束时间作为开始时间
        startTime = lastActivity.endTime;

        // 如果小于今日00:00，则使用今日00:00
        if (startTime.isBefore(todayStart)) {
          startTime = todayStart;
        }
      } else {
        // 没有上一个活动，使用今日00:00
        startTime = todayStart;
      }

      // 结束时间就是现在
      final endTime = now;

      if (mounted) {
        setState(() {
          _defaultStartTime = startTime;
          _defaultEndTime = endTime;
        });
      }
    } catch (e) {
      debugPrint('初始化默认时间失败: $e');
    }
  }

  Future<void> _loadRecentMoodsAndTags() async {
    try {
      final loadedMoods =
          await ActivityPlugin.instance.activityService.getRecentMoods();
      final loadedTags =
          await ActivityPlugin.instance.activityService.getRecentTags();
      if (mounted) {
        setState(() {
          recentMoods = loadedMoods;
          recentTags = loadedTags;
        });
      }
    } catch (e) {
      debugPrint('加载最近心情和标签失败: $e');
    }
  }

  Future<void> _loadTagGroups() async {
    try {
      final loadedGroups =
          await ActivityPlugin.instance.activityService.getTagGroups();
      if (mounted) {
        setState(() {
          tagGroups = loadedGroups;
        });
      }
    } catch (e) {
      debugPrint('加载标签组失败: $e');
    }
  }

  Future<void> _saveActivity(ActivityRecord activity) async {
    try {
      if (widget.activity != null) {
        // 编辑现有活动
        await ActivityPlugin.instance.activityService.updateActivity(
          widget.activity!,
          activity,
        );
      } else {
        // 创建新活动
        await ActivityPlugin.instance.activityService.saveActivity(activity);
      }

      // 自动保存最近标签
      if (activity.tags.isNotEmpty) {
        await _updateRecentTags(activity.tags);
      }

      // 自动保存最近心情
      if (activity.mood != null && activity.mood!.isNotEmpty) {
        await _updateRecentMood(activity.mood!);
      }

      if (mounted) {
        // 先显示保存成功消息
        toastService.showToast(
          widget.activity != null
              ? 'activity_editActivity'.tr
              : 'activity_addActivity'.tr,
        );
        // 再关闭界面
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        toastService.showToast('保存失败: $e');
      }
    }
  }

  Future<void> _updateRecentTags(List<String> tags) async {
    try {
      if (tags.isEmpty) return;

      // 获取当前的最近标签
      final recentTags =
          await ActivityPlugin.instance.activityService.getRecentTags();

      // 使用 set 去重并移除新标签中已存在的标签
      final inputTagSet = tags.toSet();
      recentTags.removeWhere(inputTagSet.contains);

      // 将新标签按选择顺序添加到开头
      recentTags.insertAll(0, tags);

      // 限制最多30个
      if (recentTags.length > 30) {
        recentTags.removeRange(30, recentTags.length);
      }

      await ActivityPlugin.instance.activityService.saveRecentTags(recentTags);
    } catch (e) {
      debugPrint('更新最近标签失败: $e');
    }
  }

  Future<void> _updateRecentMood(String mood) async {
    try {
      await ActivityPlugin.instance.activityService.saveRecentMoods([mood]);
    } catch (e) {
      debugPrint('更新最近心情失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 如果没有提供 selectedDate，使用今天的日期
    final selectedDate = widget.selectedDate ?? DateTime.now();
    final title = widget.activity != null
        ? 'activity_editActivity'.tr
        : 'activity_addActivity'.tr;

    final formContent = ActivityForm(
      activity: widget.activity,
      selectedDate: selectedDate,
      initialStartTime: _defaultStartTime,
      initialEndTime: _defaultEndTime,
      recentMoods: recentMoods,
      recentTags: recentTags,
      tagGroups: tagGroups,
      onSave: _saveActivity,
    );

    // bottom sheet 模式：只返回带标题栏的内容
    if (widget.showAsBottomSheet) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题栏
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 表单内容
          Expanded(child: formContent),
        ],
      );
    }

    // 完整页面模式：使用 Scaffold
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: formContent,
    );
  }
}