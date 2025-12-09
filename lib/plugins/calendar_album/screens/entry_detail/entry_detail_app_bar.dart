import 'package:Memento/plugins/calendar_album/screens/entry_detail_screen.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/plugins/calendar_album/controllers/calendar_controller.dart';
import 'package:Memento/plugins/calendar_album/controllers/tag_controller.dart';
import 'package:Memento/plugins/calendar_album/models/calendar_entry.dart';
import 'entry_detail_editor_launcher.dart';

class EntryDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final CalendarEntry entry;
  final CalendarController calendarController;
  final TagController tagController;

  const EntryDetailAppBar({
    super.key,
    required this.entry,
    required this.calendarController,
    required this.tagController,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(entry.title),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () async {
            final updatedEntry = await NavigationHelper.push<CalendarEntry?>(
              context,
              EntryDetailEditorLauncher(
                calendarController: calendarController,
                tagController: tagController,
                entry: entry,
                isEditing: true,
              ),
            );

            if (updatedEntry != null && context.mounted) {
              NavigationHelper.pushReplacement(context, EntryDetailScreen(entry: updatedEntry),
              );
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: Text('app_delete'.tr),
                    content: Text(
                      '${'app_delete'.tr} "${entry.title}"?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('app_cancel'.tr),
                      ),
                      TextButton(
                        onPressed: () {
                          calendarController.deleteEntry(entry);
                          Navigator.of(context).pop(); // 关闭对话框
                          Navigator.of(context).pop(); // 返回上一页
                        },
                        child: Text('app_delete'.tr),
                      ),
                    ],
                  ),
            );
          },
        ),
      ],
    );
  }
}
