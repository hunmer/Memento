import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/rounded_property_card.dart';

/// 圆角属性卡片示例
class RoundedPropertyCardExample extends StatelessWidget {
  const RoundedPropertyCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('圆角属性卡片')),
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
                    width: 280,
                    height: 180,
                    child: RoundedPropertyCardWidget(
                      title: 'A Georgian Masterpiece',
                      imageUrl:
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuC7I66qiADm9mcjQGh_wAlfWQP6o_hcJfNgeDqcih2g1QHBlHCKvyr2pKBHtvA7G9qkBB3ZlP8pV7HlhnjfuPHiGjMPGzWh1xuHfO7v8SfNXgAWZovbI2iz72aJb6Hv7xp-OyHsP6g6c9kEUTGIaMPDQGhQcCFX0vPVzVxyO2S1BOu1b7ivc_pI3JZwjIwM_D1pNiIMj9KZJrNr5K2R8eog0iEFsvVF4TJ1GpdtlCyNpfzLI9iGyc-_WhLEcfYEmXF1DGs_QyUxRg',
                      date: '01 Feb 2020',
                      time: '14:00',
                      temperature: '8° F',
                      description: 'When I first got into the business...',
                      actionLabel: 'Get directions',
                      actionIcon: Icons.my_location,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 320,
                    height: 220,
                    child: RoundedPropertyCardWidget(
                      title: 'A Georgian Masterpiece in the Heart',
                      imageUrl:
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuC7I66qiADm9mcjQGh_wAlfWQP6o_hcJfNgeDqcih2g1QHBlHCKvyr2pKBHtvA7G9qkBB3ZlP8pV7HlhnjfuPHiGjMPGzWh1xuHfO7v8SfNXgAWZovbI2iz72aJb6Hv7xp-OyHsP6g6c9kEUTGIaMPDQGhQcCFX0vPVzVxyO2S1BOu1b7ivc_pI3JZwjIwM_D1pNiIMj9KZJrNr5K2R8eog0iEFsvVF4TJ1GpdtlCyNpfzLI9iGyc-_WhLEcfYEmXF1DGs_QyUxRg',
                      date: '01 Feb 2020',
                      time: '14:00',
                      temperature: '8° F',
                      description: 'When I first got into the advertising business...',
                      actionLabel: 'Get directions',
                      actionIcon: Icons.my_location,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 380,
                    height: 280,
                    child: RoundedPropertyCardWidget(
                      title: 'A Georgian Masterpiece in the Heart of the City',
                      imageUrl:
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuC7I66qiADm9mcjQGh_wAlfWQP6o_hcJfNgeDqcih2g1QHBlHCKvyr2pKBHtvA7G9qkBB3ZlP8pV7HlhnjfuPHiGjMPGzWh1xuHfO7v8SfNXgAWZovbI2iz72aJb6Hv7xp-OyHsP6g6c9kEUTGIaMPDQGhQcCFX0vPVzVxyO2S1BOu1b7ivc_pI3JZwjIwM_D1pNiIMj9KZJrNr5K2R8eog0iEFsvVF4TJ1GpdtlCyNpfzLI9iGyc-_WhLEcfYEmXF1DGs_QyUxRg',
                      date: '01 Feb 2020',
                      time: '14:00',
                      temperature: '8° F',
                      description: 'When I first got into the advertising business, I was looking for the magical combination',
                      actionLabel: 'Get directions',
                      actionIcon: Icons.my_location,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 280,
                  child: RoundedPropertyCardWidget(
                    title: 'A Georgian Masterpiece in the Heart of the City - Premium Property',
                    imageUrl:
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuC7I66qiADm9mcjQGh_wAlfWQP6o_hcJfNgeDqcih2g1QHBlHCKvyr2pKBHtvA7G9qkBB3ZlP8pV7HlhnjfuPHiGjMPGzWh1xuHfO7v8SfNXgAWZovbI2iz72aJb6Hv7xp-OyHsP6g6c9kEUTGIaMPDQGhQcCFX0vPVzVxyO2S1BOu1b7ivc_pI3JZwjIwM_D1pNiIMj9KZJrNr5K2R8eog0iEFsvVF4TJ1GpdtlCyNpfzLI9iGyc-_WhLEcfYEmXF1DGs_QyUxRg',
                    date: '01 Feb 2020',
                    time: '14:00',
                    temperature: '8° F',
                    description: 'When I first got into the advertising business, I was looking for the magical combination that would make my campaigns stand out.',
                    actionLabel: 'Get directions',
                    actionIcon: Icons.my_location,
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 350,
                  child: RoundedPropertyCardWidget(
                    title: 'A Georgian Masterpiece in the Heart of the City - Premium Real Estate Listing',
                    imageUrl:
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuC7I66qiADm9mcjQGh_wAlfWQP6o_hcJfNgeDqcih2g1QHBlHCKvyr2pKBHtvA7G9qkBB3ZlP8pV7HlhnjfuPHiGjMPGzWh1xuHfO7v8SfNXgAWZovbI2iz72aJb6Hv7xp-OyHsP6g6c9kEUTGIaMPDQGhQcCFX0vPVzVxyO2S1BOu1b7ivc_pI3JZwjIwM_D1pNiIMj9KZJrNr5K2R8eog0iEFsvVF4TJ1GpdtlCyNpfzLI9iGyc-_WhLEcfYEmXF1DGs_QyUxRg',
                    date: '01 Feb 2020',
                    time: '14:00',
                    temperature: '8° F',
                    description: 'When I first got into the advertising business, I was looking for the magical combination that would make my campaigns stand out. This beautiful property offers everything you need.',
                    actionLabel: 'Get directions',
                    actionIcon: Icons.my_location,
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
