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

class _TagScreenState extends State<TagScreen> {
  String? _selectedTag;

  @override
  Widget build(BuildContext context) {
    final l10n = CalendarAlbumLocalizations.of(context);
    final tagController = Provider.of<TagController>(context);
    final calendarController = Provider.of<CalendarController>(context);
    final tags = tagController.tags;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('tagManagement')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddTagDialog(context),
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
                tags.isEmpty
                    ? Center(child: Text(l10n.get('noTags')))
                    : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: tags.length,
                      itemBuilder: (context, index) {
                        final tag = tags[index];
                        final isSelected = _selectedTag == tag.name;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilterChip(
                            label: Text(
                              tag.name,
                              style: TextStyle(
                                color: isSelected ? Colors.white : null,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedTag = selected ? tag.name : null;
                              });
                            },
                            backgroundColor: tag.color.withValues(
                              alpha: 51,
                            ), // 0.2 * 255 ≈ 51
                            selectedColor: tag.color.withValues(
                              alpha: 153,
                            ), // 0.6 * 255 ≈ 153
                            deleteIcon: const Icon(Icons.delete, size: 18),
                            onDeleted: () => _confirmDeleteTag(context, tag),
                          ),
                        );
                      },
                    ),
          ),

          const Divider(),

          // Entries with selected tag
          Expanded(
            child:
                _selectedTag == null
                    ? Center(child: Text(l10n.get('selectTag')))
                    : EntryList(
                      entries: calendarController.getEntriesByTag(
                        _selectedTag!,
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
                    ),
          ),
        ],
      ),
    );
  }

  void _showAddTagDialog(BuildContext context) {
    final tagController = Provider.of<TagController>(context, listen: false);
    final TextEditingController _tagNameController = TextEditingController();
    String? selectedGroup;

    showDialog(
      context: context,
      builder: (context) {
        final groups = tagController.tagGroups.map((g) => g.name).toList();
        return AlertDialog(
          title: const Text('添加标签'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _tagNameController,
                decoration: const InputDecoration(labelText: '标签名称'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedGroup,
                hint: const Text('选择标签组'),
                items:
                    groups.map((group) {
                      return DropdownMenuItem(value: group, child: Text(group));
                    }).toList(),
                onChanged: (value) => selectedGroup = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (_tagNameController.text.isNotEmpty) {
                  tagController.addTag(
                    Tag.create(name: _tagNameController.text),
                    groupName: selectedGroup,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  void _deleteTag(Tag tag) {
    final tagController = Provider.of<TagController>(context, listen: false);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('删除标签'),
            content: Text('确定要删除标签 "${tag.name}" 吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  tagController.deleteTag(tag.id);
                  Navigator.pop(context);
                },
                child: const Text('确定'),
              ),
            ],
          ),
    );
  }

  void _confirmDeleteTag(BuildContext context, Tag tag) {
    final l10n = CalendarAlbumLocalizations.of(context);
    final tagController = Provider.of<TagController>(context, listen: false);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.get('deleteTag')),
            content: Text('${l10n.get('delete')} "${tag.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.get('cancel')),
              ),
              TextButton(
                onPressed: () {
                  tagController.deleteTag(tag.id);
                  if (_selectedTag == tag.name) {
                    setState(() {
                      _selectedTag = null;
                    });
                  }
                  Navigator.of(context).pop();
                },
                child: Text(l10n.get('delete')),
              ),
            ],
          ),
    );
  }
}
