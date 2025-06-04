import 'package:flutter/material.dart';
import 'package:Memento/l10n/app_localizations.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final String? titleKey;

  const AppBarWidget({super.key, this.title, this.titleKey})
    : assert(
        title != null || titleKey != null,
        'Either title or titleKey must be provided',
      );

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final displayTitle =
        title ?? (titleKey != null ? localizations.getString(titleKey!) : '');

    return AppBar(
      title: Text(displayTitle),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

extension AppLocalizationsX on AppLocalizations {
  String getString(String key) {
    switch (key) {
      case 'appTitle':
        return appTitle;
      case 'pluginManager':
        return pluginManager;
      // Add more cases for other localized strings as needed
      default:
        return key; // Return the key itself if not found
    }
  }
}
