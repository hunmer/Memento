import 'dart:io';
import 'package:Memento/plugins/calendar_album/l10n/calendar_album_localizations.dart';
import 'package:Memento/plugins/calendar_album/screens/entry_detail/entry_detail_image_viewer.dart';
import 'package:Memento/plugins/calendar_album/screens/entry_editor_screen.dart';
import 'package:Memento/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../controllers/calendar_controller.dart';
import '../controllers/tag_controller.dart';
import '../models/calendar_entry.dart';

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
  late final CalendarController _calendarController;
  late CalendarEntry? _currentEntry;

  @override
  void initState() {
    super.initState();
    _currentEntry = widget.entry;
    _calendarController = Provider.of<CalendarController>(
      context,
      listen: false,
    );
    _calendarController.addListener(_onCalendarChange);
  }

  @override
  void dispose() {
    _calendarController.removeListener(_onCalendarChange);
    super.dispose();
  }

  void _onCalendarChange() {
    if (!mounted) return;

    final currentEntry = widget.entry;
    if (currentEntry != null) {
      final updatedEntry = _calendarController.getEntryById(currentEntry.id);
      if (updatedEntry != null && updatedEntry != _currentEntry) {
        setState(() {
          _currentEntry = updatedEntry;
        });
      }
    }
  }

  Widget _buildEntryEditorScreen({
    required CalendarController calendarController,
    required TagController tagController,
    DateTime? initialDate,
    CalendarEntry? entry,
    required bool isEditing,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CalendarController>.value(
          value: calendarController,
        ),
        ChangeNotifierProvider<TagController>.value(value: tagController),
      ],
      child: EntryEditorScreen(
        initialDate: initialDate,
        entry: entry,
        isEditing: isEditing,
      ),
    );
  }

  Widget _buildDefaultCover() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.image_not_supported,
        color: Colors.grey,
        size: 48,
      ),
    );
  }

  Widget _buildImage(String url) {
    if (url.isEmpty) return _buildDefaultCover();

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return SizedBox(
        height: 200,
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          debugPrint('Error loading image path: ${snapshot.error}');
          return _buildDefaultCover();
        }

        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final file = File(snapshot.data!);
          if (file.existsSync()) {
            return SizedBox(
              height: 200,
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

  @override
  Widget build(BuildContext context) {
    final l10n = CalendarAlbumLocalizations.of(context);
    final calendarController = Provider.of<CalendarController>(context);
    final tagController = Provider.of<TagController>(context);

    if (widget.entry == null) {
      final selectedDate = widget.date!;
      final entries = calendarController.getEntriesForDate(selectedDate);

      if (entries.isEmpty) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => _buildEntryEditorScreen(
                        calendarController: calendarController,
                        tagController: tagController,
                        initialDate: selectedDate,
                        isEditing: false,
                      ),
                    ),
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
                  l10n.get('noEntriesForDate'),
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => _buildEntryEditorScreen(
                          calendarController: calendarController,
                          tagController: tagController,
                          initialDate: selectedDate,
                          isEditing: false,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: Text(l10n.get('createEntry')),
                ),
              ],
            ),
          ),
        );
      }

      if (entries.isEmpty) return const SizedBox.shrink();
      return EntryDetailScreen(entry: entries.first);
    }

    final currentEntry = _currentEntry ?? widget.entry!;
    final tags = currentEntry.tags;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentEntry.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updatedEntry = await Navigator.push<CalendarEntry?>(
                context,
                MaterialPageRoute(
                  builder: (context) => _buildEntryEditorScreen(
                    calendarController: calendarController,
                    tagController: tagController,
                    entry: currentEntry.copyWith(),
                    isEditing: true,
                  ),
                ),
              );

              if (updatedEntry != null && context.mounted) {
                setState(() {});
                _calendarController.updateEntry(updatedEntry);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.get('delete')),
                  content: Text('${l10n.get('delete')} "${currentEntry.title}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.get('cancel')),
                    ),
                    TextButton(
                      onPressed: () {
                        calendarController.deleteEntry(currentEntry);
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                      child: Text(l10n.get('delete')),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (currentEntry.imageUrls.isNotEmpty)
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: currentEntry.imageUrls.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Scaffold(
                                body: EntryDetailImageViewer(
                                  imageUrls: currentEntry.imageUrls,
                                  initialIndex: index,
                                ),
                              ),
                            ),
                          );
                        },
                        child: _buildImage(currentEntry.imageUrls[index]),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${currentEntry.createdAt.year}-${currentEntry.createdAt.month.toString().padLeft(2, '0')}-${currentEntry.createdAt.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            if (currentEntry.location != null && currentEntry.location!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    currentEntry.location!,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: tags.map((tag) {
                  final color = Colors.primaries[tag.hashCode % Colors.primaries.length];
                  return Chip(
                    label: Text(tag),
                    backgroundColor: color.withOpacity(0.2),
                    labelStyle: TextStyle(color: color),
                    side: BorderSide(color: color.withOpacity(0.5)),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            MarkdownBody(data: currentEntry.content, selectable: true),
          ],
        ),
      ),
    );
  }
}
