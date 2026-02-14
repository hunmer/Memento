/// 图片轮播小组件（支持多种尺寸）
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:infinite_carousel/infinite_carousel.dart';
import 'package:provider/provider.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/utils/image_utils.dart';
import 'package:Memento/plugins/calendar_album/screens/entry_detail_screen.dart';
import 'package:Memento/plugins/calendar_album/calendar_album_plugin.dart';
import '../data.dart';

/// 图片轮播小组件（StatefulWidget 以管理控制器）
class PhotoCarouselWidget extends StatefulWidget {
  final List<PhotoItem> photos;
  final CalendarAlbumPlugin plugin;

  const PhotoCarouselWidget({
    super.key,
    required this.photos,
    required this.plugin,
  });

  @override
  State<PhotoCarouselWidget> createState() => PhotoCarouselWidgetState();
}

class PhotoCarouselWidgetState extends State<PhotoCarouselWidget>
    with SingleTickerProviderStateMixin {
  late InfiniteScrollController _controller;
  late Timer _autoScrollTimer;
  final Map<String, File> _loadedImages = {};

  @override
  void initState() {
    super.initState();
    _controller = InfiniteScrollController();
    // 预加载前几张图片
    _preloadImages();
    // 启动自动滚动（5秒）
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer.cancel();
    _controller.dispose();
    _loadedImages.clear();
    super.dispose();
  }

  /// 启动自动滚动
  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && _controller.hasClients) {
        _controller.nextItem(duration: const Duration(milliseconds: 500));
      }
    });
  }

  /// 预加载图片
  Future<void> _preloadImages() async {
    final preloadCount = widget.photos.length < 10 ? widget.photos.length : 10;
    for (int i = 0; i < preloadCount; i++) {
      _loadImageAsync(widget.photos[i].imageUrl);
    }
  }

  /// 异步加载图片
  Future<void> _loadImageAsync(String imageUrl) async {
    if (_loadedImages.containsKey(imageUrl)) return;

    try {
      final path = await ImageUtils.getAbsolutePath(imageUrl);
      if (path.isNotEmpty) {
        final file = File(path);
        if (file.existsSync()) {
          if (mounted) {
            setState(() {
              _loadedImages[imageUrl] = file;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('预加载图片失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: SizedBox(
        height: double.infinity,
        child: InfiniteCarousel.builder(
          itemCount: widget.photos.length,
          itemExtent: 150,
          loop: true,
          controller: _controller,
          itemBuilder: (context, itemIndex, realIndex) {
            final photo = widget.photos[itemIndex];
            final imageFile = _loadedImages[photo.imageUrl];

            // 如果图片未加载，触发加载
            if (imageFile == null) {
              _loadImageAsync(photo.imageUrl);
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () => _openPhotoDetail(photo),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    image:
                        imageFile != null
                            ? DecorationImage(
                              image: FileImage(imageFile),
                              fit: BoxFit.fitHeight,
                            )
                            : null,
                  ),
                  child:
                      imageFile == null
                          ? const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                          : null,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 打开图片对应的日记详情
  void _openPhotoDetail(PhotoItem photo) {
    NavigationHelper.push(
      context,
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(
            value: widget.plugin.calendarController!,
          ),
          ChangeNotifierProvider.value(value: widget.plugin.tagController!),
        ],
        child: EntryDetailScreen(entry: photo.entry),
      ),
    );
  }
}
