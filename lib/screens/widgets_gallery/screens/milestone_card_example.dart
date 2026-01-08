import 'package:flutter/material.dart';

/// 里程碑追踪卡片示例
class MilestoneCardExample extends StatelessWidget {
  const MilestoneCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('里程碑追踪卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: MilestoneCardWidget(
            imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCPuaYriTNZj_aRzOEEhoGRXOuhwyTTRssklQfbQOrtJLboxJj5BPDtQEJiouPbdl8Fyf1fkcO8kDgVUHaWkC2LL_Bwz4NPa-dxLcKp8bNYV6gp7HNf3YCUHbbh6lxYHU2gAfc3Ot1wO6PnfgQAZBwkTNwBYpsrGjTZ9WaQ8TH57VZvwvg2ranIpItpDK_gZRyiBnzHsmJ0CQS6SC1J6PhC05_JOHWl2k63hPclOmqBLBdQArbrj_9drOSPIcDt6ltyq7-Bq-pHDiNW',
            title: "Will's life",
            date: 'July 21, 2020',
            daysCount: 129,
            value: '0.46',
            unit: 'years',
            suffix: 'old',
          ),
        ),
      ),
    );
  }
}

/// 里程碑追踪小组件
class MilestoneCardWidget extends StatelessWidget {
  /// 头像图片 URL
  final String imageUrl;

  /// 标题
  final String title;

  /// 日期文本
  final String date;

  /// 天数
  final int daysCount;

  /// 大号显示的数值
  final String value;

  /// 数值单位
  final String unit;

  /// 数值后缀
  final String suffix;

  const MilestoneCardWidget({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.date,
    required this.daysCount,
    required this.value,
    required this.unit,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 颜色定义
    const backgroundColorLight = Color(0xFFFFFFFF);
    const backgroundColorDark = Color(0xFF151517);
    const limeTextLight = Color(0xFF4D7C0F);
    const limeTextDark = Color(0xFFD9F99D);
    const blueTextLight = Color(0xFF4F46E5);
    const blueTextDark = Color(0xFFA5B4FC);
    const secondaryTextLight = Color(0xFF6B7280);
    const secondaryTextDark = Color(0xFF9CA3AF);
    const tertiaryTextDark = Color(0xFF6B7280);

    final backgroundColor = isDark ? backgroundColorDark : backgroundColorLight;
    final titleColor = isDark ? limeTextDark : limeTextLight;
    final dateColor = isDark ? secondaryTextDark : secondaryTextLight;
    final valueColor = isDark ? blueTextDark : blueTextLight;
    final unitColor = isDark ? tertiaryTextDark : secondaryTextLight;
    final ringColor = isDark ? Colors.white10 : const Color(0xFFF3F4F6);

    return Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(36),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: ringColor,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.person, size: 32),
                    );
                  },
                ),
              ),
            ),
          ),

          // 标题和日期
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 21.6, // 1.35rem
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$date · $daysCount days',
                style: TextStyle(
                  fontSize: 12.8, // 0.8rem
                  fontWeight: FontWeight.w500,
                  color: dateColor,
                  height: 1.1,
                ),
              ),
            ],
          ),

          // 大号数值和单位
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 67.2, // 4.2rem
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                  height: 0.85,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      unit,
                      style: TextStyle(
                        fontSize: 14.4, // 0.9rem
                        fontWeight: FontWeight.w600,
                        color: unitColor,
                        height: 1,
                      ),
                    ),
                    if (suffix.isNotEmpty)
                      Text(
                        suffix,
                        style: TextStyle(
                          fontSize: 14.4,
                          fontWeight: FontWeight.w600,
                          color: unitColor,
                          height: 1,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
