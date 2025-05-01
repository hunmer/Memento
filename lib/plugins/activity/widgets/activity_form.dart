import 'package:flutter/material.dart';
import 'activity_form/activity_form_widget.dart';
import '../models/activity_record.dart';

/// 活动表单组件
/// 用于创建和编辑活动记录
class ActivityForm extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ActivityFormWidget(
      activity: activity,
      onSave: onSave,
      selectedDate: selectedDate,
      initialStartTime: initialStartTime,
      initialEndTime: initialEndTime,
      lastActivityEndTime: lastActivityEndTime,
    );
  }
}