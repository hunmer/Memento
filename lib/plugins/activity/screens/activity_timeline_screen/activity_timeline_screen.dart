import 'package:flutter/material.dart';
import '../../../../core/storage/storage_manager.dart';
import '../../services/activity_service.dart';
import '../../widgets/activity_timeline.dart';
import '../../l10n/activity_localizations.dart';
import 'components/activity_grid_view.dart';
import 'components/date_selector.dart';
import 'components/timeline_app_bar.dart';
import 'controllers/activity_controller.dart';
import 'controllers/tag_controller.dart';
import 'controllers/view_mode_controller.dart';

class ActivityTimelineScreen extends StatefulWidget {
  const ActivityTimelineScreen({super.key});

  @override
  State<ActivityTimelineScreen> createState() => _ActivityTimelineScreenState();
}

class _ActivityTimelineScreenState extends State<ActivityTimelineScreen> {
  late DateTime _selectedDate;
  late ActivityService _activityService;
  late ActivityController _activityController;
  late TagController _tagController;
  late ViewModeController _viewModeController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _initializeService().then((_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    });
  }

  Future<void> _initializeService() async {
    final storage = StorageManager();
    await storage.initialize();
    _activityService = ActivityService(storage, 'activity');
    
    _activityController = ActivityController(
      activityService: _activityService,
      onActivitiesChanged: () => setState(() {}),
    );
    
    _tagController = TagController(
      activityService: _activityService,
      onTagsChanged: () => setState(() {}),
    );
    
    _viewModeController = ViewModeController();
    _viewModeController.addListener(() {
      setState(() {});
    });

    await _tagController.initialize();
    await _activityController.loadActivities(_selectedDate);
  }

  void _onDateChanged(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _activityController.loadActivities(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      appBar: TimelineAppBar(
        tagController: _tagController,
        activityController: _activityController,
        viewModeController: _viewModeController,
      ),
      body: Column(
        children: [
          // 日期选择器
          DateSelector(
            selectedDate: _selectedDate,
            onDateChanged: _onDateChanged,
          ),
          // 根据视图模式显示不同的视图
          Expanded(
            child: _viewModeController.isGridMode
                ? ActivityGridView(
                    activities: _activityController.activities,
                    selectedDate: _selectedDate,
                    onActivityTap: (activity) => _activityController.editActivity(context, activity),
                    onUnrecordedTimeTap: (start, end) {
                      _activityController.addActivity(
                        context,
                        _selectedDate,
                        TimeOfDay(hour: start.hour, minute: start.minute),
                        TimeOfDay(hour: end.hour, minute: end.minute),
                        _tagController.updateRecentTags,
                      ).then((_) {
                        _viewModeController.clearSelectedMinutes();
                      });
                    },
                    onSelectionChanged: (start, end) {
                      if (start != null && end != null) {
                        final minutes = end.difference(start).inMinutes;
                        _viewModeController.updateSelectedMinutes(minutes);
                      } else {
                        _viewModeController.clearSelectedMinutes();
                      }
                    },
                  )
                : ActivityTimeline(
                    activities: _activityController.activities,
                    onDeleteActivity: _activityController.deleteActivity,
                    onActivityTap: (activity) => _activityController.editActivity(context, activity),
                    onUnrecordedTimeTap: (start, end) {
                      _activityController.addActivity(
                        context,
                        _selectedDate,
                        TimeOfDay(hour: start.hour, minute: start.minute),
                        TimeOfDay(hour: end.hour, minute: end.minute),
                        _tagController.updateRecentTags,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _activityController.addActivity(
          context,
          _selectedDate,
          null,
          null,
          _tagController.updateRecentTags,
        ),
        tooltip: ActivityLocalizations.of(context)?.addActivity ?? 'Add Activity',
        child: const Icon(Icons.add),
      ),
    );
  }
}