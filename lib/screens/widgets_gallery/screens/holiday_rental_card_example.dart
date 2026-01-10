import 'package:flutter/material.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';

/// 假期租赁卡片示例
class HolidayRentalCardExample extends StatelessWidget {
  const HolidayRentalCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('假期租赁卡片')),
      body: Container(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFF64748B),
        child: const Center(
          child: HolidayRentalCardWidget(
            imageUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuBNLDpG0BHa75uzY36I-GHzrOMH8SYRgTj1CgrrqHnn3pvLtDhrUE_LoerrHFx6PuuOtPsMZkpPdOyrqMk8mo7sYcA3DUKkz5T3KvqXdLGsbuL3SSnWa7S3vXnChnAdaoP4xxiZ_7LJNrVEE0ouP8mLP7_QFYA6Ph1WWN_ckuHPiDJLGHlXGh2GYgW-7kUSjHIP7ERDHY309xMl_87LZ5gvQDCSA9UbYXdhhEtPeKxWlyrcBhb1OzzhRI9oBfrLTAO9J0D5zUv59g',
            title: 'Gantiadi\nholiday house',
            label: 'Upcoming',
            date: '01 Feb 2020',
            rating: 4.1,
          ),
        ),
      ),
    );
  }
}

/// 假期租赁卡片小组件
class HolidayRentalCardWidget extends StatefulWidget {
  /// 图片 URL
  final String imageUrl;

  /// 标题（支持换行）
  final String title;

  /// 标签文本（如 "Upcoming"）
  final String label;

  /// 日期文本
  final String date;

  /// 评分（0-5）
  final double rating;

  const HolidayRentalCardWidget({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.label,
    required this.date,
    required this.rating,
  });

  @override
  State<HolidayRentalCardWidget> createState() =>
      _HolidayRentalCardWidgetState();
}

class _HolidayRentalCardWidgetState extends State<HolidayRentalCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 主题颜色
    final primaryColor =
        isDark ? const Color(0xFFFBBF24) : const Color(0xFFFBBF24); // Amber-400
    final accentColor =
        isDark
            ? const Color(0xFFFB923C)
            : const Color(0xFFFB923C); // Orange-400
    final cardColor =
        isDark ? const Color(0xFF1E293B) : Colors.white; // Slate-800 / White
    final surfaceColor =
        isDark
            ? const Color(0xFF334155)
            : const Color(0xFFF3F4F6); // Slate-700 / Gray-100
    final textMainColor =
        isDark
            ? const Color(0xFFF8FAFC)
            : const Color(0xFF1E293B); // Slate-50 / Slate-800
    final textSubColor =
        isDark
            ? const Color(0xFFCBD5E1)
            : const Color(0xFF94A3B8); // Slate-300 / Slate-400

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _animation.value)),
          child: Opacity(
            opacity: _animation.value,
            child: Container(
              width: 380,
              height: 200,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 左侧图片区域
                  _buildImageArea(isDark: isDark),
                  const SizedBox(width: 16),

                  // 右侧信息区域
                  Expanded(
                    child: _buildInfoArea(
                      isDark: isDark,
                      primaryColor: primaryColor,
                      accentColor: accentColor,
                      surfaceColor: surfaceColor,
                      textMainColor: textMainColor,
                      textSubColor: textSubColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 左侧图片区域
  Widget _buildImageArea({required bool isDark}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Image.network(
        widget.imageUrl,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 120,
            height: 120,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF3F4F6),
            child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
          );
        },
      ),
    );
  }

  /// 右侧信息区域
  Widget _buildInfoArea({
    required bool isDark,
    required Color primaryColor,
    required Color accentColor,
    required Color surfaceColor,
    required Color textMainColor,
    required Color textSubColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 顶部：标签 + 图标
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Upcoming 标签
            Container(
              margin: const EdgeInsets.only(top: 4),
              child: Text(
                widget.label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.15 * 3, // 0.15em ≈ 3px
                  color: accentColor,
                ),
              ),
            ),

            // 图标按钮
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: surfaceColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.holiday_village,
                size: 18,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        // 标题
        Text(
          widget.title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: textMainColor,
            height: 1.2,
          ),
        ),

        const Spacer(),

        // 底部：日期 + 评分
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 日期标签
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.date,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: textSubColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            // 评分
            Row(
              children: [
                Icon(Icons.star, size: 18, color: primaryColor),
                const SizedBox(width: 4),
                SizedBox(
                  height: 18,
                  child: Center(
                    child: Text(
                      widget.rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
