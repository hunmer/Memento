import 'package:flutter/material.dart';
import '../../../../widgets/image_picker_dialog.dart';
import '../../../../utils/image_utils.dart';
import 'dart:io';
import 'package:collection/collection.dart';

class EntryEditorImageHandler extends StatefulWidget {
  final List<String> imageUrls;
  final Function(String) onImageAdded;
  final Function(String) onImageRemoved;

  const EntryEditorImageHandler({
    super.key,
    required this.imageUrls,
    required this.onImageAdded,
    required this.onImageRemoved,
  });

  @override
  State<EntryEditorImageHandler> createState() =>
      _EntryEditorImageHandlerState();
}

class _EntryEditorImageHandlerState extends State<EntryEditorImageHandler> {
  Widget _buildDefaultCover() {
    return Container(
      height: 100,
      width: 100,
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }

  Widget _buildImage(String url, {bool showDelete = true}) {
    if (url.isEmpty) return _buildDefaultCover();

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return SizedBox(
        height: 100,
        width: 100,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildDefaultCover(),
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
                  errorBuilder:
                      (context, error, stackTrace) => _buildDefaultCover(),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ...widget.imageUrls.map(
                (url) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      _buildImage(url, showDelete: widget.imageUrls.length > 1),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              widget.onImageRemoved(url);
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
                  final results = await showDialog<List<Map<String, dynamic>>>(
                    context: context,
                    builder:
                        (context) => ImagePickerDialog(
                          saveDirectory: 'calendar_album/images',
                          multiple: true,
                        ),
                  );
                  if (results != null && results.isNotEmpty) {
                    setState(() {
                      for (final result in results) {
                        if (result['url'] != null) {
                          widget.onImageAdded(result['url'] as String);
                        }
                      }
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
    );
  }
}
