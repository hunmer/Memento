import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/nodes/models/node.dart';

class StatusDropdown extends StatelessWidget {
  final NodeStatus value;
  final ValueChanged<NodeStatus?> onChanged;

  const StatusDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {

    return DropdownButtonFormField<NodeStatus>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: 'nodes_status'.tr,
        border: const OutlineInputBorder(),
      ),
      items:
          NodeStatus.values.map((status) {
            String label;
            switch (status) {
              case NodeStatus.none:
                label = 'nodes_none'.tr;
                break;
              case NodeStatus.todo:
                label = 'nodes_todo'.tr;
                break;
              case NodeStatus.doing:
                label = 'nodes_doing'.tr;
                break;
              case NodeStatus.done:
                label = 'nodes_done'.tr;
                break;
            }
            return DropdownMenuItem(value: status, child: Text(label));
          }).toList(),
      onChanged: onChanged,
    );
  }
}
