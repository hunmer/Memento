import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/vertical_property_card.dart';

/// 垂直属性卡片示例
class VerticalPropertyCardExample extends StatelessWidget {
  const VerticalPropertyCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('垂直属性卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: VerticalPropertyCardWidget(
            imageUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuC7I66qiADm9mcjQGh_wAlfWQP6o_hcJfNgeDqcih2g1QHBlHCKvyr2pKBHtvA7G9qkBB3ZlP8pV7HlhnjfuPHiGjMPGzWh1xuHfO7v8SfNXgAWZovbI2iz72aJb6Hv7xp-OyHsP6g6c9kEUTGIaMPDQGhQcCFX0vPVzVxyO2S1BOu1b7ivc_pI3JZwjIwM_D1pNiIMj9KZJrNr5K2R8eog0iEFsvVF4TJ1GpdtlCyNpfzLI9iGyc-_WhLEcfYEmXF1DGs_QyUxRg',
            title: 'A Georgian Masterpiece in the Heart',
            metadata: [
              PropertyMetadata(icon: Icons.calendar_today, label: '01 Feb 2020'),
              PropertyMetadata(icon: Icons.schedule, label: '14:00'),
              PropertyMetadata(icon: Icons.cloud_queue, label: '8° F'),
            ],
            description:
                'When I first got into the advertising business, I was looking for the magical combination',
            actionLabel: 'Get directions',
            actionIcon: Icons.my_location,
          ),
        ),
      ),
    );
  }
}
