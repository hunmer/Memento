import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/calendar_controller.dart';
import '../l10n/calendar_album_localizations.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class AlbumScreen extends StatelessWidget {
  const AlbumScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = CalendarAlbumLocalizations.of(context);
    final calendarController = Provider.of<CalendarController>(context);
    final images = calendarController.getAllImages();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('allPhotos')),
      ),
      body: images.isEmpty
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
                        builder: (context) => PhotoViewGallery.builder(
                          scrollPhysics: const BouncingScrollPhysics(),
                          builder: (BuildContext context, int index) {
                            return PhotoViewGalleryPageOptions(
                              imageProvider: NetworkImage(imageUrl),
                              initialScale: PhotoViewComputedScale.contained,
                              heroAttributes:
                                  PhotoViewHeroAttributes(tag: imageUrl),
                            );
                          },
                          itemCount: 1,
                          loadingBuilder: (context, event) => Center(
                            child: CircularProgressIndicator(
                              value: event == null
                                  ? null
                                  : event.cumulativeBytesLoaded /
                                      event.expectedTotalBytes!,
                            ),
                          ),
                          backgroundDecoration:
                              const BoxDecoration(color: Colors.black),
                        ),
                      ),
                    );
                  },
                  child: Hero(
                    tag: imageUrl,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.error),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}