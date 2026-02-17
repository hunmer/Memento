import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 属性元数据模型
class PropertyMetadata {
  final IconData icon;
  final String label;

  const PropertyMetadata({
    required this.icon,
    required this.label,
  });

  factory PropertyMetadata.fromJson(Map<String, dynamic> json) {
    return PropertyMetadata(
      icon: _iconFromString(json['icon'] as String? ?? ''),
      label: json['label'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'icon': _iconToString(icon), 'label': label};
  }

  static IconData _iconFromString(String iconString) {
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
    if (icon == Icons.calendar_today) return 'Icons.calendar_today';
    if (icon == Icons.schedule) return 'Icons.schedule';
    if (icon == Icons.cloud_queue) return 'Icons.cloud_queue';
    return 'Icons.info';
  }
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

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 组件尺寸
  final HomeWidgetSize size;

  const VerticalPropertyCardWidget({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.metadata,
    required this.description,
    required this.actionLabel,
    required this.actionIcon,
    this.inline = false,
    this.size = const MediumSize(),
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory VerticalPropertyCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final metadataList = (props['metadata'] as List<dynamic>?)
            ?.map((e) => PropertyMetadata.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return VerticalPropertyCardWidget(
      imageUrl: props['imageUrl'] as String? ?? '',
      title: props['title'] as String? ?? '',
      metadata: metadataList,
      description: props['description'] as String? ?? '',
      actionLabel: props['actionLabel'] as String? ?? '',
      actionIcon: PropertyMetadata._iconFromString(
          props['actionIcon'] as String? ?? 'Icons.my_location'),
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

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
        width: widget.inline ? double.maxFinite : 340,
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
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
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
      ),
    );
  }

  Widget _buildImageSection(bool isDark) {
    // 在 small 尺寸下隐藏图片
    if (widget.size is SmallSize) {
      return const SizedBox.shrink();
    }

    // 根据尺寸动态调整图片高度
    double imageHeight;
    if (widget.size is MediumSize || widget.size is WideSize) {
      imageHeight = 140;
    } else if (widget.size is LargeSize || widget.size is Wide2Size) {
      imageHeight = 180;
    } else {
      // Large3, Wide3
      imageHeight = 220;
    }

    return Container(
      height: imageHeight,
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
          height: imageHeight,
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

  Widget _buildContentSection(
      BuildContext context, bool isDark, Color primaryColor) {
    return Padding(
      padding: widget.size.getPadding(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          _buildTitle(isDark),
          SizedBox(height: widget.size.getTitleSpacing()),
          // 元数据行
          _buildMetadataRow(isDark),
          SizedBox(height: widget.size.getItemSpacing()),
          // 描述文本
          _buildDescription(isDark),
          SizedBox(height: widget.size.getTitleSpacing()),
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
          fontSize: widget.size.getTitleFontSize(),
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
        spacing: widget.size.getItemSpacing(),
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
          size: widget.size.getIconSize() * 0.7,
          color: const Color(0xFF9CA3AF),
        ),
        SizedBox(width: widget.size.getSmallSpacing()),
        Text(
          meta.label,
          style: TextStyle(
            fontSize: widget.size.getSubtitleFontSize(),
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
          fontSize: widget.size.getSubtitleFontSize(),
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
              size: widget.size.getIconSize(),
              color: primaryColor,
            ),
            SizedBox(width: widget.size.getSmallSpacing()),
            Text(
              widget.actionLabel,
              style: TextStyle(
                fontSize: widget.size.getSubtitleFontSize(),
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
