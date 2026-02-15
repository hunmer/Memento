import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/social_activity_card.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/models/social_activity_card_data.dart';

/// 社交活动动态卡片示例
class SocialActivityCardExample extends StatelessWidget {
  const SocialActivityCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('社交活动动态卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: SocialActivityCardWidget(
            size: HomeWidgetSize.large,
            user: SocialUser(
              name: 'Sammy Lawson',
              username: '@CoRay',
              avatarUrl:
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuDzpJQv6FKOjR43geXnHpsz8Npw1GNObnjUa4a3rMQMhzgh_Ve97KVQFW2t3lmVLLpxubY1Ij4YjjtZja3z1gx65I9Z-nhCYBZ9BvLuskC7U8Sw_3XzG0JPVacFep_ILPA18Xzs4yfFMKnCahkfdVUbs02DabzlfaajQAqdlz2HpOOA8RSmsUDDVuvexDm3FSCTBEWNnmqrT3WUQcz0HFRaIGdRRirVYatc5fUOPzltq8H7dNLxkzrbMheMDzFe-Ljb4_HjIBos9A',
              followerCount: 3600,
            ),
            posts: [
              SocialPost(
                hashtag: '#iphone',
                content: 'It\'s incredible to see art, creativity and technology come together in celebration',
                commentCount: 3600,
                repostCount: 12000,
                imageUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuDv-L2GqLDB3xFsxjxb-FZwDal1ZHLI_iIfHb2QF0ikj7mDKw_uXQBE0SDqqd8v_UTM-S3b_TfJP9xvcHVXstPR6dA00hqTl4QXeEzf0w0kkoq6pPgX9wJ-Jyw4TScj-Jxhk4Ztcw8TGBKqEHPm-BkbGvU4YRkJ015N3PSkDQCPbl1Z7sXAFlGv_OCdtMJteF3FeWWI8HgKWhM9oy8E-CGBCfmjdJ6Q1JyYzXk_QkRe7Ml1mIGACbUjWOcUlFhKh6oeuMSF4vYS4Q',
              ),
              SocialPost(
                hashtag: '#technology',
                content: 'The most powerful technology empowers everyone',
                commentCount: 4900,
                repostCount: 14000,
                imageUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuACh19veuHbJJdX79BnZ9ZaBiWnr328sjaUQBL9kSyEcXsvq55v66Dh3qEtWkU1nt6DDmrlTyUg7lQPv9D7dswYcBBEs3JCZn1g0EunLyU0ORUz0yZMOSrsCDJOC9E42OEC_0Ti8L5Ig8lPhgdONolkEb5LCqstFHzsberQnrbMNofpMYxRM2mWwG-9v9y7z7JgT81yAuLt5Tb-SAK1NfMCCOS8VM2bMaHaKluQDJz2_uFHWptoqG66NxwrX7rpca3Z6XxyMvLlYA',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
