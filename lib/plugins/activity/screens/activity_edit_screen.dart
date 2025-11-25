import 'package:flutter/material.dart';
import '../l10n/activity_localizations.dart';
import '../services/activity_service.dart';
import '../widgets/activity_form.dart';
import '../models/activity_record.dart';

/// 活动编辑界面
/// 用于创建和编辑活动记录
class ActivityEditScreen extends StatefulWidget {
  final ActivityService activityService;
  final ActivityRecord? activity;
  final DateTime selectedDate;
  final Function(List<String>)? onTagsUpdated;

  const ActivityEditScreen({
    super.key,
    required this.activityService,
    this.activity,
    required this.selectedDate,
    this.onTagsUpdated,
  });

  @override
  State<ActivityEditScreen> createState() => _ActivityEditScreenState();
}

class _ActivityEditScreenState extends State<ActivityEditScreen> {
  List<String> recentMoods = [];
  List<String> recentTags = [];

  @override
  void initState() {
    super.initState();
    _loadRecentMoodsAndTags();
  }

  Future<void> _loadRecentMoodsAndTags() async {
    try {
      final loadedMoods = await widget.activityService.getRecentMoods();
      final loadedTags = await widget.activityService.getRecentTags();
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

  Future<void> _saveActivity(ActivityRecord activity) async {
    try {
      if (widget.activity != null) {
        // 编辑现有活动
        await widget.activityService.updateActivity(widget.activity!, activity);
      } else {
        // 创建新活动
        await widget.activityService.saveActivity(activity);
      }

      if (activity.tags.isNotEmpty && widget.onTagsUpdated != null) {
        widget.onTagsUpdated!(activity.tags);
        await _updateRecentTags(activity.tags);
      }

      if (activity.mood != null && activity.mood!.isNotEmpty) {
        await _updateRecentMood(activity.mood!);
      }

      if (mounted) {
        Navigator.of(context).pop();
        // 显示保存成功消息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.activity != null
                  ? ActivityLocalizations.of(context).editActivity
                  : ActivityLocalizations.of(context).addActivity
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateRecentTags(List<String> tags) async {
    try {
      await widget.activityService.saveRecentTags(tags);
    } catch (e) {
      debugPrint('更新最近标签失败: $e');
    }
  }

  Future<void> _updateRecentMood(String mood) async {
    try {
      await widget.activityService.saveRecentMoods([mood]);
    } catch (e) {
      debugPrint('更新最近心情失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.activity != null
              ? ActivityLocalizations.of(context).editActivity
              : ActivityLocalizations.of(context).addActivity,
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ActivityForm(
        activity: widget.activity,
        selectedDate: widget.selectedDate,
        recentMoods: recentMoods,
        recentTags: recentTags,
        onSave: _saveActivity,
      ),
    );
  }
}