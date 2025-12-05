import 'dart:io';

import 'package:Memento/core/plugin_manager.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/habits/l10n/habits_localizations.dart';

class HabitsAppBar extends StatelessWidget {
  final HabitsLocalizations l10n;
  final Function() onAddPressed;
  final Function() onBackPressed;

  const HabitsAppBar({
    super.key,
    required this.l10n,
    required this.onAddPressed,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(l10n.habits),
      automaticallyImplyLeading: !(Platform.isAndroid || Platform.isIOS),
      leading:
          (Platform.isAndroid || Platform.isIOS)
              ? null
              : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => PluginManager.toHomeScreen(context),
              ),
      actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: onAddPressed),
      ],
    );
  }
}
