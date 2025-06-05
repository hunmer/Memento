import 'dart:io';

import 'package:Memento/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../../controllers/tag_controller.dart';
import '../../models/calendar_entry.dart';
import 'entry_detail_image_viewer.dart';

class EntryDetailContent extends StatelessWidget {
  final CalendarEntry entry;

  const EntryDetailContent({super.key, required this.entry});

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

  @override
  Widget build(BuildContext context) {
    final tagController = Provider.of<TagController>(context);
    final tags =
        entry.tags
            .map((tagName) => tagController.getTagByName(tagName))
            .whereType<Tag>()
            .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entry.imageUrls.isNotEmpty)
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: entry.imageUrls.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => EntryDetailImageViewer(
                                  imageUrls: entry.imageUrls,
                                  initialIndex: index,
                                ),
                          ),
                        );
                      },
                      child: _buildImage(entry.imageUrls[index]),
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
                '${entry.createdAt.year}-${entry.createdAt.month.toString().padLeft(2, '0')}-${entry.createdAt.day.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          if (entry.location != null && entry.location!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16),
                const SizedBox(width: 8),
                Text(
                  entry.location!,
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
          MarkdownBody(data: entry.content, selectable: true),
        ],
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
}
