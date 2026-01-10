import 'package:flutter/material.dart';

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

/// 租赁预览卡片小组件
class RentalPreviewCardWidget extends StatefulWidget {
  /// 图片URL
  final String imageUrl;

  /// 状态标签
  final String status;

  /// 评分
  final double rating;

  /// 标题
  final String title;

  /// 描述文本
  final String description;

  /// 日期
  final String date;

  /// 时长
  final String duration;

  const RentalPreviewCardWidget({
    super.key,
    required this.imageUrl,
    required this.status,
    required this.rating,
    required this.title,
    required this.description,
    required this.date,
    required this.duration,
  });

  @override
  State<RentalPreviewCardWidget> createState() =>
      _RentalPreviewCardWidgetState();
}

class _RentalPreviewCardWidgetState extends State<RentalPreviewCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeInAnimation = CurvedAnimation(
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

    return AnimatedBuilder(
      animation: _fadeInAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeInAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _fadeInAnimation.value)),
            child: child,
          ),
        );
      },
      child: Container(
        width: 340,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              offset: const Offset(0, 20),
              blurRadius: 40,
              spreadRadius: -10,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSection(context, isDark),
              const SizedBox(height: 16),
              _buildInfoSection(context, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context, bool isDark) {
    return SizedBox(
      height: 192,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              child: Image.network(
                widget.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color:
                        isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                    child: const Icon(
                      Icons.home_work_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? const Color(0xFF1F2937).withOpacity(0.95)
                        : Colors.white.withOpacity(0.95),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.home_work,
                color: Color(0xFFF43F5E),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.status.toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Color(0xFFFBBF24), size: 14),
                  const SizedBox(width: 2),
                  Text(
                    widget.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Color(0xFFFBBF24),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.title,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF111827),
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            widget.description,
            style: TextStyle(
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              fontSize: 12,
              height: 1.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? const Color(0xFF374151).withOpacity(0.6)
                          : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.date,
                  style: TextStyle(
                    color:
                        isDark
                            ? const Color(0xFFD1D5DB)
                            : const Color(0xFF6B7280),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.schedule,
                    color: Color(0xFF9CA3AF),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.duration,
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
