import 'package:flutter/material.dart';
import '../../../models/node.dart';
import '../../../l10n/nodes_localizations.dart';

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
    final l10n = NodesLocalizations.of(context);

    return DropdownButtonFormField<NodeStatus>(
      value: value,
      decoration: InputDecoration(
        labelText: l10n.status,
        border: const OutlineInputBorder(),
      ),
      items:
          NodeStatus.values.map((status) {
            String label;
            switch (status) {
              case NodeStatus.none:
                label = l10n.none;
                break;
              case NodeStatus.todo:
                label = l10n.todo;
                break;
              case NodeStatus.doing:
                label = l10n.doing;
                break;
              case NodeStatus.done:
                label = l10n.done;
                break;
            }
            return DropdownMenuItem(value: status, child: Text(label));
          }).toList(),
      onChanged: onChanged,
    );
  }
}
