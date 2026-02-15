import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/news_update_card.dart';

/// 新闻更新卡片示例
class NewsUpdateCardExample extends StatelessWidget {
  const NewsUpdateCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('新闻更新卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
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
                    child: NewsUpdateCardWidget(
                      size: const SmallSize(),
                      icon: Icons.bolt,
                      title: '"I confess."',
                      timestamp: '4 minutes ago',
                      currentIndex: 0,
                      totalItems: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 200,
                    child: NewsUpdateCardWidget(
                      size: const MediumSize(),
                      icon: Icons.bolt,
                      title: '"I confess." The Belarusian pro-governmental',
                      timestamp: '4 minutes ago',
                      currentIndex: 0,
                      totalItems: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 250,
                    child: NewsUpdateCardWidget(
                      size: const LargeSize(),
                      icon: Icons.bolt,
                      title: '"I confess." The Belarusian pro-governmental telegram channel published a video of Roman Protasevich',
                      timestamp: '4 minutes ago',
                      currentIndex: 0,
                      totalItems: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 220,
                  child: NewsUpdateCardWidget(
                    size: const WideSize(),
                    icon: Icons.bolt,
                    title: '"I confess." The Belarusian pro-governmental telegram channel published a video of Roman Protasevich with apparent pressure from authorities',
                    timestamp: '4 minutes ago',
                    currentIndex: 0,
                    totalItems: 4,
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 280,
                  child: NewsUpdateCardWidget(
                    size: const Wide2Size(),
                    icon: Icons.bolt,
                    title: '"I confess." The Belarusian pro-governmental telegram channel published a video of Roman Protasevich with apparent pressure from authorities regarding the Ryanair flight incident',
                    timestamp: '4 minutes ago',
                    currentIndex: 0,
                    totalItems: 4,
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
