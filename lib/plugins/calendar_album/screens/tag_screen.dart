import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:provider/provider.dart';
import 'package:Memento/plugins/calendar_album/controllers/tag_controller.dart';
import 'package:Memento/plugins/calendar_album/controllers/calendar_controller.dart';
import 'package:Memento/plugins/calendar_album/widgets/entry_list.dart';
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

    final tagController = Provider.of<TagController>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('calendar_album_tag_management'.tr),
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
            tooltip: 'calendar_album_tag_management'.tr,
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
                    ? Center(child: Text('calendar_album_no_tags'.tr))
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
                    ? Center(child: Text('calendar_album_select_tag'.tr))
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

                        showDialog<void>(
                          context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: Text('calendar_album_delete_entry'.tr),
                                      content: Text(
                                        '${'app_delete'.tr} "${entry.title}"?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(context).pop(),
                                          child: Text('app_cancel'.tr),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            calendarController.deleteEntry(entry);
                                            Navigator.of(context).pop();
                                            setState(() {}); // 强制刷新界面
                                          },
                                          child: Text('app_delete'.tr),
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
