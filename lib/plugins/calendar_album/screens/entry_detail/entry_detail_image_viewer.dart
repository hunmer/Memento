import 'package:Memento/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'dart:io';

class EntryDetailImageViewer extends StatelessWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const EntryDetailImageViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (BuildContext context, int galleryIndex) {
          final imageUrl = imageUrls[galleryIndex];
          if (imageUrl.startsWith('http')) {
            return PhotoViewGalleryPageOptions(
              imageProvider: NetworkImage(imageUrl),
              initialScale: PhotoViewComputedScale.contained,
              minScale: PhotoViewComputedScale.contained * 0.8,
              maxScale: PhotoViewComputedScale.covered * 2,
            );
          }
          return FutureBuilder<String>(
            future: ImageUtils.getAbsolutePath(imageUrl),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: FileImage(File(snapshot.data!)),
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
          );
        },
        itemCount: imageUrls.length,
        loadingBuilder:
            (context, event) =>
                const Center(child: CircularProgressIndicator()),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        pageController: PageController(initialPage: initialIndex),
      ),
    );
  }
}
