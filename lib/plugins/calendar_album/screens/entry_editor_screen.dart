import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/calendar_controller.dart';
import '../controllers/tag_controller.dart';
import '../models/calendar_entry.dart';
import '../l10n/calendar_album_localizations.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EntryEditorScreen extends StatefulWidget {
  final CalendarEntry? entry;
  final DateTime? initialDate;
  final bool isEditing;

  const EntryEditorScreen({
    Key? key,
    this.entry,
    this.initialDate,
    required this.isEditing,
  }) : super(key: key);

  @override
  State<EntryEditorScreen> createState() => _EntryEditorScreenState();
}

class _EntryEditorScreenState extends State<EntryEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _locationController;
  String? _mood;
  String? _weather;
  List<String> _selectedTags = [];
  List<String> _imageUrls = [];
  bool _isPreview = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry?.title ?? '');
    _contentController = TextEditingController(
      text: widget.entry?.content ?? '',
    );
    _locationController = TextEditingController(
      text: widget.entry?.location ?? '',
    );
    _mood = widget.entry?.mood;
    _weather = widget.entry?.weather;
    _selectedTags = widget.entry?.tags.toList() ?? [];
    _imageUrls = widget.entry?.imageUrls.toList() ?? [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = CalendarAlbumLocalizations.of(context);
    final calendarController = context.watch<CalendarController>();
    final tagController = context.watch<TagController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? l10n.get('edit') : l10n.get('newEntry')),
        actions: [
          IconButton(
            icon: Icon(_isPreview ? Icons.edit : Icons.preview),
            onPressed: () {
              setState(() {
                _isPreview = !_isPreview;
              });
            },
            tooltip: _isPreview ? l10n.get('edit') : l10n.get('preview'),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              _saveEntry(context, calendarController);
            },
          ),
        ],
      ),
      body:
          _isPreview
              ? Markdown(data: _contentController.text, selectable: true)
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: l10n.get('title'),
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 16),

                    // Content
                    TextField(
                      controller: _contentController,
                      decoration: InputDecoration(
                        labelText: l10n.get('content'),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.info_outline),
                          onPressed: () {
                            // Show markdown help
                            showDialog(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text('Markdown Help'),
                                    content: const SingleChildScrollView(
                                      child: Text(
                                        '# Heading 1\n## Heading 2\n**Bold**\n*Italic*\n- List item\n1. Numbered item\n[Link](url)\n![Image](url)',
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.of(context).pop(),
                                        child: Text(l10n.get('close')),
                                      ),
                                    ],
                                  ),
                            );
                          },
                        ),
                      ),
                      maxLines: 10,
                    ),
                    const SizedBox(height: 16),

                    // Word count
                    Text(
                      '${l10n.get('wordCount')}: ${_contentController.text.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),

                    // Location
                    TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: l10n.get('location'),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.location_on),
                      ),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 16),

                    // Mood and Weather in a row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: l10n.get('mood'),
                              border: const OutlineInputBorder(),
                            ),
                            value: _mood,
                            items:
                                [
                                  'Happy',
                                  'Sad',
                                  'Excited',
                                  'Tired',
                                  'Calm',
                                  'Anxious',
                                  'Angry',
                                  'Content',
                                ].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _mood = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: l10n.get('weather'),
                              border: const OutlineInputBorder(),
                            ),
                            value: _weather,
                            items:
                                [
                                  'Sunny',
                                  'Cloudy',
                                  'Rainy',
                                  'Snowy',
                                  'Windy',
                                  'Foggy',
                                  'Stormy',
                                  'Clear',
                                ].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _weather = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tags
                    Text(
                      l10n.get('tags'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ...tagController.tags.map((tag) {
                          final isSelected = _selectedTags.contains(tag.name);
                          return FilterChip(
                            label: Text(tag.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedTags.add(tag.name);
                                } else {
                                  _selectedTags.remove(tag.name);
                                }
                              });
                            },
                            backgroundColor: tag.color.withOpacity(0.2),
                            selectedColor: tag.color.withOpacity(0.6),
                          );
                        }),
                        ActionChip(
                          label: Text(l10n.get('addTag')),
                          avatar: const Icon(Icons.add),
                          onPressed: () {
                            // Show add tag dialog
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Images
                    Text(
                      l10n.get('images'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ..._imageUrls.map(
                            (url) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  Image.network(
                                    url,
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _imageUrls.remove(url);
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final ImagePicker picker = ImagePicker();
                              final XFile? image = await picker.pickImage(
                                source: ImageSource.gallery,
                              );
                              if (image != null) {
                                // In a real app, you would upload the image to a server
                                // and get back a URL. For now, we'll just use a placeholder.
                                setState(() {
                                  _imageUrls.add(
                                    'https://via.placeholder.com/150',
                                  );
                                });
                              }
                            },
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.add_photo_alternate),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  void _saveEntry(BuildContext context, CalendarController calendarController) {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title cannot be empty')));
      return;
    }

    if (widget.isEditing && widget.entry != null) {
      // Update existing entry
      final updatedEntry = widget.entry!.copyWith(
        title: _titleController.text,
        content: _contentController.text,
        tags: _selectedTags,
        location:
            _locationController.text.isEmpty ? null : _locationController.text,
        mood: _mood,
        weather: _weather,
        imageUrls: _imageUrls,
      );
      calendarController.updateEntry(updatedEntry);
    } else {
      // Create new entry
      final newEntry = CalendarEntry.create(
        title: _titleController.text,
        content: _contentController.text,
        tags: _selectedTags,
        location:
            _locationController.text.isEmpty ? null : _locationController.text,
        mood: _mood,
        weather: _weather,
        imageUrls: _imageUrls,
      );
      calendarController.addEntry(newEntry);
    }

    Navigator.of(context).pop();
  }
}
