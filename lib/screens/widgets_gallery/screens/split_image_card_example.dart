import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/split_image_card.dart';

/// 图片分割卡片示例
class SplitImageCardExample extends StatelessWidget {
  const SplitImageCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('图片分割卡片')),
      body: Container(
        color: isDark ? const Color(0xFF5B5CE6) : const Color(0xFFF3F4F6),
        child: const Center(
          child: SplitImageCardWidget(
            imageUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuCIUN5u7_vXAmPtmC1n8CohO3eS0nZOPxCdcvHkmt1gIycehc3bA86brIYWSrJTWE6Wix61_MBSRyWe1uhT0fDO3PsKCQ3_BWhVESA4KhsovB-7V2yyRmartUzJ7Y-4imptSg_sOYJby5zQl_Nh7CLA6YSu-JvkZlW3V0aF1_x4aq5RKTHGwdFl9qEfHNSpTlpcmytGbAH2zOMnzAPVbgRmf4i8ef0MhxwxconBvFNmKy3QE5BzUvw5s8EDAwiCwlO_MrtTXCrvyA',
            topIcon: Icons.schedule,
            topText: '14:00',
            title: 'A Georgian Masterpiece in the Heart',
            bottomIcon: Icons.calendar_today,
            bottomText: '01 Feb 2020',
          ),
        ),
      ),
    );
  }
}
