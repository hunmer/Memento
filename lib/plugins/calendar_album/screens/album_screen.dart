import 'package:Memento/plugins/calendar_album/screens/entry_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../controllers/calendar_controller.dart';
import '../l10n/calendar_album_localizations.dart';
import '../../../utils/image_utils.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  late CalendarController _calendarController;
  late CalendarAlbumLocalizations l10n;
  List<String> _images = [];
  late List<Widget> _imageWidgets;

  @override
  void initState() {
    super.initState();
    _calendarController = Provider.of<CalendarController>(
      context,
      listen: false,
    );
    _images = _calendarController.getAllImages();
    _imageWidgets = List.filled(
      _images.length,
      Image.asset('assets/images/image_not_found.jpg', fit: BoxFit.contain),
    );
    _preloadImages();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = CalendarAlbumLocalizations.of(context);
  }

  Future<void> _preloadImages() async {
    for (var i = 0; i < _images.length; i++) {
      try {
        final path = await ImageUtils.getAbsolutePath(_images[i]);
        if (path.isNotEmpty) {
          final file = File(path);
          if (file.existsSync()) {
            _imageWidgets[i] = Image.file(file, fit: BoxFit.contain);
          }
        }
      } catch (e) {
        debugPrint('Error loading image: $e');
      }
      if (mounted) setState(() {});
    }
  }

  Widget _buildDefaultCover() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l10n.allPhotos)),
      body: Consumer<CalendarController>(
        builder: (context, calendarController, child) {
          final images = calendarController.getAllImages();
          return images.isEmpty
              ? Center(child: Text(l10n.noPhotos))
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
                              (context) => _PhotoViewScreen(
                                images: images,
                                initialIndex: index,
                              ),
                        ),
                      );
                    },
                    child: Hero(tag: imageUrl, child: _buildImage(imageUrl)),
                  );
                },
              );
        },
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return _buildDefaultCover();
    }

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error loading network image: $error');
            return _buildDefaultCover();
          },
        ),
      );
    }
    return FutureBuilder<String>(
      future: ImageUtils.getAbsolutePath(imageUrl),
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
}

class _PhotoViewScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _PhotoViewScreen({required this.images, required this.initialIndex});

  @override
  State<_PhotoViewScreen> createState() => _PhotoViewScreenState();
}

class _PhotoViewScreenState extends State<_PhotoViewScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.note),
            onPressed: () {
              final currentImage =
                  widget.images[_pageController.page?.round() ??
                      widget.initialIndex];
              final entry = Provider.of<CalendarController>(
                context,
                listen: false,
              ).getDiaryEntryForImage(currentImage);
              if (entry != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EntryDetailScreen(entry: entry),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.black,
        child: PhotoViewGallery.builder(
          itemCount: widget.images.length,
          builder: (context, index) {
            return PhotoViewGalleryPageOptions.customChild(
              child: FutureBuilder<String>(
                future: ImageUtils.getAbsolutePath(widget.images[index]),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    final file = File(snapshot.data!);
                    if (file.existsSync()) {
                      return Image.file(file, fit: BoxFit.contain);
                    }
                  }
                  return Image.asset(
                    'assets/images/image_not_found.png',
                    fit: BoxFit.contain,
                  );
                },
              ),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
              initialScale: PhotoViewComputedScale.contained,
              heroAttributes: PhotoViewHeroAttributes(
                tag: widget.images[index],
              ),
            );
          },
          scrollPhysics: const NeverScrollableScrollPhysics(),
          pageController: _pageController,
          loadingBuilder:
              (context, event) => Center(
                child: CircularProgressIndicator(
                  value:
                      event == null || event.expectedTotalBytes == null
                          ? 0
                          : event.cumulativeBytesLoaded /
                              event.expectedTotalBytes!,
                  color: Colors.white,
                ),
              ),
        ),
      ),
    );
  }
}
