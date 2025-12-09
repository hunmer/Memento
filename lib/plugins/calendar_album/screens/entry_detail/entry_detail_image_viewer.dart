import 'package:Memento/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'dart:io';

class EntryDetailImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const EntryDetailImageViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  State<EntryDetailImageViewer> createState() => _EntryDetailImageViewerState();
}

class _EntryDetailImageViewerState extends State<EntryDetailImageViewer> {
  late PageController _pageController;
  late List<ImageProvider> _imageProviders;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _imageProviders = List.filled(
      widget.imageUrls.length,
      const AssetImage('assets/placeholder.png'),
      growable: false,
    );

    // 异步加载所有图片
    for (var i = 0; i < widget.imageUrls.length; i++) {
      _createImageProvider(widget.imageUrls[i])
          .then((provider) {
            if (mounted) {
              setState(() {
                _imageProviders[i] = provider;
              });
            }
          })
          .catchError((e) {
            debugPrint('Error loading image: $e');
            if (mounted) {
              setState(() {
                _imageProviders[i] = const AssetImage(
                  'assets/error_placeholder.png',
                );
              });
            }
          });
    }
  }

  Future<ImageProvider> _createImageProvider(String url) async {
    if (url.startsWith('http')) {
      return NetworkImage(url);
    }
    final absolutePath = await ImageUtils.getAbsolutePath(url);
    if (await File(absolutePath).exists()) {
      return FileImage(File(absolutePath));
    }
    throw Exception('Image file not found at path: $absolutePath');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PhotoViewGallery.builder(
        scrollPhysics: const NeverScrollableScrollPhysics(),
        builder: (BuildContext context, int index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: _imageProviders[index],
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained * 0.8,
            maxScale: PhotoViewComputedScale.covered * 2,
            heroAttributes: PhotoViewHeroAttributes(
              tag: widget.imageUrls[index],
            ),
          );
        },
        itemCount: _imageProviders.length,
        loadingBuilder:
            (context, event) => Center(
              child: SizedBox(
                width: 20.0,
                height: 20.0,
                child: CircularProgressIndicator(
                  value:
                      event == null
                          ? 0
                          : event.cumulativeBytesLoaded /
                              event.expectedTotalBytes!,
                ),
              ),
            ),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        pageController: _pageController,
      ),
    );
  }
}
