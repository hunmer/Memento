import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/image_display_card.dart';

/// 图片展示卡片示例
class HolidayRentalCardExample extends StatelessWidget {
  const HolidayRentalCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('图片展示卡片')),
      body: Container(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFF64748B),
        child: const Center(
          child: ImageDisplayCardWidget(
            imageUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuBNLDpG0BHa75uzY36I-GHzrOMH8SYRgTj1CgrrqHnn3pvLtDhrUE_LoerrHFx6PuuOtPsMZkpPdOyrqMk8mo7sYcA3DUKkz5T3KvqXdLGsbuL3SSnWa7S3vXnChnAdaoP4xxiZ_7LJNrVEE0ouP8mLP7_QFYA6Ph1WWN_ckuHPiDJLGHlXGh2GYgW-7kUSjHIP7ERDHY309xMl_87LZ5gvQDCSA9UbYXdhhEtPeKxWlyrcBhb1OzzhRI9oBfrLTAO9J0D5zUv59g',
            title: 'Gantiadi\nholiday house',
            label: 'Upcoming',
            date: '01 Feb 2020',
            rating: 4.1,
            icon: Icons.holiday_village,
          ),
        ),
      ),
    );
  }
}
