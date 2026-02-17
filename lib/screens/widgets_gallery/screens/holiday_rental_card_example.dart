import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/image_display_card.dart';

/// 图片展示卡片示例
class HolidayRentalCardExample extends StatelessWidget {
  const HolidayRentalCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('图片展示卡片')),
      body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('小尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: ImageDisplayCardWidget(
                    size: const SmallSize(),
                    imageUrl:
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuBNLDpG0BHa75uzY36I-GHzrOMH8SYRgTj1CgrrqHnn3pvLtDhrUE_LoerrHFx6PuuOtPsMZkpPdOyrqMk8mo7sYcA3DUKkz5T3KvqXdLGsbuL3SSnWa7S3vXnChnAdaoP4xxiZ_7LJNrVEE0ouP8mLP7_QFYA6Ph1WWN_ckuHPiDJLGHlXGh2GYgW-7kUSjHIP7ERDHY309xMl_87LZ5gvQDCSA9UbYXdhhEtPeKxWlyrcBhb1OzzhRI9oBfrLTAO9J0D5zUv59g',
                    title: 'Gantiadi\nhouse',
                    label: 'Upcoming',
                    date: '01 Feb',
                    rating: 4.1,
                    icon: Icons.holiday_village,
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: ImageDisplayCardWidget(
                    size: const MediumSize(),
                    imageUrl:
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuBNLDpG0BHa75uzY36I-GHzrOMH8SYRgTj1CgrrqHnn3pvLtDhrUE_LoerrHFx6PuuOtPsMZkpPdOyrqMk8mo7sYcA3DUKkz5T3KvqXdLGsbuL3SSnWa7S3vXnChnAdaoP4xxiZ_7LJNrVEE0ouP8mLP7_QFYA6Ph1WWN_ckuHPiDJLGHlXGh2GYgW-7kUSjHIP7ERDHY309xMl_87LZ5gvQDCSA9UbYXdhhEtPeKxWlyrcBhb1OzzhRI9oBfrLTAO9J0D5zUv59g',
                    title: 'Gantiadi\nholiday house',
                    label: 'Upcoming',
                    date: '01 Feb 2020',
                    rating: 4.1,
                    icon: Icons.holiday_village,
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: ImageDisplayCardWidget(
                    size: const LargeSize(),
                    imageUrl:
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuBNLDpG0BHa75uzY36I-GHzrOMH8SYRgTj1CgrrqHnn3pvLtDhrUE_LoerrHFx6PuuOtPsMZkpPdOyrqMk8mo7sYcA3DUKkz5T3KvqXdLGsbuL3SSnWa7S3vXnChnAdaoP4xxiZ_7LJNrVEE0ouP8mLP7_QFYA6Ph1WWN_ckuHPiDJLGHlXGh2GYgW-7kUSjHIP7ERDHY309xMl_87LZ5gvQDCSA9UbYXdhhEtPeKxWlyrcBhb1OzzhRI9oBfrLTAO9J0D5zUv59g',
                    title: 'Gantiadi\nholiday house',
                    label: 'Upcoming',
                    date: '01 Feb 2020',
                    rating: 4.1,
                    icon: Icons.holiday_village,
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                ImageDisplayCardWidget(
                  size: const WideSize(),
                  inline: true,
                  imageUrl:
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuBNLDpG0BHa75uzY36I-GHzrOMH8SYRgTj1CgrrqHnn3pvLtDhrUE_LoerrHFx6PuuOtPsMZkpPdOyrqMk8mo7sYcA3DUKkz5T3KvqXdLGsbuL3SSnWa7S3vXnChnAdaoP4xxiZ_7LJNrVEE0ouP8mLP7_QFYA6Ph1WWN_ckuHPiDJLGHlXGh2GYgW-7kUSjHIP7ERDHY309xMl_87LZ5gvQDCSA9UbYXdhhEtPeKxWlyrcBhb1OzzhRI9oBfrLTAO9J0D5zUv59g',
                  title: 'Gantiadi Holiday House',
                  label: 'Upcoming Reservation',
                  date: '01 Feb 2020',
                  rating: 4.1,
                  icon: Icons.holiday_village,
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                ImageDisplayCardWidget(
                  size: const Wide2Size(),
                  inline: true,
                  imageUrl:
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuBNLDpG0BHa75uzY36I-GHzrOMH8SYRgTj1CgrrqHnn3pvLtDhrUE_LoerrHFx6PuuOtPsMZkpPdOyrqMk8mo7sYcA3DUKkz5T3KvqXdLGsbuL3SSnWa7S3vXnChnAdaoP4xxiZ_7LJNrVEE0ouP8mLP7_QFYA6Ph1WWN_ckuHPiDJLGHlXGh2GYgW-7kUSjHIP7ERDHY309xMl_87LZ5gvQDCSA9UbYXdhhEtPeKxWlyrcBhb1OzzhRI9oBfrLTAO9J0D5zUv59g',
                  title: 'Gantiadi Holiday House - Premium Stay',
                  label: 'Upcoming Reservation - Highly Rated',
                  date: '01 Feb 2020 - Saturday',
                  rating: 4.1,
                  icon: Icons.holiday_village,
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
