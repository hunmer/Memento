import 'package:get/get.dart';
import 'package:flutter/material.dart' hide ListTile, Row, Center, SizedBox;
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:flutter/material.dart'
    as flutter
    show ListTile, Row, Center, SizedBox;
import 'package:Memento/plugins/tracker/models/goal.dart';
import 'package:Memento/plugins/tracker/models/record.dart';
import 'package:Memento/plugins/tracker/controllers/tracker_controller.dart';
import 'package:Memento/plugins/tracker/widgets/goal_edit_page.dart';
import 'package:Memento/plugins/tracker/widgets/record_dialog.dart';
import 'package:provider/provider.dart';
import 'package:Memento/core/services/toast_service.dart';

class GoalDetailScreen extends StatelessWidget {
  final Goal goal;

  const GoalDetailScreen({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    return Consumer<TrackerController>(
      builder: (context, controller, child) {
        final currentValue =
            controller.goals.firstWhere((g) => g.id == goal.id).currentValue;
        final isCompleted = currentValue >= goal.targetValue;

        return Scaffold(
          appBar: AppBar(
            title: Text(goal.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text('tracker_confirmClear'.tr),
                          content: Text('tracker_confirmClearMessage'.tr),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('app_cancel'.tr),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text('app_ok'.tr),
                            ),
                          ],
                        ),
                  );
                  if (confirmed == true) {
                    await controller.clearRecordsForGoal(goal.id);
                    if (context.mounted) {
                      Toast.success(
                        'tracker_recordsCleared'.tr,
                      );
                    }
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  NavigationHelper.push(context, GoalEditPage(controller: controller, goal: goal),
                  );
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${'tracker_goalsTitle'.tr}: ${goal.name}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const flutter.SizedBox(height: 16),
                LinearProgressIndicator(
                  value: controller.calculateProgress(goal),
                  backgroundColor: Colors.grey[200],
                  color:
                      isCompleted
                          ? Colors.green
                          : goal.progressColor != null
                          ? Color(goal.progressColor!)
                          : Theme.of(context).primaryColor,
                ),
                const flutter.SizedBox(height: 16),
                Text(
                  'tracker_currentProgress'.tr
                      .replaceFirst('{currentValue}', currentValue.toString())
                      .replaceFirst(
                        '{targetValue}',
                        goal.targetValue.toString(),
                      ),
                ),
                const flutter.SizedBox(height: 16),
                if (goal.reminderTime != null)
                  Text(
                    'tracker_reminderTime'.tr.replaceFirst(
                      '{reminderTime}',
                      goal.reminderTime.toString(),
                    ),
                  ),
                const flutter.SizedBox(height: 16),
                Text(
                  'tracker_recordHistory'.tr,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const flutter.SizedBox(height: 8),
                Expanded(
                  child: FutureBuilder<List<Record>>(
                    future: controller.getRecordsForGoal(goal.id),
                    builder: (context, initialSnapshot) {
                      if (initialSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const flutter.Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      return StreamBuilder<List<Record>>(
                        stream: controller.watchRecordsForGoal(goal.id),
                        initialData: initialSnapshot.data,
                        builder: (context, snapshot) {
                          final records = snapshot.data ?? [];
                          if (records.isEmpty) {
                            return flutter.Center(
                              child: Text(
                                'tracker_noRecords'.tr,
                              ),
                            );
                          }
                          return ListView.builder(
                            itemCount: records.length,
                            itemBuilder: (context, index) {
                              final record = records[index];
                              return flutter.ListTile(
                                title: Text('tracker_recordValueDisplay'.tr(record.value)),
                                subtitle: Text(
                                  record.recordedAt
                                      .toLocal()
                                      .toString()
                                      .split('.')
                                      .first,
                                ),
                                trailing: flutter.Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(record.note ?? ''),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20),
                                      onPressed: () async {
                                        final confirmed = await showDialog<
                                          bool
                                        >(
                                          context: context,
                                          builder:
                                              (context) => AlertDialog(
                                                title: Text('tracker_confirmDelete'.tr),
                                                content: Text('tracker_confirmDeleteRecordMessage'.tr),
                                                actions: [
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          context,
                                                          false,
                                                        ),
                                                    child: Text('app_cancel'.tr),
                                                  ),
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          context,
                                                          true,
                                                        ),
                                                    child: Text('app_ok'.tr),
                                                  ),
                                                ],
                                              ),
                                        );
                                        if (confirmed == true) {
                                          await controller.deleteRecord(
                                            record.id,
                                          );
                                          if (context.mounted) {
                                            Toast.success('tracker_recordDeleted'.tr);
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) =>
                        RecordDialog(goal: goal, controller: controller),
              );
            },
          ),
        );
      },
    );
  }
}
