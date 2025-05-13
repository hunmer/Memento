import 'package:flutter/material.dart';
import '../../controllers/store_controller.dart';

class PointsHistory extends StatefulWidget {
  final StoreController controller;

  const PointsHistory({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  _PointsHistoryState createState() => _PointsHistoryState();
}

class _PointsHistoryState extends State<PointsHistory> {
  Future<void> _showClearConfirmation() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认清空'),
          content: const Text('确定要清空所有积分记录吗？'),
          actions: [
            TextButton(
              child: const Text('取消'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('确定'),
              onPressed: () {
                widget.controller.clearPointsLogs();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller.pointsLogs.isEmpty) {
      return const Center(child: Text('暂无记录'));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: widget.controller.pointsLogs.length,
      itemBuilder: (context, index) {
        final log = widget.controller.pointsLogs[index];
        return Card(
          child: ListTile(
            leading: Icon(
              log.type == '获得' ? Icons.add : Icons.remove,
              color: log.type == '获得' ? Colors.green : Colors.red,
            ),
            title: Text('${log.value}积分 (${log.type})'),
            subtitle: Text(log.reason),
            trailing: Text(
              '${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}',
            ),
          ),
        );
      },
    );
  }
}
