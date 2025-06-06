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
    _imageProviders = widget.imageUrls.map(_createImageProvider).toList();
  }

  ImageProvider _createImageProvider(String url) {
    if (url.startsWith('http')) {
      return NetworkImage(url);
    }
    return FileImage(File(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
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
