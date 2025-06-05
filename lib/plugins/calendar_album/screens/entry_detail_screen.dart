import 'dart:io';

import 'package:Memento/plugins/calendar_album/l10n/calendar_album_localizations.dart';
import 'package:Memento/plugins/calendar_album/screens/entry_editor_screen.dart';
import 'package:Memento/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
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
    if (url.isEmpty) {
      return _buildDefaultCover();
    }

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
                      builder:
                          (context) => _buildEntryEditorScreen(
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
                        builder:
                            (context) => _buildEntryEditorScreen(
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

      // 如果有多个条目，显示第一个
      if (entries.isEmpty) return const SizedBox.shrink();
      return EntryDetailScreen(entry: entries.first);
    }

    final currentEntry = widget.entry!;
    final tags = currentEntry.tags
        .map((tagName) => tagController.getTagByName(tagName))
        .whereType<Tag>()
        .toList();

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
                  builder:
                      (context) => _buildEntryEditorScreen(
                        calendarController: calendarController,
                        tagController: tagController,
                        entry: currentEntry,
                        isEditing: true,
                      ),
                ),
              );

              if (updatedEntry != null && context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder:
                        (context) => EntryDetailScreen(entry: updatedEntry),
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
                      title: Text(l10n.get('delete')),
                      content: Text(
                        '${l10n.get('delete')} "${currentEntry.title}"?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(l10n.get('cancel')),
                        ),
                        TextButton(
                          onPressed: () {
                            calendarController.deleteEntry(currentEntry);
                            Navigator.of(context).pop(); // 关闭对话框
                            Navigator.of(context).pop(); // 返回上一页
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
                              builder:
                                  (context) => Scaffold(
                                    appBar: AppBar(
                                      backgroundColor: Colors.black,
                                      iconTheme: const IconThemeData(
                                        color: Colors.white,
                                      ),
                                    ),
                                    body: PhotoViewGallery.builder(
                                      scrollPhysics:
                                          const BouncingScrollPhysics(),
                                      builder: (
                                        BuildContext context,
                                        int galleryIndex,
                                      ) {
                                        final imageUrl =
                                            currentEntry
                                                .imageUrls[galleryIndex];
                                        if (imageUrl.startsWith('http')) {
                                          return PhotoViewGalleryPageOptions(
                                            imageProvider: NetworkImage(
                                              imageUrl,
                                            ),
                                            initialScale:
                                                PhotoViewComputedScale
                                                    .contained,
                                            minScale:
                                                PhotoViewComputedScale
                                                    .contained *
                                                0.8,
                                            maxScale:
                                                PhotoViewComputedScale.covered *
                                                2,
                                          );
                                        }
                                        final localImagePath = await ImageUtils.getAbsolutePath(imageUrl);
                                        if (localImagePath != null && localImagePath.isNotEmpty && File(localImagePath).existsSync()) {
                                          return PhotoViewGalleryPageOptions(
                                            imageProvider: FileImage(File(localImagePath)),
                                            initialScale: PhotoViewComputedScale.contained,
                                            minScale: PhotoViewComputedScale.contained * 0.8,
                                            maxScale: PhotoViewComputedScale.covered * 2,
                                          );
                                        }
                                        return PhotoViewGalleryPageOptions(
                                          imageProvider: const AssetImage('assets/icon/icon.png'),
                                          initialScale: PhotoViewComputedScale.contained,
                                        );
                                      },
                                      itemCount: currentEntry.imageUrls.length,
                                      loadingBuilder:
                                          (context, event) => const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                      backgroundDecoration: const BoxDecoration(
                                        color: Colors.black,
                                      ),
                                      pageController: PageController(
                                        initialPage: index,
                                      ),
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
                  ],
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
            if (currentEntry.location != null &&
                currentEntry.location!.isNotEmpty) ...[
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
                children:
                    tags.map((tag) {
                      return Chip(
                        label: Text(tag.name),
                        backgroundColor: Color.fromRGBO(
                          (tag.color.red * 255.0).round() & 0xff,
                          (tag.color.green * 255.0).round() & 0xff,
                          (tag.color.blue * 255.0).round() & 0xff,
                          0.2,
                        ),
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
