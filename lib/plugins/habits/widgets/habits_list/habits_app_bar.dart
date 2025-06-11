import 'package:flutter/material.dart';
import 'package:Memento/plugins/habits/l10n/habits_localizations.dart';

class HabitsAppBar extends StatelessWidget {
  final HabitsLocalizations l10n;
  final List<String> groups;
  final String? selectedGroup;
  final bool isCardView;
  final Function(String?) onGroupChanged;
  final Function() onViewChanged;
  final Function() onAddPressed;
  final Function() onBackPressed;

  const HabitsAppBar({
    super.key,
    required this.l10n,
    required this.groups,
    required this.selectedGroup,
    required this.isCardView,
    required this.onGroupChanged,
    required this.onViewChanged,
    required this.onAddPressed,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(l10n.habits),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBackPressed,
      ),
      actions: [
        if (groups.isNotEmpty)
          DropdownButton<String>(
            value: selectedGroup,
            hint: Text(l10n.group),
            items: [
              const DropdownMenuItem(value: null, child: Text('All')),
              ...groups.map(
                (group) => DropdownMenuItem(value: group, child: Text(group)),
              ),
            ],
            onChanged: onGroupChanged,
          ),
        IconButton(
          icon: Icon(isCardView ? Icons.list : Icons.grid_view),
          onPressed: onViewChanged,
        ),
        IconButton(icon: const Icon(Icons.add), onPressed: onAddPressed),
      ],
    );
  }
}
