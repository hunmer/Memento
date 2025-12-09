import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/habits/controllers/completion_record_controller.dart';
import 'package:Memento/plugins/habits/l10n/habits_localizations.dart';
import 'package:Memento/plugins/habits/models/skill.dart';
import 'package:Memento/plugins/habits/utils/habits_utils.dart';

class StatisticsTab extends StatelessWidget {
  final Skill skill;
  final CompletionRecordController recordController;

  const StatisticsTab({
    super.key,
    required this.skill,
    required this.recordController,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = HabitsLocalizations.of(context);

    return FutureBuilder(
      future: Future.wait([
        recordController.getCompletionCount(skill.id),
        recordController.getTotalDuration(skill.id),
      ]),
      builder: (context, snapshot) {
        final count = snapshot.data?[0] ?? 0;
        final duration = snapshot.data?[1] ?? 0;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.statistics,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.check_circle),
                          title: Text(l10n.totalCompletions),
                          trailing: Text(
                            'nfc_completions'.tr +
                                ': $count',
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.timer),
                          title: Text(l10n.totalDuration),
                          trailing: Text(HabitsUtils.formatDuration(duration)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // TODO: 添加统计图表
                Center(
                  child: Text(
                    l10n.statisticsChartsPlaceholder,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
