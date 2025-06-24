import 'package:flutter/material.dart';
import 'package:Memento/plugins/habits/controllers/completion_record_controller.dart';
import 'package:Memento/plugins/habits/models/completion_record.dart';
import 'package:Memento/plugins/habits/l10n/habits_localizations.dart';
import 'package:Memento/plugins/habits/widgets/common_record_list.dart';

class HabitsHistoryList extends StatefulWidget {
  final String habitId;
  final CompletionRecordController controller;

  const HabitsHistoryList({
    super.key,
    required this.habitId,
    required this.controller,
  });

  @override
  State<HabitsHistoryList> createState() => _HabitsHistoryListState();
}

class _HabitsHistoryListState extends State<HabitsHistoryList> {
  List<CompletionRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final records = await widget.controller.getHabitCompletionRecords(
      widget.habitId,
    );
    if (mounted) {
      setState(() => _records = records);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = HabitsLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.history),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showClearAllDialog(context),
          ),
        ],
      ),
      body: CommonRecordList<CompletionRecord>(
        records: _records,
        confirmDismiss: (context, record) => _showDeleteDialog(context, record),
        onDelete: widget.controller.deleteCompletionRecord,
        getDate: (record) => record.date.toString(),
        getNotes: (record) => record.notes,
        getDeleteMessage: () => l10n.recordDeleted,
        itemKey: (record) => Key(record.id),
      ),
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

  Future<void> _showClearAllDialog(BuildContext context) async {
    HabitsLocalizations.of(context);
    final shouldClear =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Clear All Records'),
                content: const Text(
                  'Are you sure you want to clear all records?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Clear'),
                  ),
                ],
              ),
        ) ??
        false;

    if (shouldClear && mounted) {
      await widget.controller.clearAllCompletionRecords(widget.habitId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All records cleared')));
      await _loadRecords();
    }
  }
}
