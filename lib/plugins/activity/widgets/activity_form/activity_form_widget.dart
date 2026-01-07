import 'package:flutter/material.dart';
import 'package:Memento/plugins/activity/models/activity_record.dart';
import 'package:Memento/widgets/tags_dialog/models/models.dart';
import 'activity_form_state.dart';

class ActivityFormWidget extends StatefulWidget {
  final ActivityRecord? activity;
  final Function(ActivityRecord) onSave;
  final DateTime selectedDate;
  final DateTime? initialStartTime;
  final DateTime? initialEndTime;
  final DateTime? lastActivityEndTime;
  final List<String>? recentMoods;
  final List<String>? recentTags;
  final List<TagGroupWithTags>? tagGroups;

  const ActivityFormWidget({
    super.key,
    this.activity,
    required this.onSave,
    required this.selectedDate,
    this.initialStartTime,
    this.initialEndTime,
    this.lastActivityEndTime,
    this.recentMoods,
    this.recentTags,
    this.tagGroups,
  });

  @override
  State<ActivityFormWidget> createState() => ActivityFormState();
}
