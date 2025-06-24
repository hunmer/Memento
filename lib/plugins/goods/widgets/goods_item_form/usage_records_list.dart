import 'package:Memento/plugins/goods/l10n/goods_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/usage_record.dart';

class UsageRecordsList extends StatefulWidget {
  final List<UsageRecord> records;
  final Function(List<UsageRecord>) onRecordsChanged;

  const UsageRecordsList({
    super.key,
    required this.records,
    required this.onRecordsChanged,
  });

  @override
  _UsageRecordsListState createState() => _UsageRecordsListState();
}

class _UsageRecordsListState extends State<UsageRecordsList> {
  late List<UsageRecord> _records;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _records = List<UsageRecord>.from(widget.records);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              GoodsLocalizations.of(context)!.usageRecords,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: Text(GoodsLocalizations.of(context)!.addUsageRecord),
              onPressed: _addNewRecord,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_records.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                GoodsLocalizations.of(context)!.noUsageRecords,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _records.length,
            itemBuilder: (context, index) {
              final record = _records[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(_dateFormat.format(record.date)),
                  subtitle:
                      record.note != null && record.note!.isNotEmpty
                          ? Text(record.note!)
                          : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeRecord(index),
                  ),
                  onTap: () => _editRecord(index),
                ),
              );
            },
          ),
      ],
    );
  }

  void _addNewRecord() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (pickedDate != null) {
      final TextEditingController noteController = TextEditingController();

      // ignore: use_build_context_synchronously
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(GoodsLocalizations.of(context)!.addUsageRecordTitle),
            content: TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: GoodsLocalizations.of(context)!.optionalNote,
                hintText: GoodsLocalizations.of(context)!.enterUsageNote,
              ),
              maxLines: 2,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(GoodsLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(GoodsLocalizations.of(context)!.confirm),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        setState(() {
          _records.add(
            UsageRecord(
              date: pickedDate,
              note: noteController.text.isEmpty ? null : noteController.text,
            ),
          );
          _records.sort((a, b) => b.date.compareTo(a.date)); // 按日期降序排序
          widget.onRecordsChanged(_records);
        });
      }
    }
  }

  void _editRecord(int index) async {
    final record = _records[index];
    final TextEditingController noteController = TextEditingController(
      text: record.note,
    );

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: record.date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (pickedDate != null) {
      // ignore: use_build_context_synchronously
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(GoodsLocalizations.of(context)!.editUsageRecordTitle),
            content: TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: GoodsLocalizations.of(context)!.optionalNote,
                hintText: GoodsLocalizations.of(context)!.enterUsageNote,
              ),
              maxLines: 2,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(GoodsLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(GoodsLocalizations.of(context)!.confirm),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        setState(() {
          _records[index] = UsageRecord(
            date: pickedDate,
            note: noteController.text.isEmpty ? null : noteController.text,
          );
          _records.sort((a, b) => b.date.compareTo(a.date)); // 按日期降序排序
          widget.onRecordsChanged(_records);
        });
      }
    }
  }

  void _removeRecord(int index) {
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: const Text('确定要删除这条使用记录吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    ).then((confirmed) {
      if (confirmed == true) {
        setState(() {
          _records.removeAt(index);
          widget.onRecordsChanged(_records);
        });
      }
    });
  }
}
