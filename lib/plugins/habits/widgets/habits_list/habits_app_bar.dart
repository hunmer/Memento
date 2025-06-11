import 'package:flutter/material.dart';
import 'package:Memento/plugins/habits/l10n/habits_localizations.dart';

class HabitsAppBar extends StatelessWidget {
  final HabitsLocalizations l10n;
  final bool isCardView;
  final Function() onViewChanged;
  final Function() onAddPressed;
  final Function() onBackPressed;

  const HabitsAppBar({
    super.key,
    required this.l10n,
    required this.isCardView,
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
        IconButton(
          icon: Icon(isCardView ? Icons.list : Icons.grid_view),
          onPressed: onViewChanged,
        ),
        IconButton(icon: const Icon(Icons.add), onPressed: onAddPressed),
      ],
    );
  }
}
