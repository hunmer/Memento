import 'package:flutter/material.dart';
import '../../controllers/store_controller.dart';

class PointsHistory extends StatelessWidget {
  final StoreController controller;

  const PointsHistory({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (controller.pointsLogs.isEmpty) {
      return const Center(child: Text('暂无记录'));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: controller.pointsLogs.length,
      itemBuilder: (context, index) {
        final log = controller.pointsLogs[index];
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
