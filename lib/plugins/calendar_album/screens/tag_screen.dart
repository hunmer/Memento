import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/tag_controller.dart';
import '../controllers/calendar_controller.dart';
import '../l10n/calendar_album_localizations.dart';
import '../widgets/entry_list.dart';
import 'entry_editor_screen.dart';
import 'entry_detail_screen.dart' hide Center, SizedBox;

class TagScreen extends StatefulWidget {
  const TagScreen({super.key});

  @override
  State<TagScreen> createState() => _TagScreenState();
}

class _TagItem {
  final String tag;
  bool active;

  _TagItem(this.tag, {this.active = true});
}

class _TagScreenState extends State<TagScreen> {
  final List<_TagItem> _selectedTags = [];

  @override
  Widget build(BuildContext context) {
    final l10n = CalendarAlbumLocalizations.of(context);
    final tagController = Provider.of<TagController>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('tagManagement')),
        actions: [
          IconButton(
            icon: const Icon(Icons.label),
            onPressed: () async {
              final selectedTags = await tagController.showTagManagerDialog(
                context,
              );
              if (selectedTags != null) {
                setState(() {
                  _selectedTags.clear();
                  _selectedTags.addAll(
                    selectedTags.map((tag) => _TagItem(tag)),
                  );
                });
              }
            },
            tooltip: l10n.get('tagManagement'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tag list
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child:
                _selectedTags.isEmpty
                    ? Center(child: Text(l10n.get('noTags')))
                    : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedTags.length,
                      itemBuilder: (context, index) {
                        final tagItem = _selectedTags[index];
                        final color =
                            Colors.primaries[tagItem.tag.hashCode %
                                Colors.primaries.length];

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilterChip(
                            label: Text(
                              tagItem.tag,
                              style: TextStyle(
                                color: tagItem.active ? Colors.white : null,
                              ),
                            ),
                            selected: tagItem.active,
                            onSelected: (selected) {
                              setState(() {
                                tagItem.active = selected;
                              });
                            },
                            backgroundColor: color.withOpacity(0.2),
                            selectedColor: color.withOpacity(0.6),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () {
                              setState(() {
                                _selectedTags.removeAt(index);
                              });
                            },
                          ),
                        );
                      },
                    ),
          ),
          const Divider(),
          // Entries with selected tag
          Expanded(
            child: Consumer<CalendarController>(
              builder: (context, calendarController, child) {
                return _selectedTags.isEmpty
                    ? Center(child: Text(l10n.get('selectTag')))
                    : EntryList(
                      entries: calendarController.getEntriesByTags(
                        _selectedTags
                            .where((item) => item.active)
                            .map((item) => item.tag)
                            .toList(),
                      ),
                      onTap: (entry) {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder:
                                (context) => MultiProvider(
                                  providers: [
                                    ChangeNotifierProvider<
                                      CalendarController
                                    >.value(value: calendarController),
                                    ChangeNotifierProvider<TagController>.value(
                                      value: tagController,
                                    ),
                                  ],
                                  child: EntryDetailScreen(entry: entry),
                                ),
                          ),
                        );
                      },
                      onEdit: (entry) {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder:
                                (context) => MultiProvider(
                                  providers: [
                                    ChangeNotifierProvider<
                                      CalendarController
                                    >.value(value: calendarController),
                                    ChangeNotifierProvider<TagController>.value(
                                      value: tagController,
                                    ),
                                  ],
                                  child: EntryEditorScreen(
                                    entry: entry,
                                    isEditing: true,
                                  ),
                                ),
                          ),
                        );
                      },
                      onDelete: (entry) {
                        final l10n = CalendarAlbumLocalizations.of(context);
                        showDialog<void>(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: Text(l10n.get('deleteEntry')),
                                content: Text(
                                  '${l10n.get('delete')} "${entry.title}"?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(),
                                    child: Text(l10n.get('cancel')),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      calendarController.deleteEntry(entry);
                                      Navigator.of(context).pop();
                                      setState(() {}); // 强制刷新界面
                                    },
                                    child: Text(l10n.get('delete')),
                                  ),
                                ],
                              ),
                        );
                      },
                    );
              },
            ),
          ),
        ],
      ),
    );
  }
}
