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
                    width: 280,
                    height: 200,
                    child: ImageDisplayCardWidget(
                      imageUrl:
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuBNLDpG0BHa75uzY36I-GHzrOMH8SYRgTj1CgrrqHnn3pvLtDhrUE_LoerrHFx6PuuOtPsMZkpPdOyrqMk8mo7sYcA3DUKkz5T3KvqXdLGsbuL3SSnWa7S3vXnChnAdaoP4xxiZ_7LJNrVEE0ouP8mLP7_QFYA6Ph1WWN_ckuHPiDJLGHlXGh2GYgW-7kUSjHIP7ERDHY309xMl_87LZ5gvQDCSA9UbYXdhhEtPeKxWlyrcBhb1OzzhRI9oBfrLTAO9J0D5zUv59g',
                      title: 'Gantiadi\nhouse',
                      label: 'Upcoming',
                      date: '01 Feb',
                      rating: 4.1,
                      icon: Icons.holiday_village,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 320,
                    height: 250,
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
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 380,
                    height: 300,
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
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 280,
                  child: ImageDisplayCardWidget(
                    imageUrl:
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuBNLDpG0BHa75uzY36I-GHzrOMH8SYRgTj1CgrrqHnn3pvLtDhrUE_LoerrHFx6PuuOtPsMZkpPdOyrqMk8mo7sYcA3DUKkz5T3KvqXdLGsbuL3SSnWa7S3vXnChnAdaoP4xxiZ_7LJNrVEE0ouP8mLP7_QFYA6Ph1WWN_ckuHPiDJLGHlXGh2GYgW-7kUSjHIP7ERDHY309xMl_87LZ5gvQDCSA9UbYXdhhEtPeKxWlyrcBhb1OzzhRI9oBfrLTAO9J0D5zUv59g',
                    title: 'Gantiadi Holiday House',
                    label: 'Upcoming Reservation',
                    date: '01 Feb 2020',
                    rating: 4.1,
                    icon: Icons.holiday_village,
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 350,
                  child: ImageDisplayCardWidget(
                    imageUrl:
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuBNLDpG0BHa75uzY36I-GHzrOMH8SYRgTj1CgrrqHnn3pvLtDhrUE_LoerrHFx6PuuOtPsMZkpPdOyrqMk8mo7sYcA3DUKkz5T3KvqXdLGsbuL3SSnWa7S3vXnChnAdaoP4xxiZ_7LJNrVEE0ouP8mLP7_QFYA6Ph1WWN_ckuHPiDJLGHlXGh2GYgW-7kUSjHIP7ERDHY309xMl_87LZ5gvQDCSA9UbYXdhhEtPeKxWlyrcBhb1OzzhRI9oBfrLTAO9J0D5zUv59g',
                    title: 'Gantiadi Holiday House - Premium Stay',
                    label: 'Upcoming Reservation - Highly Rated',
                    date: '01 Feb 2020 - Saturday',
                    rating: 4.1,
                    icon: Icons.holiday_village,
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
