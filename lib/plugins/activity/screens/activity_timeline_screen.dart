import 'package:flutter/material.dart';
import '../models/activity_record.dart';
import '../services/activity_service.dart';
import '../widgets/activity_timeline.dart';
import '../widgets/activity_form.dart';

class ActivityTimelineScreen extends StatefulWidget {
  const ActivityTimelineScreen({super.key});

  @override
  State<ActivityTimelineScreen> createState() => _ActivityTimelineScreenState();
}

class _ActivityTimelineScreenState extends State<ActivityTimelineScreen> {
  DateTime _selectedDate = DateTime.now();
  late ActivityService _activityService;
  List<ActivityRecord> _activities = [];

  @override
  void initState() {
    super.initState();
    // 初始化服务（实际使用时需要从插件获取storage）
    // _activityService = ActivityService(storage, 'activity');
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    final activities = await _activityService.getActivitiesForDate(_selectedDate);
    setState(() {
      _activities = activities;
    });
  }

  void _onDateChanged(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _loadActivities();
  }

  void _showAddActivityDialog() {
    showDialog(
      context: context,
      builder: (context) => ActivityForm(
        onSave: (ActivityRecord activity) async {
          await _activityService.saveActivity(activity);
          _loadActivities();
        },
        selectedDate: _selectedDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                _onDateChanged(
                  _selectedDate.subtract(const Duration(days: 1)),
                );
              },
            ),
            Text(
              '${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day}',
              style: const TextStyle(fontSize: 20),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                _onDateChanged(
                  _selectedDate.add(const Duration(days: 1)),
                );
              },
            ),
          ],
        ),
      ),
      body: ActivityTimeline(
        activities: _activities,
        onActivityTap: (activity) {
          showDialog(
            context: context,
            builder: (context) => ActivityForm(
              activity: activity,
              onSave: (ActivityRecord updatedActivity) async {
                await _activityService.updateActivity(activity, updatedActivity);
                _loadActivities();
              },
              selectedDate: _selectedDate,
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddActivityDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}