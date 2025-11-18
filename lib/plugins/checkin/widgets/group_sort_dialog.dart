import 'package:flutter/material.dart';
import '../services/group_sort_service.dart';
import '../l10n/checkin_localizations.dart';

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
    final l10n = CheckinLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.groupSortTitle),
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
            title: Text(l10n.reverseSort),
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
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () {
            widget.onSortChanged(_selectedSortType, _isReversed);
            Navigator.of(context).pop();
          },
          child: Text(l10n.confirm),
        ),
      ],
    );
  }
}
