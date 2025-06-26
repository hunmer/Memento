import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/plugins/database/l10n/database_localizations.dart';
import 'package:flutter/material.dart';
import '../controllers/database_controller.dart';
import '../models/record.dart';

class RecordDetailWidget extends StatefulWidget {
  final Record record;
  final DatabaseController controller;

  const RecordDetailWidget({
    super.key,
    required this.record,
    required this.controller,
  });

  @override
  State<RecordDetailWidget> createState() => _RecordDetailWidgetState();
}

class _RecordDetailWidgetState extends State<RecordDetailWidget> {
  late Record _currentRecord;

  @override
  void initState() {
    super.initState();
    _currentRecord = widget.record;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentRecord.fields['title']?.toString() ?? 'Record'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEdit(),
          ),
          IconButton(icon: const Icon(Icons.delete), onPressed: _deleteRecord),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_currentRecord.fields['image'] != null)
            Image.network(_currentRecord.fields['image']),
          const SizedBox(height: 16),
          ..._currentRecord.fields.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    entry.value?.toString() ?? 'N/A',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToEdit() async {}

  Future<void> _deleteRecord() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(DatabaseLocalizations.of(context).deleteRecordTitle),
            content: Text(
              DatabaseLocalizations.of(context).deleteRecordMessage,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(AppLocalizations.of(context)!.delete),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await widget.controller.deleteRecord(_currentRecord.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }
}
