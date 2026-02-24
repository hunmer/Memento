import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/plugins/openai/models/ai_agent.dart';
import 'package:Memento/widgets/adaptive_image.dart';

/// Agent 卡片组件（公共小组件版本）
///
/// 用于在主页小组件系统中展示 AI 助手信息
class AgentCardWidget extends StatefulWidget {
  /// Agent 名称
  final String name;

  /// Agent 描述
  final String description;

  /// 服务商 ID
  final String serviceProviderId;

  /// 标签列表
  final List<String> tags;

  /// 头像 URL
  final String? avatarUrl;

  /// 图标（IconData 的 codePoint）
  final int? iconCodePoint;

  /// 图标颜色
  final int? iconColorValue;

  /// 小组件尺寸（用于响应式布局）
  final HomeWidgetSize? size;

  /// 点击回调（用于导航到详情页）
  final VoidCallback? onTap;

  /// 长按回调（用于显示操作菜单）
  final VoidCallback? onLongPress;

  const AgentCardWidget({
    super.key,
    required this.name,
    required this.description,
    required this.serviceProviderId,
    required this.tags,
    this.avatarUrl,
    this.iconCodePoint,
    this.iconColorValue,
    this.size,
    this.onTap,
    this.onLongPress,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory AgentCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return AgentCardWidget(
      name: props['name'] as String? ?? '',
      description: props['description'] as String? ?? '',
      serviceProviderId: props['serviceProviderId'] as String? ?? 'openai',
      tags: (props['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      avatarUrl: props['avatarUrl'] as String?,
      iconCodePoint: props['iconCodePoint'] as int?,
      iconColorValue: props['iconColorValue'] as int?,
      size: size,
      onTap: props['onTap'] as VoidCallback?,
      onLongPress: props['onLongPress'] as VoidCallback?,
    );
  }

  @override
  State<AgentCardWidget> createState() => _AgentCardWidgetState();
}

class _AgentCardWidgetState extends State<AgentCardWidget> {
  final GlobalKey _cardKey = GlobalKey();

  /// 根据服务商 ID 获取颜色
  Color _getColorForServiceProvider(String providerId) {
    switch (providerId) {
      case 'openai':
        return Colors.green;
      case 'azure':
        return Colors.blue;
      case 'ollama':
        return Colors.orange;
      case 'deepseek':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// 根据尺寸获取图标容器大小
  double _getIconContainerSize(HomeWidgetSize size) {
    switch (size.category) {
      case SizeCategory.mini:
        return 40.0;
      case SizeCategory.small:
        return 60.0;
      case SizeCategory.medium:
        return 70.0;
      case SizeCategory.large:
      case SizeCategory.xlarge:
        return 80.0;
    }
  }

  /// 根据尺寸获取图标大小
  double _getIconSize(HomeWidgetSize size) {
    switch (size.category) {
      case SizeCategory.mini:
        return 20.0;
      case SizeCategory.small:
        return 30.0;
      case SizeCategory.medium:
        return 35.0;
      case SizeCategory.large:
      case SizeCategory.xlarge:
        return 40.0;
    }
  }

  /// 根据尺寸获取字体大小
  double _getTitleFontSize(HomeWidgetSize size) {
    switch (size.category) {
      case SizeCategory.mini:
        return 10.0;
      case SizeCategory.small:
        return 12.0;
      case SizeCategory.medium:
        return 14.0;
      case SizeCategory.large:
      case SizeCategory.xlarge:
        return 16.0;
    }
  }

  /// 根据尺寸获取副标题字体大小
  double _getSubtitleFontSize(HomeWidgetSize size) {
    switch (size.category) {
      case SizeCategory.mini:
        return 8.0;
      case SizeCategory.small:
        return 10.0;
      case SizeCategory.medium:
        return 11.0;
      case SizeCategory.large:
      case SizeCategory.xlarge:
        return 12.0;
    }
  }

  /// 根据尺寸获取内边距
  double _getPadding(HomeWidgetSize size) {
    switch (size.category) {
      case SizeCategory.mini:
        return 4.0;
      case SizeCategory.small:
        return 6.0;
      case SizeCategory.medium:
        return 8.0;
      case SizeCategory.large:
      case SizeCategory.xlarge:
        return 8.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 使用传入的尺寸，默认 large
    final size = widget.size ?? HomeWidgetSize.large;
    final effectiveColor = widget.iconColorValue != null
        ? Color(widget.iconColorValue!)
        : _getColorForServiceProvider(widget.serviceProviderId);

    return Material(
      key: _cardKey,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Agent Icon
            Expanded(
              child: Center(
                child: _buildAgentIcon(effectiveColor, size),
              ),
            ),

            // Agent Info
            Padding(
              padding: EdgeInsets.all(_getPadding(size)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: _getTitleFontSize(size),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    '服务商: ${widget.serviceProviderId}',
                    style: TextStyle(
                      fontSize: _getSubtitleFontSize(size),
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  _buildTags(isDark, size),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentIcon(Color effectiveColor, HomeWidgetSize size) {
    final iconSize = _getIconContainerSize(size);

    // 如果有头像，优先显示头像
    if (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty) {
      return SizedBox(
        width: iconSize,
        height: iconSize,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: effectiveColor.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: ClipOval(
            child: AdaptiveImage(
              imagePath: widget.avatarUrl,
              width: iconSize,
              height: iconSize,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }

    // 如果有自定义图标，使用自定义图标
    if (widget.iconCodePoint != null) {
      return Container(
        width: iconSize,
        height: iconSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: effectiveColor,
        ),
        child: Icon(
          IconData(widget.iconCodePoint!, fontFamily: 'MaterialIcons'),
          size: _getIconSize(size),
          color: Colors.white,
        ),
      );
    }

    // 默认图标
    return _buildDefaultIcon(effectiveColor, size);
  }

  Widget _buildDefaultIcon(Color effectiveColor, HomeWidgetSize size) {
    final iconSize = _getIconContainerSize(size);
    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: effectiveColor,
      ),
      child: Icon(
        Icons.smart_toy,
        size: _getIconSize(size),
        color: Colors.white,
      ),
    );
  }

  Widget _buildTags(bool isDark, HomeWidgetSize size) {
    final tagCount = size.category == SizeCategory.mini ? 1 : 2;
    return Wrap(
      spacing: 2,
      runSpacing: 2,
      children: widget.tags.take(tagCount).map((tag) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: _getPadding(size) / 2,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            tag,
            style: TextStyle(
              fontSize: _getSubtitleFontSize(size) - 2,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// AgentCardData 数据模型（用于 JSON 序列化）
class AgentCardData {
  final String name;
  final String description;
  final String serviceProviderId;
  final List<String> tags;
  final String? avatarUrl;
  final int? iconCodePoint;
  final int? iconColorValue;
  final int? sizeWidth;
  final int? sizeHeight;

  const AgentCardData({
    required this.name,
    required this.description,
    required this.serviceProviderId,
    required this.tags,
    this.avatarUrl,
    this.iconCodePoint,
    this.iconColorValue,
    this.sizeWidth,
    this.sizeHeight,
  });

  /// 获取 HomeWidgetSize
  HomeWidgetSize get size {
    if (sizeWidth != null && sizeHeight != null) {
      return HomeWidgetSize.fromSize(sizeWidth!, sizeHeight!);
    }
    return HomeWidgetSize.large;
  }

  /// 从 AIAgent 创建
  factory AgentCardData.fromAgent(AIAgent agent, {HomeWidgetSize? size}) {
    return AgentCardData(
      name: agent.name,
      description: agent.description,
      serviceProviderId: agent.serviceProviderId,
      tags: agent.tags,
      avatarUrl: agent.avatarUrl,
      iconCodePoint: agent.icon?.codePoint,
      iconColorValue: agent.iconColor?.value,
      sizeWidth: size?.width,
      sizeHeight: size?.height,
    );
  }

  /// 从 JSON 创建
  factory AgentCardData.fromJson(Map<String, dynamic> json) {
    return AgentCardData(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      serviceProviderId: json['serviceProviderId'] as String? ?? 'openai',
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      avatarUrl: json['avatarUrl'] as String?,
      iconCodePoint: json['iconCodePoint'] as int?,
      iconColorValue: json['iconColorValue'] as int?,
      sizeWidth: json['sizeWidth'] as int?,
      sizeHeight: json['sizeHeight'] as int?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'serviceProviderId': serviceProviderId,
      'tags': tags,
      'avatarUrl': avatarUrl,
      'iconCodePoint': iconCodePoint,
      'iconColorValue': iconColorValue,
      'sizeWidth': sizeWidth,
      'sizeHeight': sizeHeight,
    };
  }
}
