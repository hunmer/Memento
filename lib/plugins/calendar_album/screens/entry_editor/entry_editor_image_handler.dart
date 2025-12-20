import 'dart:ui';

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
    return Container(
      width: 112,
      height: 144,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }

  Widget _buildImageContent(String url, String? thumbUrl) {
    // 优先使用缩略图进行预览
    final displayUrl = thumbUrl ?? url;

    if (displayUrl.startsWith('http://') || displayUrl.startsWith('https://')) {
      return Image.network(
        displayUrl,
        fit: BoxFit.cover,
        width: 112,
        height: 144,
        errorBuilder: (context, error, stackTrace) => _buildDefaultCover(),
      );
    }

    return FutureBuilder<String>(
      future: ImageUtils.getAbsolutePath(displayUrl),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final file = File(snapshot.data!);
          if (file.existsSync()) {
            return Image.file(
              file,
              fit: BoxFit.cover,
              width: 112,
              height: 144,
              errorBuilder:
                  (context, error, stackTrace) => _buildDefaultCover(),
            );
          }
        }
        return _buildDefaultCover();
      },
    );
  }

  Widget _buildImageItem(int index, String url, String? thumbUrl) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          Container(
            width: 112,
            height: 144,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildImageContent(url, thumbUrl),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                widget.onImageRemoved(index);
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
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
          width: 112,
          height: 144,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade300,
              style:
                  BorderStyle
                      .none, // Custom dashed border implementation would be complex here, simplifying with standard border or dashed effect via CustomPainter if needed.
              // For simplicity and standard Flutter widgets, we'll use a standard border for now or a plugin if strict adherence is needed.
              // Re-reading instruction: "dashed border". Flutter doesn't have a simple dashed border property for Container.
              // I will use a custom painter or just a solid border that looks clean.
              // Let's use a solid border but maybe lighter to mimic the feel, or use DottedBorder if I knew it was in pubspec.
              // Since I must strictly adhere, I'll use a standard border for safety but style it lightly.
            ),
          ),
          child: CustomPaint(
            painter: _DashedBorderPainter(
              color: Colors.grey.shade300,
              strokeWidth: 1.5,
              radius: 12,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_a_photo_outlined,
                  size: 30,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  'calendar_album_add_photos'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: [
          _buildAddButton(),
          ...List.generate(
            widget.imageUrls.length,
            (index) => _buildImageItem(
              index,
              widget.imageUrls[index],
              index < widget.thumbUrls.length ? widget.thumbUrls[index] : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

    final path =
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.width, size.height),
            Radius.circular(radius),
          ),
        );

    final dashPath = _dashPath(
      path,
      dashArray: CircularIntervalList<double>([5.0, 5.0]),
    );
    canvas.drawPath(dashPath, paint);
  }

  // Simple dash path implementation
  Path _dashPath(
    Path source, {
    required CircularIntervalList<double> dashArray,
  }) {
    final Path dest = Path();
    for (final PathMetric metric in source.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final double len = dashArray.next;
        if (draw) {
          dest.addPath(
            metric.extractPath(distance, distance + len),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CircularIntervalList<T> {
  final List<T> _values;
  int _index = 0;

  CircularIntervalList(this._values);

  T get next {
    if (_index >= _values.length) {
      _index = 0;
    }
    return _values[_index++];
  }
}
