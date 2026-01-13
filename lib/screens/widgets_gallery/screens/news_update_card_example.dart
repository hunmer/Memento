import 'package:flutter/material.dart';
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
        child: const Center(
          child: NewsUpdateCardWidget(
            icon: Icons.bolt,
            title: '"I confess." The Belarusian pro-governmental telegram channel published a video of Roman Protasevich',
            timestamp: '4 minutes ago',
            currentIndex: 0,
            totalItems: 4,
          ),
        ),
      ),
    );
  }
}
