import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../controllers/calendar_controller.dart';
import '../l10n/calendar_album_localizations.dart';
import '../../../utils/image_utils.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class AlbumScreen extends StatelessWidget {
  const AlbumScreen({super.key});

  Widget _buildDefaultCover() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }

  Widget _buildImage(String url) {
    if (url.isEmpty) {
      return _buildDefaultCover();
    }

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error loading network image: $error');
            return _buildDefaultCover();
          },
        ),
      );
    }

    return FutureBuilder<String>(
      future: ImageUtils.getAbsolutePath(url),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final file = File(snapshot.data!);
          if (file.existsSync()) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                file,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Error loading local image: $error');
                  return _buildDefaultCover();
                },
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
    final images = calendarController.getAllImages();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.get('allPhotos'))),
      body:
          images.isEmpty
              ? Center(child: Text(l10n.get('noPhotos')))
              : GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final imageUrl = images[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => Scaffold(
                                extendBodyBehindAppBar: true,
                                appBar: AppBar(
                                  backgroundColor: Colors.black.withAlpha(128),
                                  elevation: 0,
                                  iconTheme: const IconThemeData(
                                    color: Colors.white,
                                  ),
                                ),
                                body: PhotoViewGallery.builder(
                                  itemCount: images.length,
                                  builder: (context, index) {
                                    return PhotoViewGalleryPageOptions(
                                      imageProvider: FileImage(
                                        File(images[index]),
                                      ),
                                      minScale:
                                          PhotoViewComputedScale.contained,
                                      maxScale:
                                          PhotoViewComputedScale.covered * 2,
                                      initialScale:
                                          PhotoViewComputedScale.contained,
                                      heroAttributes: PhotoViewHeroAttributes(
                                        tag: images[index],
                                      ),
                                    );
                                  },
                                  scrollPhysics: const BouncingScrollPhysics(),
                                  backgroundDecoration: const BoxDecoration(
                                    color: Colors.black,
                                  ),
                                  pageController: PageController(
                                    initialPage: index,
                                  ),
                                  loadingBuilder:
                                      (context, event) => Center(
                                        child: CircularProgressIndicator(
                                          value:
                                              event == null
                                                  ? 0
                                                  : event.cumulativeBytesLoaded /
                                                      event.expectedTotalBytes!,
                                          color: Colors.white,
                                        ),
                                      ),
                                ),
                              ),
                        ),
                      );
                    },
                    child: Hero(tag: imageUrl, child: _buildImage(imageUrl)),
                  );
                },
              ),
    );
  }
}
