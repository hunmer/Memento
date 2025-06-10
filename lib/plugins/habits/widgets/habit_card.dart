import 'package:Memento/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class HabitCard extends StatelessWidget {
  final String? imageUrl;
  final String title;
  final List<String> subtitles;
  final VoidCallback? onTap;

  const HabitCard({
    super.key,
    this.imageUrl,
    required this.title,
    this.subtitles = const [],
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Expanded(child: _buildImage()),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  ...subtitles.map(
                    (text) => Text(
                      text,
                      style: Theme.of(context).textTheme.bodySmall,
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

  Widget _buildImage() {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return const Center(child: Icon(Icons.auto_awesome, size: 48));
    }

    return FutureBuilder<String>(
      future:
          imageUrl!.startsWith('http')
              ? Future.value(imageUrl!)
              : ImageUtils.getAbsolutePath(imageUrl!),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Center(
            child: AspectRatio(
              aspectRatio: 1.0,
              child: ClipOval(
                child:
                    imageUrl!.startsWith('http')
                        ? Image.network(
                          snapshot.data!,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image),
                        )
                        : Image.file(
                          File(snapshot.data!),
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image),
                        ),
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return const Icon(Icons.broken_image);
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }
}
