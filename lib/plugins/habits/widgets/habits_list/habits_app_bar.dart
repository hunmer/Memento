import 'package:universal_platform/universal_platform.dart';

import 'package:Memento/core/plugin_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HabitsAppBar extends StatelessWidget {
  final Function() onAddPressed;
  final Function() onBackPressed;

  const HabitsAppBar({
    super.key,
    required this.onAddPressed,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text('habits_habits'.tr),

      leading:
          (UniversalPlatform.isAndroid || UniversalPlatform.isIOS)
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
