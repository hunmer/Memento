import 'package:Memento/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:provider/provider.dart';
import '../controllers/tag_controller.dart';
import '../controllers/calendar_controller.dart';
import '../l10n/calendar_album_localizations.dart';
import '../widgets/entry_list.dart';
import 'entry_editor_screen.dart';
import 'entry_detail_screen.dart';

class TagScreen extends StatefulWidget {
  const TagScreen({super.key});

  @override
  State<TagScreen> createState() => _TagScreenState();
}

class _TagItem {
  final String tag;
  bool active;

  // ignore: unused_element_parameter
  _TagItem(this.tag, {this.active = false});
}

class _TagScreenState extends State<TagScreen> {
  final List<_TagItem> _selectedTags = [];

  @override
  Widget build(BuildContext context) {
    final l10n = CalendarAlbumLocalizations.of(context);
    final tagController = Provider.of<TagController>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tagManagement),
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
            tooltip: l10n.tagManagement,
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
                    ? Center(child: Text(l10n.noTags))
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
                            backgroundColor: color.withAlpha(
                              (0.2 * 255).toInt(),
                            ),
                            selectedColor: color.withAlpha((0.6 * 255).toInt()),
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
                    ? Center(child: Text(l10n.selectTag))
                    : EntryList(
                      entries: calendarController.getEntriesByTags(
                        _selectedTags
                            .where((item) => item.active)
                            .map((item) => item.tag)
                            .toList(),
                      ),
                      onTap: (entry) {
                        NavigationHelper.push<void>(
                          context,
                          MultiProvider(
                            providers: [
                              ChangeNotifierProvider<CalendarController>.value(
                                value: calendarController,
                              ),
                              ChangeNotifierProvider<TagController>.value(
                                value: tagController,
                              ),
                            ],
                            child: EntryDetailScreen(entry: entry),
                          ),
                        );
                      },
                      onEdit: (entry) {
                        NavigationHelper.push<void>(
                          context,
                          MultiProvider(
                            providers: [
                              ChangeNotifierProvider<CalendarController>.value(
                                value: calendarController,
                              ),
                              ChangeNotifierProvider<TagController>.value(
                                value: tagController,
                              ),
                            ],
                            child: EntryEditorScreen(
                              entry: entry,
                              isEditing: true,
                            ),
                          ),
                        );
                      },
                      onDelete: (entry) {
                        final l10n = CalendarAlbumLocalizations.of(context);
                        final appL10n = AppLocalizations.of(context);
                        showDialog<void>(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: Text(l10n.deleteEntry),
                                content: Text(
                                  '${appL10n!.delete} "${entry.title}"?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(),
                                    child: Text(appL10n.cancel),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      calendarController.deleteEntry(entry);
                                      Navigator.of(context).pop();
                                      setState(() {}); // 强制刷新界面
                                    },
                                    child: Text(appL10n.delete),
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
