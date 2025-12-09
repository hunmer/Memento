import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/widgets/image_picker_dialog.dart';
import 'package:Memento/utils/image_utils.dart';
import 'dart:io';

class EntryEditorImageHandler extends StatefulWidget {
  final List<String> imageUrls;
  final List<String> thumbUrls;
  final Function(String url, String? thumbUrl) onImageAdded;
  final Function(int index) onImageRemoved;

  const EntryEditorImageHandler({
    super.key,
    required this.imageUrls,
    required this.thumbUrls,
    required this.onImageAdded,
    required this.onImageRemoved,
  });

  @override
  State<EntryEditorImageHandler> createState() =>
      _EntryEditorImageHandlerState();
}

class _EntryEditorImageHandlerState extends State<EntryEditorImageHandler> {
  Widget _buildDefaultCover() {
    return SizedBox(
      height: 100,
      width: 100,
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }

  Widget _buildImage(int index, String url, String? thumbUrl, {bool showDelete = true}) {
    if (url.isEmpty) return _buildDefaultCover();

    // 优先使用缩略图进行预览
    final displayUrl = thumbUrl ?? url;

    if (displayUrl.startsWith('http://') || displayUrl.startsWith('https://')) {
      return SizedBox(
        height: 100,
        width: 100,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            displayUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildDefaultCover(),
          ),
        ),
      );
    }

    return FutureBuilder<String>(
      future: ImageUtils.getAbsolutePath(displayUrl),
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
              ...List.generate(
                widget.imageUrls.length,
                (index) {
                  final url = widget.imageUrls[index];
                  final thumbUrl = index < widget.thumbUrls.length ? widget.thumbUrls[index] : null;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        _buildImage(index, url, thumbUrl, showDelete: widget.imageUrls.length > 1),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                widget.onImageRemoved(index);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              GestureDetector(
                onTap: () async {
                  final results = await showDialog<List<Map<String, dynamic>>>(
                    context: context,
                    builder:
                        (context) => ImagePickerDialog(
                          saveDirectory: 'calendar_album/images',
                          multiple: true,
                          enableCompression: true,
                          compressionQuality: 85,
                        ),
                  );
                  if (results != null && results.isNotEmpty) {
                    setState(() {
                      for (final result in results) {
                        if (result['url'] != null) {
                          widget.onImageAdded(
                            result['url'] as String,
                            result['thumbUrl'] as String?,
                          );
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
