
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SimpleGroupSelector extends StatelessWidget {
  final List<String> groups;
  final String? selectedGroup;
  final ValueChanged<String?> onGroupSelected;

  const SimpleGroupSelector({
    super.key,
    required this.groups,
    this.selectedGroup,
    required this.onGroupSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('app_selectGroup'.tr),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: groups.map((group) => ListTile(
              title: Text(group),
              onTap: () {
                onGroupSelected(group);
                Navigator.of(context).pop();
              },
            )).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('app_cancel'.tr),
        ),
      ],
    );
  }
}
