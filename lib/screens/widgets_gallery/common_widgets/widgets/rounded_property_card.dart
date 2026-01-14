import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 属性元数据项
class PropertyMetadataItem {
  final IconData icon;
  final String label;

  const PropertyMetadataItem({
    required this.icon,
    required this.label,
  });

  factory PropertyMetadataItem.fromJson(Map<String, dynamic> json) {
    return PropertyMetadataItem(
      icon: _iconFromString(json['icon'] as String? ?? ''),
      label: json['label'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'icon': _iconToString(icon), 'label': label};
  }

  static IconData _iconFromString(String iconString) {
    // 简单的图标映射，实际使用中可以扩展
    switch (iconString) {
      case 'Icons.calendar_today':
        return Icons.calendar_today;
      case 'Icons.schedule':
        return Icons.schedule;
      case 'Icons.cloud_queue':
        return Icons.cloud_queue;
      default:
        return Icons.info;
    }
  }

  static String _iconToString(IconData icon) {
    // 简单的图标映射，实际使用中可以扩展
    if (icon == Icons.calendar_today) return 'Icons.calendar_today';
    if (icon == Icons.schedule) return 'Icons.schedule';
    if (icon == Icons.cloud_queue) return 'Icons.cloud_queue';
    return 'Icons.info';
  }
}

/// 圆角属性卡片小组件
class RoundedPropertyCardWidget extends StatefulWidget {
  final String title;
  final String imageUrl;
  final String date;
  final String time;
  final String temperature;
  final String description;
  final String actionLabel;
  final IconData actionIcon;
  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  const RoundedPropertyCardWidget({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.date,
    required this.time,
    required this.temperature,
    required this.description,
    required this.actionLabel,
    required this.actionIcon,
    this.inline = false,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory RoundedPropertyCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return RoundedPropertyCardWidget(
      title: props['title'] as String? ?? '',
      imageUrl: props['imageUrl'] as String? ?? '',
      date: props['date'] as String? ?? '',
      time: props['time'] as String? ?? '',
      temperature: props['temperature'] as String? ?? '',
      description: props['description'] as String? ?? '',
      actionLabel: props['actionLabel'] as String? ?? '',
      actionIcon: PropertyMetadataItem._iconFromString(props['actionIcon'] as String? ?? 'Icons.my_location'),
      inline: props['inline'] as bool? ?? false,
    );
  }

  @override
  State<RoundedPropertyCardWidget> createState() => _RoundedPropertyCardWidgetState();
}

class _RoundedPropertyCardWidgetState extends State<RoundedPropertyCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _slideAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
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

    // 使用主题颜色
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cardBackgroundColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    const secondaryTextColor = Color(0xFF9CA3AF);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Container(
              width: widget.inline ? double.maxFinite : 340,
              decoration: BoxDecoration(
                color: cardBackgroundColor,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 顶部图片区域
                    _buildImageSection(isDark),

                    // 内容区域
                    _buildContentSection(
                      context,
                      isDark,
                      primaryColor,
                      textColor,
                      secondaryTextColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageSection(bool isDark) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F7),
      ),
      child: FadeInImage(
        placeholder: MemoryImage(kTransparentImage),
        image: NetworkImage(widget.imageUrl),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        imageErrorBuilder: (context, error, stackTrace) {
          return Container(
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F7),
            child: Icon(
              Icons.image_outlined,
              size: 64,
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
          );
        },
      ),
    );
  }

  Widget _buildContentSection(
    BuildContext context,
    bool isDark,
    Color primaryColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: textColor,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          // 元数据行
          _buildMetadataRow(isDark, secondaryTextColor),
          const SizedBox(height: 16),

          // 描述文本
          Text(
            widget.description,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280),
              height: 1.6,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),

          // 操作按钮
          _buildActionButton(primaryColor),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(bool isDark, Color secondaryTextColor) {
    final metadataItems = [
      PropertyMetadataItem(icon: Icons.calendar_today, label: widget.date),
      PropertyMetadataItem(icon: Icons.schedule, label: widget.time),
      PropertyMetadataItem(icon: Icons.cloud_queue, label: widget.temperature),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: metadataItems.map((item) {
        return _MetadataItemWidget(
          icon: item.icon,
          label: item.label,
          isDark: isDark,
          textColor: secondaryTextColor,
          animation: _animationController,
        );
      }).toList(),
    );
  }

  Widget _buildActionButton(Color primaryColor) {
    return InkWell(
      onTap: () {
        // TODO: 实现导航逻辑
      },
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.actionIcon,
            size: 20,
            color: primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            widget.actionLabel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// 元数据项组件
class _MetadataItemWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final Color textColor;
  final Animation<double> animation;

  const _MetadataItemWidget({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.textColor,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: textColor,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: textColor,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

/// 透明图片占位符
final Uint8List kTransparentImage = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);
