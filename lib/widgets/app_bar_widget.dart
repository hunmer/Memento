import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
    final displayTitle = title ?? (titleKey != null ? titleKey!.tr : '');

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
