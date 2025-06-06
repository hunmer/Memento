import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/calendar_controller.dart';
import '../controllers/tag_controller.dart';
import '../models/calendar_entry.dart';
import '../l10n/calendar_album_localizations.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../../../widgets/image_picker_dialog.dart';
import '../../../utils/image_utils.dart';

class EntryEditorScreen extends StatefulWidget {
  final CalendarEntry? entry;
  final DateTime? initialDate;
  final bool isEditing;

  const EntryEditorScreen({
    super.key,
    this.entry,
    this.initialDate,
    required this.isEditing,
  });

  @override
  State<EntryEditorScreen> createState() => _EntryEditorScreenState();
}

class _EntryEditorScreenState extends State<EntryEditorScreen> {
  Widget _buildDefaultCover() {
    return Container(
      height: 100,
      width: 100,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }

  Widget _buildImage(String url) {
    if (url.isEmpty) {
      return _buildDefaultCover();
    }

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return SizedBox(
        height: 100,
        width: 100,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Error loading network image: $error');
              return _buildDefaultCover();
            },
          ),
        ),
      );
    }

    return FutureBuilder<String>(
      future: ImageUtils.getAbsolutePath(url),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final file = File(snapshot.data!);
          if (file.existsSync()) {
            return SizedBox(
              height: 100,
              width: 100,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  file,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Error loading local image: $error');
                    return _buildDefaultCover();
                  },
                ),
              ),
            );
          }
        }
        return _buildDefaultCover();
      },
    );
  }

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
    final tagController = Provider.of<TagController>(context, listen: false);
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
            onPressed: () async {
              try {
                if (!mounted) return;
                final savedEntry = _saveEntry(context, calendarController);
                if (savedEntry != null) {
                  Navigator.of(context).pop(savedEntry);
                }
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
              }
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
                        prefixIcon: IconButton(
                          icon: const Icon(Icons.location_on),
                          onPressed: () async {
                            try {
                              // 这里应该使用定位SDK获取经纬度，这里使用示例坐标
                              const location =
                                  '117.130967881945,36.673222113716';
                              final response = await http.get(
                                Uri.parse(
                                  'http://restapi.amap.com/v3/geocode/regeo?key=dad6a772bf826842c3049e9c7198115c&location=$location&poitype=&radius=1000&extensions=all&batch=false&roadlevel=0',
                                ),
                              );

                              if (!mounted) return;

                              if (response.statusCode == 200) {
                                final data = json.decode(response.body);
                                if (data['status'] == '1') {
                                  setState(() {
                                    _locationController.text =
                                        data['regeocode']['formatted_address'];
                                  });
                                }
                              }
                            } catch (e) {
                              if (!mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('获取位置失败: $e')),
                              );
                            }
                          },
                        ),
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
                        ...(tagController?.tags ?? []).map<Widget>((tag) {
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
                        }).toList(),
                        ActionChip(
                          label: Text(l10n.get('addTag')),
                          avatar: const Icon(Icons.add),
                          onPressed: () {
                            final textController = TextEditingController();
                            showDialog(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: Text(l10n.get('addTag')),
                                    content: TextField(
                                      controller: textController,
                                      autofocus: true,
                                      decoration: InputDecoration(
                                        labelText: l10n.get('tagName'),
                                        border: const OutlineInputBorder(),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.of(context).pop(),
                                        child: Text(l10n.get('cancel')),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          final value = textController.text;
                                          if (value.isNotEmpty &&
                                              tagController != null) {
                                            final newTag = Tag.create(
                                              name: value,
                                            );
                                            tagController.addTag(newTag);
                                            setState(() {
                                              _selectedTags.add(value);
                                            });
                                          }
                                          // 同步新标签到标签管理
                                          for (final tagName in _selectedTags) {
                                            if (!tagController.tags.any(
                                              (tag) => tag.name == tagName,
                                            )) {
                                              final newTag = Tag.create(
                                                name: tagName,
                                                color: Colors.blue,
                                              );
                                              tagController.addTag(newTag);
                                            }
                                          }
                                          Navigator.of(context).pop();
                                        },
                                        child: Text(l10n.get('confirm')),
                                      ),
                                    ],
                                  ),
                            );
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
                                  _buildImage(url),
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
                              final result =
                                  await showDialog<Map<String, dynamic>>(
                                    context: context,
                                    builder:
                                        (context) => const ImagePickerDialog(
                                          saveDirectory:
                                              'calendar_album/images',
                                        ),
                                  );
                              if (result != null && result['url'] != null) {
                                setState(() {
                                  _imageUrls.add(result['url'] as String);
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

  CalendarEntry? _saveEntry(
    BuildContext context,
    CalendarController calendarController,
  ) {
    final tagController = Provider.of<TagController>(context, listen: false);
    if (!mounted) return null;
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title cannot be empty')));
      return null;
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
      return updatedEntry;
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
      return newEntry;
    }
  }
}
