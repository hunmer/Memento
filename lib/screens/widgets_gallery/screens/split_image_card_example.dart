import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/split_image_card.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

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
                    child: SplitImageCardWidget(
                      imageUrl:
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuCIUN5u7_vXAmPtmC1n8CohO3eS0nZOPxCdcvHkmt1gIycehc3bA86brIYWSrJTWE6Wix61_MBSRyWe1uhT0fDO3PsKCQ3_BWhVESA4KhsovB-7V2yyRmartUzJ7Y-4imptSg_sOYJby5zQl_Nh7CLA6YSu-JvkZlW3V0aF1_x4aq5RKTHGwdFl9qEfHNSpTlpcmytGbAH2zOMnzAPVbgRmf4i8ef0MhxwxconBvFNmKy3QE5BzUvw5s8EDAwiCwlO_MrtTXCrvyA',
                      topIcon: Icons.schedule,
                      topText: '14:00',
                      title: 'Georgian Masterpiece',
                      bottomIcon: Icons.calendar_today,
                      bottomText: '01 Feb 2020',
                      size: const SmallSize(),
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
                    child: SplitImageCardWidget(
                      imageUrl:
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuCIUN5u7_vXAmPtmC1n8CohO3eS0nZOPxCdcvHkmt1gIycehc3bA86brIYWSrJTWE6Wix61_MBSRyWe1uhT0fDO3PsKCQ3_BWhVESA4KhsovB-7V2yyRmartUzJ7Y-4imptSg_sOYJby5zQl_Nh7CLA6YSu-JvkZlW3V0aF1_x4aq5RKTHGwdFl9qEfHNSpTlpcmytGbAH2zOMnzAPVbgRmf4i8ef0MhxwxconBvFNmKy3QE5BzUvw5s8EDAwiCwlO_MrtTXCrvyA',
                      topIcon: Icons.schedule,
                      topText: '14:00',
                      title: 'A Georgian Masterpiece',
                      bottomIcon: Icons.calendar_today,
                      bottomText: '01 Feb 2020',
                      size: const MediumSize(),
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
                    child: SplitImageCardWidget(
                      imageUrl:
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuCIUN5u7_vXAmPtmC1n8CohO3eS0nZOPxCdcvHkmt1gIycehc3bA86brIYWSrJTWE6Wix61_MBSRyWe1uhT0fDO3PsKCQ3_BWhVESA4KhsovB-7V2yyRmartUzJ7Y-4imptSg_sOYJby5zQl_Nh7CLA6YSu-JvkZlW3V0aF1_x4aq5RKTHGwdFl9qEfHNSpTlpcmytGbAH2zOMnzAPVbgRmf4i8ef0MhxwxconBvFNmKy3QE5BzUvw5s8EDAwiCwlO_MrtTXCrvyA',
                      topIcon: Icons.schedule,
                      topText: '14:00',
                      title: 'A Georgian Masterpiece in the Heart',
                      bottomIcon: Icons.calendar_today,
                      bottomText: '01 Feb 2020',
                      size: const LargeSize(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 280,
                  child: SplitImageCardWidget(
                    imageUrl:
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuCIUN5u7_vXAmPtmC1n8CohO3eS0nZOPxCdcvHkmt1gIycehc3bA86brIYWSrJTWE6Wix61_MBSRyWe1uhT0fDO3PsKCQ3_BWhVESA4KhsovB-7V2yyRmartUzJ7Y-4imptSg_sOYJby5zQl_Nh7CLA6YSu-JvkZlW3V0aF1_x4aq5RKTHGwdFl9qEfHNSpTlpcmytGbAH2zOMnzAPVbgRmf4i8ef0MhxwxconBvFNmKy3QE5BzUvw5s8EDAwiCwlO_MrtTXCrvyA',
                    topIcon: Icons.schedule,
                    topText: '14:00',
                    title: 'A Georgian Masterpiece in the Heart of the City',
                    bottomIcon: Icons.calendar_today,
                    bottomText: '01 Feb 2020',
                    size: const WideSize(),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 350,
                  child: SplitImageCardWidget(
                    imageUrl:
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuCIUN5u7_vXAmPtmC1n8CohO3eS0nZOPxCdcvHkmt1gIycehc3bA86brIYWSrJTWE6Wix61_MBSRyWe1uhT0fDO3PsKCQ3_BWhVESA4KhsovB-7V2yyRmartUzJ7Y-4imptSg_sOYJby5zQl_Nh7CLA6YSu-JvkZlW3V0aF1_x4aq5RKTHGwdFl9qEfHNSpTlpcmytGbAH2zOMnzAPVbgRmf4i8ef0MhxwxconBvFNmKy3QE5BzUvw5s8EDAwiCwlO_MrtTXCrvyA',
                    topIcon: Icons.schedule,
                    topText: '14:00 - 18:00',
                    title:
                        'A Georgian Masterpiece in the Heart of the City - Premium Property',
                    bottomIcon: Icons.calendar_today,
                    bottomText: '01 Feb 2020 - Saturday',
                    size: const Wide2Size(),
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
