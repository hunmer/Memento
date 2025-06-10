import 'package:flutter/material.dart';
import 'package:Memento/plugins/habits/controllers/completion_record_controller.dart';
import 'package:Memento/plugins/habits/l10n/habits_localizations.dart';
import 'package:Memento/plugins/habits/models/skill.dart';
import 'package:Memento/plugins/habits/utils/habits_utils.dart';

class CompletionRecordsTab extends StatelessWidget {
  final Skill skill;
  final CompletionRecordController recordController;

  const CompletionRecordsTab({
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
                  '${l10n.completions}: $count',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${l10n.totalDuration}: ${HabitsUtils.formatDuration(duration)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (skill.description != null) ...[
                  const SizedBox(height: 16),
                  Text(skill.description!),
                ],
                const SizedBox(height: 24),
                Text(
                  l10n.recentRecords,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                // TODO: 添加具体的完成记录列表
              ],
            ),
          ),
        );
      },
    );
  }
}
