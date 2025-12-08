import 'package:flutter/material.dart';
import 'package:Memento/plugins/checkin/models/checkin_item.dart';

class CheckinCard extends StatelessWidget {
  final CheckinItem checkinItem;
  final VoidCallback onDelete;

  const CheckinCard({
    super.key,
    required this.checkinItem,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        leading: Icon(checkinItem.icon),
        title: Text(checkinItem.name),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
