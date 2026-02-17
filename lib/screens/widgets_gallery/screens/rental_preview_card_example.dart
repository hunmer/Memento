import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/rental_preview_card.dart';

/// 租赁预览卡片示例
class RentalPreviewCardExample extends StatelessWidget {
  const RentalPreviewCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('租赁预览卡片')),
      body: Container(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
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
                    child: RentalPreviewCardWidget(
                      size: const SmallSize(),
                      imageUrl:
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuCy3FkoYOsBs67DoRSkHacGbAGIW_MrSaQUShJ5cE4hq150_S3cORrNLnScjj_6NAvzQQ7_DRqUhmCQMfI0xNnHtiVuG1mHXIW6W9RyB7_PYEY9BXJmSA4duqZjRBcBid60ho_UZ8NfhC3BZV4AhPbES6hhOklhdA_1PtpNoftcr5YBiA4TWOpNdoVIwijmT5LQ_3r3wMHn4Cl3umkfGgOywaAP5EE7htELBy7uvKtoSqoVNrXyIbhg1szVZo5RYHmcGaKNIEcFyg',
                      status: '即将到来',
                      rating: 4.1,
                      title: 'Gantiadi holiday house',
                      description: '当我第一次进入广告业务时',
                      date: '2020年2月1日',
                      duration: '4小时 38分钟',
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
                    child: RentalPreviewCardWidget(
                      size: const MediumSize(),
                      imageUrl:
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuCy3FkoYOsBs67DoRSkHacGbAGIW_MrSaQUShJ5cE4hq150_S3cORrNLnScjj_6NAvzQQ7_DRqUhmCQMfI0xNnHtiVuG1mHXIW6W9RyB7_PYEY9BXJmSA4duqZjRBcBid60ho_UZ8NfhC3BZV4AhPbES6hhOklhdA_1PtpNoftcr5YBiA4TWOpNdoVIwijmT5LQ_3r3wMHn4Cl3umkfGgOywaAP5EE7htELBy7uvKtoSqoVNrXyIbhg1szVZo5RYHmcGaKNIEcFyg',
                      status: '即将到来',
                      rating: 4.1,
                      title: 'Gantiadi holiday house',
                      description: '当我第一次进入广告业务时，我正在寻找神奇的组合',
                      date: '2020年2月1日',
                      duration: '4小时 38分钟',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 280,
                    child: RentalPreviewCardWidget(
                      size: const LargeSize(),
                      imageUrl:
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuCy3FkoYOsBs67DoRSkHacGbAGIW_MrSaQUShJ5cE4hq150_S3cORrNLnScjj_6NAvzQQ7_DRqUhmCQMfI0xNnHtiVuG1mHXIW6W9RyB7_PYEY9BXJmSA4duqZjRBcBid60ho_UZ8NfhC3BZV4AhPbES6hhOklhdA_1PtpNoftcr5YBiA4TWOpNdoVIwijmT5LQ_3r3wMHn4Cl3umkfGgOywaAP5EE7htELBy7uvKtoSqoVNrXyIbhg1szVZo5RYHmcGaKNIEcFyg',
                      status: '即将到来',
                      rating: 4.1,
                      title: 'Gantiadi holiday house',
                      description: '当我第一次进入广告业务时，我正在寻找神奇的组合，让我的创意能够触达更广泛的受众。',
                      date: '2020年2月1日',
                      duration: '4小时 38分钟',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 280,
                  child: RentalPreviewCardWidget(
                    size: const WideSize(),
                    inline: true,
                    imageUrl:
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuCy3FkoYOsBs67DoRSkHacGbAGIW_MrSaQUShJ5cE4hq150_S3cORrNLnScjj_6NAvzQQ7_DRqUhmCQMfI0xNnHtiVuG1mHXIW6W9RyB7_PYEY9BXJmSA4duqZjRBcBid60ho_UZ8NfhC3BZV4AhPbES6hhOklhdA_1PtpNoftcr5YBiA4TWOpNdoVIwijmT5LQ_3r3wMHn4Cl3umkfGgOywaAP5EE7htELBy7uvKtoSqoVNrXyIbhg1szVZo5RYHmcGaKNIEcFyg',
                    status: '即将到来',
                    rating: 4.1,
                    title: 'Gantiadi Holiday House - Beautiful Retreat',
                    description:
                        '当我第一次进入广告业务时，我正在寻找神奇的组合，让我的创意能够触达更广泛的受众。这是一个完美的度假胜地。',
                    date: '2020年2月1日',
                    duration: '4小时 38分钟',
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 350,
                  child: RentalPreviewCardWidget(
                    size: const Wide2Size(),
                    inline: true,
                    imageUrl:
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuCy3FkoYOsBs67DoRSkHacGbAGIW_MrSaQUShJ5cE4hq150_S3cORrNLnScjj_6NAvzQQ7_DRqUhmCQMfI0xNnHtiVuG1mHXIW6W9RyB7_PYEY9BXJmSA4duqZjRBcBid60ho_UZ8NfhC3BZV4AhPbES6hhOklhdA_1PtpNoftcr5YBiA4TWOpNdoVIwijmT5LQ_3r3wMHn4Cl3umkfGgOywaAP5EE7htELBy7uvKtoSqoVNrXyIbhg1szVZo5RYHmcGaKNIEcFyg',
                    status: '即将到来',
                    rating: 4.1,
                    title:
                        'Gantiadi Holiday House - Beautiful Retreat in Nature',
                    description:
                        '当我第一次进入广告业务时，我正在寻找神奇的组合，让我的创意能够触达更广泛的受众。这个度假屋提供了完美的放松体验，拥有宽敞的空间和优美的自然环境。',
                    date: '2020年2月1日',
                    duration: '4小时 38分钟',
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
