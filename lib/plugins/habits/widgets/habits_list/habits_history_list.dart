import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/habits/controllers/completion_record_controller.dart';
import 'package:Memento/plugins/habits/models/completion_record.dart';
import 'package:Memento/plugins/habits/widgets/common_record_list.dart';
import 'package:Memento/core/services/toast_service.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text('habits_history'.tr),
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
        getDeleteMessage: () => 'habits_recordDeleted'.tr,
        itemKey: (record) => Key(record.id),
      ),
    );
  }

  Future<bool> _showDeleteDialog(
    BuildContext context,
    CompletionRecord record,
  ) async {

    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('habits_deleteRecord'.tr),
                content: Text('habits_deleteRecordMessage'.tr),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('habits_cancel'.tr),
                  ),
                  TextButton(
                    onPressed: () async {
                      await widget.controller.deleteCompletionRecord(record.id);
                      Navigator.pop(context, true);
                    },
                    child: Text('habits_delete'.tr),
                  ),
                ],
              ),
        ) ??
        false;
  }

  Future<void> _showClearAllDialog(BuildContext context) async {

    final shouldClear =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('habits_clearAllRecords'.tr),
                content: Text('habits_deleteRecordMessage'.tr),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('habits_cancel'.tr),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text('habits_clearAllRecords'.tr),
                  ),
                ],
              ),
        ) ??
        false;

    if (shouldClear && mounted) {
      await widget.controller.clearAllCompletionRecords(widget.habitId);
      Toast.success('habits_clearAllRecords'.tr);
      await _loadRecords();
    }
  }
}
