import 'package:Memento/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

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
      title: Text(AppLocalizations.of(context)!.selectGroup),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            return ListTile(
              title: Text(group),
              onTap: () {
                onGroupSelected(group);
                Navigator.of(context).pop();
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
      ],
    );
  }
}
