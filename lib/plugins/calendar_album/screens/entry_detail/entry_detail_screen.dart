import 'package:Memento/plugins/calendar_album/models/calendar_entry.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:provider/provider.dart';
import 'package:Memento/plugins/calendar_album/controllers/calendar_controller.dart';
import 'package:Memento/plugins/calendar_album/controllers/tag_controller.dart';
import 'entry_detail_app_bar.dart';
import 'entry_detail_content.dart';
import 'entry_detail_editor_launcher.dart';

class EntryDetailScreen extends StatefulWidget {
  final CalendarEntry? entry;
  final DateTime? date;

  const EntryDetailScreen({super.key, this.entry, this.date})
    : assert(
        entry != null || date != null,
        'Either entry or date must be provided',
      );

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final calendarController = Provider.of<CalendarController>(context);
    final tagController = Provider.of<TagController>(context);

    if (widget.entry == null) {
      return _buildEmptyState(calendarController, tagController);
    }

    return Scaffold(
      appBar: EntryDetailAppBar(
        entry: widget.entry!,
        calendarController: calendarController,
        tagController: tagController,
      ),
      body: EntryDetailContent(entry: widget.entry!),
    );
  }

  Widget _buildEmptyState(
    CalendarController calendarController,
    TagController tagController,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.date!.year}-${widget.date!.month.toString().padLeft(2, '0')}-${widget.date!.day.toString().padLeft(2, '0')}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              NavigationHelper.push(context, EntryDetailEditorLauncher(
                        calendarController: calendarController,
                        tagController: tagController,
                        initialDate: widget.date!,
                        isEditing: false,),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.note_add, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'calendarAlbum_noEntriesForDate'.tr,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                NavigationHelper.push(context, EntryDetailEditorLauncher(
                          calendarController: calendarController,
                          tagController: tagController,
                          initialDate: widget.date!,
                          isEditing: false,),
                );
              },
              icon: const Icon(Icons.add),
              label: Text('calendarAlbum_createEntry'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
