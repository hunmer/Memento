import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 联系人卡片小组件
class ContactCardWidget extends StatelessWidget {
  /// 联系人 ID
  final String id;

  /// 联系人姓名
  final String name;

  /// 电话号码
  final String? phone;

  /// 最后联系时间
  final String lastContactTime;

  /// 是否有头像
  final bool hasAvatar;

  /// 图标
  final int iconCodePoint;

  /// 图标颜色
  final int iconColorValue;

  /// 标签
  final List<String>? tags;

  /// 是否为内联模式
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const ContactCardWidget({
    super.key,
    required this.id,
    required this.name,
    this.phone,
    required this.lastContactTime,
    this.hasAvatar = false,
    required this.iconCodePoint,
    required this.iconColorValue,
    this.tags,
    this.inline = false,
    this.size = const MediumSize(),
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory ContactCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return ContactCardWidget(
      id: props['id'] as String? ?? '',
      name: props['name'] as String? ?? '',
      phone: props['phone'] as String?,
      lastContactTime: props['lastContactTime'] as String? ?? '',
      hasAvatar: props['hasAvatar'] as bool? ?? false,
      iconCodePoint: (props['icon'] as int?) ?? 0,
      iconColorValue: (props['iconColor'] as int?) ?? 0xFF9C27B0,
      tags: (props['tags'] as List<dynamic>?)
              ?.cast<String>()
              .toList(),
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = IconData(iconCodePoint, fontFamily: 'MaterialIcons');
    final color = Color(iconColorValue);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: inline ? double.maxFinite : null,
        height: inline ? double.maxFinite : null,
        padding: size.getPadding(),
        child: Row(
          children: [
            _buildAvatar(context, icon, color),
            SizedBox(width: size.getItemSpacing()),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: size.getTitleFontSize(),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: size.getItemSpacing() / 2),
                  Text(
                    lastContactTime,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: size.getSubtitleFontSize(),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (tags != null && tags!.isNotEmpty) ...[
                    SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: tags!
                          .take(3)
                          .map((tag) => Chip(
                                label: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: size.getSubtitleFontSize(),
                                  ),
                                ),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, IconData icon, Color color) {
    return Container(
      width: size.getIconSize(),
      height: size.getIconSize(),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.2),
      ),
      child: Icon(
        icon,
        size: size.getIconSize() * 0.5,
        color: color,
      ),
    );
  }
}
