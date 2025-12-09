import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/services/toast_service.dart';

class CommonRecordList<T> extends StatelessWidget {
  final List<T> records;
  final Future<bool> Function(BuildContext, T) confirmDismiss;
  final Future<void> Function(String) onDelete;
  final String Function(T) getDate;
  final String Function(T) getNotes;
  final String Function() getDeleteMessage;
  final Key Function(T) itemKey;

  const CommonRecordList({
    super.key,
    required this.records,
    required this.confirmDismiss,
    required this.onDelete,
    required this.getDate,
    required this.getNotes,
    required this.getDeleteMessage,
    required this.itemKey,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: records.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final record = records[index];
        return Dismissible(
          key: itemKey(record),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          confirmDismiss:
              (direction) async => await confirmDismiss(context, record),
          onDismissed: (direction) async {
            await onDelete(itemKey(record).toString());
            ToastService.instance.showToast(getDeleteMessage());
          },
          child: ListTile(
            title: Text(getDate(record).split('.').first),
            subtitle: Text(getNotes(record)),
            onTap: () => _showDetailDialog(context, record),
          ),
        );
      },
    );
  }

  void _showDetailDialog(BuildContext context, T record) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(getDate(record).split('.').first),
            content: Text(getNotes(record)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('app_close'.tr),
              ),
            ],
          ),
    );
  }
}
