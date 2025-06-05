import 'package:Memento/plugins/calendar_album/screens/entry_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/calendar_controller.dart';
import '../../controllers/tag_controller.dart';
import '../../models/calendar_entry.dart';
import 'entry_detail_editor_launcher.dart';
import '../../l10n/calendar_album_localizations.dart';

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
            final updatedEntry = await Navigator.push<CalendarEntry?>(
              context,
              MaterialPageRoute(
                builder:
                    (context) => EntryDetailEditorLauncher(
                      calendarController: calendarController,
                      tagController: tagController,
                      entry: entry,
                      isEditing: true,
                    ),
              ),
            );

            if (updatedEntry != null && context.mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => EntryDetailScreen(entry: updatedEntry),
                ),
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
                    title: Text(
                      CalendarAlbumLocalizations.of(context).get('delete'),
                    ),
                    content: Text(
                      '${CalendarAlbumLocalizations.of(context).get('delete')} "${entry.title}"?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          CalendarAlbumLocalizations.of(context).get('cancel'),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          calendarController.deleteEntry(entry);
                          Navigator.of(context).pop(); // 关闭对话框
                          Navigator.of(context).pop(); // 返回上一页
                        },
                        child: Text(
                          CalendarAlbumLocalizations.of(context).get('delete'),
                        ),
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
