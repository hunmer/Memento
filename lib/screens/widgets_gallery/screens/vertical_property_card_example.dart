import 'package:flutter/material.dart';

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

/// 属性元数据模型
class PropertyMetadata {
  final IconData icon;
  final String label;

  const PropertyMetadata({
    required this.icon,
    required this.label,
  });
}

/// 垂直属性卡片小组件
class VerticalPropertyCardWidget extends StatefulWidget {
  /// 图片URL
  final String imageUrl;

  /// 标题
  final String title;

  /// 元数据列表（图标+文字）
  final List<PropertyMetadata> metadata;

  /// 描述文本
  final String description;

  /// 操作标签
  final String actionLabel;

  /// 操作图标
  final IconData actionIcon;

  const VerticalPropertyCardWidget({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.metadata,
    required this.description,
    required this.actionLabel,
    required this.actionIcon,
  });

  @override
  State<VerticalPropertyCardWidget> createState() =>
      _VerticalPropertyCardWidgetState();
}

class _VerticalPropertyCardWidgetState
    extends State<VerticalPropertyCardWidget>
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
    final primaryColor = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
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
              color: Colors.black.withOpacity(0.1),
              blurRadius: 40,
              offset: const Offset(0, 20),
              spreadRadius: -5,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: -5,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部图片
            _buildImageSection(isDark),
            // 内容区域
            _buildContentSection(context, isDark, primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(bool isDark) {
    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEEF2FF),
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: _animation.value,
              child: child,
            ),
          );
        },
        child: Image.network(
          widget.imageUrl,
          width: double.infinity,
          height: 240,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEEF2FF),
              child: const Center(
                child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEEF2FF),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContentSection(BuildContext context, bool isDark, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          _buildTitle(isDark),
          const SizedBox(height: 12),
          // 元数据行
          _buildMetadataRow(isDark),
          const SizedBox(height: 16),
          // 描述文本
          _buildDescription(isDark),
          const SizedBox(height: 24),
          // 操作按钮
          _buildActionButton(primaryColor),
        ],
      ),
    );
  }

  Widget _buildTitle(bool isDark) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final itemAnimation = CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.15, 0.75, curve: Curves.easeOutCubic),
        );
        return Opacity(
          opacity: itemAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - itemAnimation.value)),
            child: child,
          ),
        );
      },
      child: Text(
        widget.title,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          height: 1.2,
          color: isDark ? Colors.white : const Color(0xFF111827),
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildMetadataRow(bool isDark) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final itemAnimation = CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.25, 0.8, curve: Curves.easeOutCubic),
        );
        return Opacity(
          opacity: itemAnimation.value,
          child: child,
        );
      },
      child: Wrap(
        spacing: 16,
        children: widget.metadata.map((meta) {
          return _buildMetadataItem(meta, isDark);
        }).toList(),
      ),
    );
  }

  Widget _buildMetadataItem(PropertyMetadata meta, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          meta.icon,
          size: 16,
          color: const Color(0xFF9CA3AF),
        ),
        const SizedBox(width: 6),
        Text(
          meta.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            color: const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(bool isDark) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final itemAnimation = CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
        );
        return Opacity(
          opacity: itemAnimation.value,
          child: child,
        );
      },
      child: Text(
        widget.description,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          height: 1.6,
          color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280),
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildActionButton(Color primaryColor) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final itemAnimation = CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.45, 0.9, curve: Curves.easeOutCubic),
        );
        return Opacity(
          opacity: itemAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 5 * (1 - itemAnimation.value)),
            child: child,
          ),
        );
      },
      child: InkWell(
        onTap: () {
          // TODO: 处理点击事件
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
      ),
    );
  }
}
