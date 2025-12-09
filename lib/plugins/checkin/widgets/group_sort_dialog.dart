import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/plugins/checkin/services/group_sort_service.dart';

class GroupSortDialog extends StatefulWidget {
  final GroupSortType currentSortType;
  final bool isReversed;
  final Function(GroupSortType, bool) onSortChanged;

  const GroupSortDialog({
    super.key,
    required this.currentSortType,
    required this.isReversed,
    required this.onSortChanged,
  });

  @override
  State<GroupSortDialog> createState() => _GroupSortDialogState();
}

class _GroupSortDialogState extends State<GroupSortDialog> {
  late GroupSortType _selectedSortType;
  late bool _isReversed;

  @override
  void initState() {
    super.initState();
    _selectedSortType = widget.currentSortType;
    _isReversed = widget.isReversed;
  }

  @override
  Widget build(BuildContext context) {

    return AlertDialog(
      title: Text('checkin_groupSortTitle'.tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...GroupSortType.values.map(
            (type) => RadioListTile<GroupSortType>(
              title: Text(GroupSortService.getSortTypeName(type, context)),
              value: type,
            ),
          ),
          const Divider(),
          SwitchListTile(
            title: Text('checkin_reverseSort'.tr),
            value: _isReversed,
            onChanged: (value) {
              setState(() {
                _isReversed = value;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('checkin_cancel'.tr),
        ),
        TextButton(
          onPressed: () {
            widget.onSortChanged(_selectedSortType, _isReversed);
            Navigator.of(context).pop();
          },
          child: Text('checkin_confirm'.tr),
        ),
      ],
    );
  }
}
