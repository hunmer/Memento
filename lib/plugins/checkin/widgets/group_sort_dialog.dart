import 'package:flutter/material.dart';
import '../services/group_sort_service.dart';

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
      title: const Text('分组排序方式'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...GroupSortType.values.map((type) => RadioListTile<GroupSortType>(
                title: Text(GroupSortService.getSortTypeName(type)),
                value: type,
                groupValue: _selectedSortType,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedSortType = value;
                    });
                  }
                },
              )),
          const Divider(),
          SwitchListTile(
            title: const Text('反向排序'),
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
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            widget.onSortChanged(_selectedSortType, _isReversed);
            Navigator.of(context).pop();
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}