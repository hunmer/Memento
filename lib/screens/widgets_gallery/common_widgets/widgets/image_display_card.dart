import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 图片展示卡片小组件
///
/// 通用的图片展示卡片组件，支持显示图片、标题、标签、日期和评分
class ImageDisplayCardWidget extends StatefulWidget {
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

  /// 右上角图标
  final IconData? icon;

  /// 主色调（用于评分和标签）
  final Color? primaryColor;

  /// 强调色（用于标签）
  final Color? accentColor;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const ImageDisplayCardWidget({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.label,
    required this.date,
    required this.rating,
    this.icon,
    this.primaryColor,
    this.accentColor,
    this.inline = false,
    this.size = const MediumSize(),
  });

  /// 从 props 创建实例
  factory ImageDisplayCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return ImageDisplayCardWidget(
      imageUrl: props['imageUrl'] as String? ?? '',
      title: props['title'] as String? ?? '',
      label: props['label'] as String? ?? '',
      date: props['date'] as String? ?? '',
      rating: (props['rating'] as num?)?.toDouble() ?? 0.0,
      icon: props['icon'] != null
          ? IconData(props['icon'] as int, fontFamily: 'MaterialIcons')
          : null,
      primaryColor: props['primaryColor'] != null
          ? Color(props['primaryColor'] as int)
          : null,
      accentColor: props['accentColor'] != null
          ? Color(props['accentColor'] as int)
          : null,
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<ImageDisplayCardWidget> createState() =>
      _ImageDisplayCardWidgetState();
}

class _ImageDisplayCardWidgetState extends State<ImageDisplayCardWidget>
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
    final primaryColor = widget.primaryColor ??
        (isDark
            ? const Color(0xFFFBBF24)
            : const Color(0xFFFBBF24)); // Amber-400
    final accentColor = widget.accentColor ??
        (isDark
            ? const Color(0xFFFB923C)
            : const Color(0xFFFB923C)); // Orange-400
    final cardColor =
        isDark ? const Color(0xFF1E293B) : Colors.white; // Slate-800 / White
    final surfaceColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFF3F4F6); // Slate-700 / Gray-100
    final textMainColor = isDark
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF1E293B); // Slate-50 / Slate-800
    final textSubColor = isDark
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
              width: widget.inline ? double.maxFinite : 380,
              height: widget.inline ? double.maxFinite : 200,
              padding: widget.size.getPadding(),
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
                  SizedBox(width: widget.size.getItemSpacing() * 2),

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
            child:
                const Icon(Icons.broken_image, size: 48, color: Colors.grey),
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
            // 标签
            Container(
              margin: EdgeInsets.only(top: widget.size.getItemSpacing() / 2),
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
            if (widget.icon != null)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  size: 18,
                  color: const Color(0xFF94A3B8),
                ),
              ),
          ],
        ),

        SizedBox(height: widget.size.getItemSpacing() / 2),

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
              padding: EdgeInsets.symmetric(
                horizontal: widget.size.getItemSpacing() * 1.5,
                vertical: widget.size.getItemSpacing() * 0.75,
              ),
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
                SizedBox(width: widget.size.getItemSpacing() / 2),
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
