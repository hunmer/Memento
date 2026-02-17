import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/news_card.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/models/news_card_data.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 新闻卡片示例
class NewsCardExample extends StatelessWidget {
  const NewsCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('新闻卡片')),
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
                    width: 150,
                    height: 150,
                    child: NewsCardWidget(
                      inline: true,
                      size: const SmallSize(),
                      featuredNews: FeaturedNewsData(
                        imageUrl:
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuDv5gxvSgmJi-EJnx1jpWIpatry-RBKJyPObZyjHGF4-dpstaoze49i8tJFHbm3FOGPd2LNfrxsIt6W5g4qO1YfXAYs6ZVYy2GA78hSeLg1pAm2khF7Z5hO5NCICS2kSwHjgA5diQ8bCI6-IdSKXJxszm4VL2Fq4uCx3rbOzM_OYO_AO6sFN2ew-KJaE3U3xyYbqX-7Z5P7ippdNtDWdpZDfWXETGhR087NeReVoMb6Xf8_Zf-uQ2kXVzCAKZ4wkiflAg-3sYRMbQ',
                        title:
                            'Hacker Leaks From Netflix Show Threatens Networks',
                      ),
                      category: 'Latest news',
                      newsItems: [
                        NewsItemData(
                          title:
                              'Cody Brown Has a Broad Vision for Virtual Reality',
                          time: '26 hrs ago',
                          imageUrl:
                              'https://lh3.googleusercontent.com/aida-public/AB6AXuA4bhNi8gKGFeCyMYb8-ry8Uf4QLPszrY1ZXtnxdE_kGEUm_kXgutv3zEtoLws1ch65y_Uxq1IJYl4TBe2X4Fg20L8Kma7rJ0VUS5k0fux5ECK4wP8GJC34ODtVLdrtWhus4VDRInJN8NzrM-AcOHHaCEt50tQfwMSD6tQEPaWvaE8ww-EXx1FBYAaU3NLK7UeXg8zblqPPV64qXL_WJnCwMx3WlPTOcZ2nb1wGKl6CUvYaisxupGZyn1QPr2wJvZEh-2KCGgXd1Q',
                        ),
                        NewsItemData(
                          title:
                              'Visa Applications Pour In by Truckload Before Door',
                          time: '29 hrs ago',
                          imageUrl:
                              'https://lh3.googleusercontent.com/aida-public/AB6AXuA_MHiN7St5tuKKxJmnX2fWLFiH1TnKauia8M8rChdMABchAWsC9DhfrFNMP7a1zvbVM6ypKB2R6-ZHnOxWEzHXVxH3uoqNnoAUVNVUQ4SjroiaZuEi6Mj_eQcmBWxtxxRCdgPUW0zzfkNPyNDVqkqSGQ780Yhn-i7xnL1S7ulNFupLPi1fw0f24cgKW92Vo-EanJvPI4nFSsL4PR7K8I2Z6IcdtDssZHs0MLLA6bxTZ5g-gDkg4lpv7cURh3hUI0gnivnNmAoLnA',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: NewsCardWidget(
                      inline: true,
                      size: const MediumSize(),
                      featuredNews: FeaturedNewsData(
                        imageUrl:
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuDv5gxvSgmJi-EJnx1jpWIpatry-RBKJyPObZyjHGF4-dpstaoze49i8tJFHbm3FOGPd2LNfrxsIt6W5g4qO1YfXAYs6ZVYy2GA78hSeLg1pAm2khF7Z5hO5NCICS2kSwHjgA5diQ8bCI6-IdSKXJxszm4VL2Fq4uCx3rbOzM_OYO_AO6sFN2ew-KJaE3U3xyYbqX-7Z5P7ippdNtDWdpZDfWXETGhR087NeReVoMb6Xf8_Zf-uQ2kXVzCAKZ4wkiflAg-3sYRMbQ',
                        title:
                            'Hacker Leaks From Netflix Show Threatens Networks',
                      ),
                      category: 'Latest news',
                      newsItems: [
                        NewsItemData(
                          title:
                              'Cody Brown Has a Broad Vision for Virtual Reality',
                          time: '26 hrs ago',
                          imageUrl:
                              'https://lh3.googleusercontent.com/aida-public/AB6AXuA4bhNi8gKGFeCyMYb8-ry8Uf4QLPszrY1ZXtnxdE_kGEUm_kXgutv3zEtoLws1ch65y_Uxq1IJYl4TBe2X4Fg20L8Kma7rJ0VUS5k0fux5ECK4wP8GJC34ODtVLdrtWhus4VDRInJN8NzrM-AcOHHaCEt50tQfwMSD6tQEPaWvaE8ww-EXx1FBYAaU3NLK7UeXg8zblqPPV64qXL_WJnCwMx3WlPTOcZ2nb1wGKl6CUvYaisxupGZyn1QPr2wJvZEh-2KCGgXd1Q',
                        ),
                        NewsItemData(
                          title:
                              'Visa Applications Pour In by Truckload Before Door',
                          time: '29 hrs ago',
                          imageUrl:
                              'https://lh3.googleusercontent.com/aida-public/AB6AXuA_MHiN7St5tuKKxJmnX2fWLFiH1TnKauia8M8rChdMABchAWsC9DhfrFNMP7a1zvbVM6ypKB2R6-ZHnOxWEzHXVxH3uoqNnoAUVNVUQ4SjroiaZuEi6Mj_eQcmBWxtxxRCdgPUW0zzfkNPyNDVqkqSGQ780Yhn-i7xnL1S7ulNFupLPi1fw0f24cgKW92Vo-EanJvPI4nFSsL4PR7K8I2Z6IcdtDssZHs0MLLA6bxTZ5g-gDkg4lpv7cURh3hUI0gnivnNmAoLnA',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: NewsCardWidget(
                      inline: true,
                      size: const LargeSize(),
                      featuredNews: FeaturedNewsData(
                        imageUrl:
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuDv5gxvSgmJi-EJnx1jpWIpatry-RBKJyPObZyjHGF4-dpstaoze49i8tJFHbm3FOGPd2LNfrxsIt6W5g4qO1YfXAYs6ZVYy2GA78hSeLg1pAm2khF7Z5hO5NCICS2kSwHjgA5diQ8bCI6-IdSKXJxszm4VL2Fq4uCx3rbOzM_OYO_AO6sFN2ew-KJaE3U3xyYbqX-7Z5P7ippdNtDWdpZDfWXETGhR087NeReVoMb6Xf8_Zf-uQ2kXVzCAKZ4wkiflAg-3sYRMbQ',
                        title:
                            'Hacker Leaks From Netflix Show Threatens Networks',
                      ),
                      category: 'Latest news',
                      newsItems: [
                        NewsItemData(
                          title:
                              'Cody Brown Has a Broad Vision for Virtual Reality',
                          time: '26 hrs ago',
                          imageUrl:
                              'https://lh3.googleusercontent.com/aida-public/AB6AXuA4bhNi8gKGFeCyMYb8-ry8Uf4QLPszrY1ZXtnxdE_kGEUm_kXgutv3zEtoLws1ch65y_Uxq1IJYl4TBe2X4Fg20L8Kma7rJ0VUS5k0fux5ECK4wP8GJC34ODtVLdrtWhus4VDRInJN8NzrM-AcOHHaCEt50tQfwMSD6tQEPaWvaE8ww-EXx1FBYAaU3NLK7UeXg8zblqPPV64qXL_WJnCwMx3WlPTOcZ2nb1wGKl6CUvYaisxupGZyn1QPr2wJvZEh-2KCGgXd1Q',
                        ),
                        NewsItemData(
                          title:
                              'Visa Applications Pour In by Truckload Before Door',
                          time: '29 hrs ago',
                          imageUrl:
                              'https://lh3.googleusercontent.com/aida-public/AB6AXuA_MHiN7St5tuKKxJmnX2fWLFiH1TnKauia8M8rChdMABchAWsC9DhfrFNMP7a1zvbVM6ypKB2R6-ZHnOxWEzHXVxH3uoqNnoAUVNVUQ4SjroiaZuEi6Mj_eQcmBWxtxxRCdgPUW0zzfkNPyNDVqkqSGQ780Yhn-i7xnL1S7ulNFupLPi1fw0f24cgKW92Vo-EanJvPI4nFSsL4PR7K8I2Z6IcdtDssZHs0MLLA6bxTZ5g-gDkg4lpv7cURh3hUI0gnivnNmAoLnA',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 320,
                  child: NewsCardWidget(
                    inline: true,
                    size: const WideSize(),
                    featuredNews: FeaturedNewsData(
                      imageUrl:
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuDv5gxvSgmJi-EJnx1jpWIpatry-RBKJyPObZyjHGF4-dpstaoze49i8tJFHbm3FOGPd2LNfrxsIt6W5g4qO1YfXAYs6ZVYy2GA78hSeLg1pAm2khF7Z5hO5NCICS2kSwHjgA5diQ8bCI6-IdSKXJxszm4VL2Fq4uCx3rbOzM_OYO_AO6sFN2ew-KJaE3U3xyYbqX-7Z5P7ippdNtDWdpZDfWXETGhR087NeReVoMb6Xf8_Zf-uQ2kXVzCAKZ4wkiflAg-3sYRMbQ',
                      title:
                          'Hacker Leaks From Netflix Show Threatens Networks and Digital Security',
                    ),
                    category: 'Latest News and Updates',
                    newsItems: [
                      NewsItemData(
                        title:
                            'Cody Brown Has a Broad Vision for Virtual Reality and Future Technology',
                        time: '26 hrs ago',
                        imageUrl:
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuA4bhNi8gKGFeCyMYb8-ry8Uf4QLPszrY1ZXtnxdE_kGEUm_kXgutv3zEtoLws1ch65y_Uxq1IJYl4TBe2X4Fg20L8Kma7rJ0VUS5k0fux5ECK4wP8GJC34ODtVLdrtWhus4VDRInJN8NzrM-AcOHHaCEt50tQfwMSD6tQEPaWvaE8ww-EXx1FBYAaU3NLK7UeXg8zblqPPV64qXL_WJnCwMx3WlPTOcZ2nb1wGKl6CUvYaisxupGZyn1QPr2wJvZEh-2KCGgXd1Q',
                      ),
                      NewsItemData(
                        title:
                            'Visa Applications Pour In by Truckload Before Door Closes',
                        time: '29 hrs ago',
                        imageUrl:
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuA_MHiN7St5tuKKxJmnX2fWLFiH1TnKauia8M8rChdMABchAWsC9DhfrFNMP7a1zvbVM6ypKB2R6-ZHnOxWEzHXVxH3uoqNnoAUVNVUQ4SjroiaZuEi6Mj_eQcmBWxtxxRCdgPUW0zzfkNPyNDVqkqSGQ780Yhn-i7xnL1S7ulNFupLPi1fw0f24cgKW92Vo-EanJvPI4nFSsL4PR7K8I2Z6IcdtDssZHs0MLLA6bxTZ5g-gDkg4lpv7cURh3hUI0gnivnNmAoLnA',
                      ),
                      NewsItemData(
                        title:
                            'Global Technology Summit Announces New Innovation Awards',
                        time: '32 hrs ago',
                        imageUrl:
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuDv5gxvSgmJi-EJnx1jpWIpatry-RBKJyPObZyjHGF4-dpstaoze49i8tJFHbm3FOGPd2LNfrxsIt6W5g4qO1YfXAYs6ZVYy2GA78hSeLg1pAm2khF7Z5hO5NCICS2kSwHjgA5diQ8bCI6-IdSKXJxszm4VL2Fq4uCx3rbOzM_OYO_AO6sFN2ew-KJaE3U3xyYbqX-7Z5P7ippdNtDWdpZDfWXETGhR087NeReVoMb6Xf8_Zf-uQ2kXVzCAKZ4wkiflAg-3sYRMbQ',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 420,
                  child: NewsCardWidget(
                    inline: true,
                    size: const Wide2Size(),
                    featuredNews: FeaturedNewsData(
                      imageUrl:
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuDv5gxvSgmJi-EJnx1jpWIpatry-RBKJyPObZyjHGF4-dpstaoze49i8tJFHbm3FOGPd2LNfrxsIt6W5g4qO1YfXAYs6ZVYy2GA78hSeLg1pAm2khF7Z5hO5NCICS2kSwHjgA5diQ8bCI6-IdSKXJxszm4VL2Fq4uCx3rbOzM_OYO_AO6sFN2ew-KJaE3U3xyYbqX-7Z5P7ippdNtDWdpZDfWXETGhR087NeReVoMb6Xf8_Zf-uQ2kXVzCAKZ4wkiflAg-3sYRMbQ',
                      title:
                          'Hacker Leaks From Netflix Show Threatens Networks and Global Digital Security',
                    ),
                    category: 'Latest News and Breaking Updates',
                    newsItems: [
                      NewsItemData(
                        title:
                            'Cody Brown Has a Broad Vision for Virtual Reality and Future Technology',
                        time: '26 hrs ago',
                        imageUrl:
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuA4bhNi8gKGFeCyMYb8-ry8Uf4QLPszrY1ZXtnxdE_kGEUm_kXgutv3zEtoLws1ch65y_Uxq1IJYl4TBe2X4Fg20L8Kma7rJ0VUS5k0fux5ECK4wP8GJC34ODtVLdrtWhus4VDRInJN8NzrM-AcOHHaCEt50tQfwMSD6tQEPaWvaE8ww-EXx1FBYAaU3NLK7UeXg8zblqPPV64qXL_WJnCwMx3WlPTOcZ2nb1wGKl6CUvYaisxupGZyn1QPr2wJvZEh-2KCGgXd1Q',
                      ),
                      NewsItemData(
                        title:
                            'Visa Applications Pour In by Truckload Before Door Closes',
                        time: '29 hrs ago',
                        imageUrl:
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuA_MHiN7St5tuKKxJmnX2fWLFiH1TnKauia8M8rChdMABchAWsC9DhfrFNMP7a1zvbVM6ypKB2R6-ZHnOxWEzHXVxH3uoqNnoAUVNVUQ4SjroiaZuEi6Mj_eQcmBWxtxxRCdgPUW0zzfkNPyNDVqkqSGQ780Yhn-i7xnL1S7ulNFupLPi1fw0f24cgKW92Vo-EanJvPI4nFSsL4PR7K8I2Z6IcdtDssZHs0MLLA6bxTZ5g-gDkg4lpv7cURh3hUI0gnivnNmAoLnA',
                      ),
                      NewsItemData(
                        title:
                            'Global Technology Summit Announces New Innovation Awards and Winners',
                        time: '32 hrs ago',
                        imageUrl:
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuDv5gxvSgmJi-EJnx1jpWIpatry-RBKJyPObZyjHGF4-dpstaoze49i8tJFHbm3FOGPd2LNfrxsIt6W5g4qO1YfXAYs6ZVYy2GA78hSeLg1pAm2khF7Z5hO5NCICS2kSwHjgA5diQ8bCI6-IdSKXJxszm4VL2Fq4uCx3rbOzM_OYO_AO6sFN2ew-KJaE3U3xyYbqX-7Z5P7ippdNtDWdpZDfWXETGhR087NeReVoMb6Xf8_Zf-uQ2kXVzCAKZ4wkiflAg-3sYRMbQ',
                      ),
                      NewsItemData(
                        title:
                            'Breaking: New AI Regulations Passed by International Technology Council',
                        time: '35 hrs ago',
                        imageUrl:
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuA4bhNi8gKGFeCyMYb8-ry8Uf4QLPszrY1ZXtnxdE_kGEUm_kXgutv3zEtoLws1ch65y_Uxq1IJYl4TBe2X4Fg20L8Kma7rJ0VUS5k0fux5ECK4wP8GJC34ODtVLdrtWhus4VDRInJN8NzrM-AcOHHaCEt50tQfwMSD6tQEPaWvaE8ww-EXx1FBYAaU3NLK7UeXg8zblqPPV64qXL_WJnCwMx3WlPTOcZ2nb1wGKl6CUvYaisxupGZyn1QPr2wJvZEh-2KCGgXd1Q',
                      ),
                    ],
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
