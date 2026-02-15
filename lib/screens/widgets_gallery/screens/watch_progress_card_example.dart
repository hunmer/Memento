import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('小尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 150,
                    height: 150,
                    child: WatchProgressCardWidget(
                      size: const SmallSize(),
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
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: WatchProgressCardWidget(
                      size: const MediumSize(),
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
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: WatchProgressCardWidget(
                      size: const LargeSize(),
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
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸 (4x1)'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 450,
                    height: 180,
                    child: WatchProgressCardWidget(
                      size: const WideSize(),
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
                        WatchProgressItem(
                          title: 'The Creator',
                          thumbnailUrl: 'https://via.placeholder.com/40',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('宽尺寸 (4x2)'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 450,
                    height: 350,
                    child: WatchProgressCardWidget(
                      size: const Wide2Size(),
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
                        WatchProgressItem(
                          title: 'The Creator',
                          thumbnailUrl: 'https://via.placeholder.com/40',
                        ),
                        WatchProgressItem(
                          title: 'Mission Impossible',
                          thumbnailUrl: 'https://via.placeholder.com/40',
                        ),
                        WatchProgressItem(
                          title: 'John Wick 4',
                          thumbnailUrl: 'https://via.placeholder.com/40',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
      ),
    );
  }
}
