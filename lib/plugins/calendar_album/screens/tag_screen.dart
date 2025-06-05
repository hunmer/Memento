import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/tag_controller.dart';
import '../controllers/calendar_controller.dart';
import '../l10n/calendar_album_localizations.dart';
import '../widgets/entry_list.dart';

class TagScreen extends StatefulWidget {
  const TagScreen({Key? key}) : super(key: key);

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
            child: tags.isEmpty
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
                          label: Text(tag.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedTag = selected ? tag.name : null;
                            });
                          },
                          backgroundColor: tag.color.withOpacity(0.2),
                          selectedColor: tag.color.withOpacity(0.6),
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
            child: _selectedTag == null
                ? Center(child: Text(l10n.get('selectTag')))
                : EntryList(
                    entries: calendarController.getEntriesByTag(_selectedTag!),
                    onTap: (entry) {
                      // View entry
                    },
                    onEdit: (entry) {
                      // Edit entry
                    },
                    onDelete: (entry) {
                      // Delete entry
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddTagDialog(BuildContext context) {
    final l10n = CalendarAlbumLocalizations.of(context);
    final tagController = Provider.of<TagController>(context, listen: false);
    final nameController = TextEditingController();
    Color selectedColor = Colors.blue;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.get('createTag')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: l10n.get('tagName'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.get('tagColor')),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      Colors.red,
                      Colors.pink,
                      Colors.purple,
                      Colors.deepPurple,
                      Colors.indigo,
                      Colors.blue,
                      Colors.lightBlue,
                      Colors.cyan,
                      Colors.teal,
                      Colors.green,
                      Colors.lightGreen,
                      Colors.lime,
                      Colors.yellow,
                      Colors.amber,
                      Colors.orange,
                      Colors.deepOrange,
                      Colors.brown,
                      Colors.grey,
                      Colors.blueGrey,
                    ].map((color) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedColor = color;
                          });
                        },
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: selectedColor == color
                                ? Border.all(color: Colors.black, width: 2)
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.get('cancel')),
                ),
                TextButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      tagController.addTag(
                        Tag.create(
                          name: nameController.text,
                          color: selectedColor,
                        ),
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(l10n.get('save')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteTag(BuildContext context, Tag tag) {
    final l10n = CalendarAlbumLocalizations.of(context);
    final tagController = Provider.of<TagController>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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