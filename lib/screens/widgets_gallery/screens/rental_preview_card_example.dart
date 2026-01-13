import 'package:flutter/material.dart';
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
        child: const Center(
          child: RentalPreviewCardWidget(
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
    );
  }
}
