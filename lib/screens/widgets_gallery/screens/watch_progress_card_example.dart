import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/watch_progress_card.dart';

/// 观看进度卡片示例
class WatchProgressCardExample extends StatelessWidget {
  const WatchProgressCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('观看进度卡片')),
      body: Container(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFE5E7EB),
        child: const Center(
          child: WatchProgressCardWidget(
            userName: 'James',
            lastWatched: '2 days ago',
            currentCount: 16,
            totalCount: 24,
            items: [
              WatchProgressItem(
                title: 'Dune: Part Two',
                thumbnailUrl: 'https://via.placeholder.com/40',
              ),
              WatchProgressItem(
                title: 'Oppenheimer',
                thumbnailUrl: 'https://via.placeholder.com/40',
              ),
              WatchProgressItem(
                title: 'Small Things like It',
                thumbnailUrl: 'https://via.placeholder.com/40',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
