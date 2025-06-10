import 'package:flutter/material.dart';
import 'package:Memento/plugins/habits/controllers/completion_record_controller.dart';
import 'package:Memento/plugins/habits/l10n/habits_localizations.dart';
import 'package:Memento/plugins/habits/models/skill.dart';
import 'package:Memento/plugins/habits/models/completion_record.dart';
import 'package:Memento/plugins/habits/utils/habits_utils.dart';

class SkillRecordHistoryList extends StatefulWidget {
  final String habitId;
  final CompletionRecordController controller;

  const SkillRecordHistoryList({
    super.key,
    required this.habitId,
    required this.controller,
  });

  @override
  State<SkillRecordHistoryList> createState() => _SkillRecordHistoryListState();
}

class _SkillRecordHistoryListState extends State<SkillRecordHistoryList> {
  List<CompletionRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final records = await widget.controller.getSkillCompletionRecords(
      widget.habitId,
    );
    if (mounted) {
      setState(() => _records = records);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = HabitsLocalizations.of(context);

    return ListView.separated(
      itemCount: _records.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final record = _records[index];
        return Dismissible(
          key: Key(record.id),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await _showDeleteDialog(context, record);
          },
          onDismissed: (direction) async {
            await widget.controller.deleteCompletionRecord(record.id);
            if (mounted) {
              setState(() {
                _records.removeAt(index);
              });
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.recordDeleted)));
            }
          },
          child: ListTile(
            title: Text(record.date.toString()),
            subtitle: Text(record.notes),
          ),
        );
      },
    );
  }

  Future<bool> _showDeleteDialog(
    BuildContext context,
    CompletionRecord record,
  ) async {
    final l10n = HabitsLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(l10n.deleteRecord),
                content: Text(l10n.deleteRecordMessage),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l10n.cancel),
                  ),
                  TextButton(
                    onPressed: () async {
                      await widget.controller.deleteCompletionRecord(record.id);
                      Navigator.pop(context, true);
                    },
                    child: Text(l10n.delete),
                  ),
                ],
              ),
        ) ??
        false;
  }
}

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
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  Flexible(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: 200,
                        maxHeight: MediaQuery.of(context).size.height * 0.6,
                      ),
                      child: SkillRecordHistoryList(
                        habitId: skill.id,
                        controller: recordController,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
