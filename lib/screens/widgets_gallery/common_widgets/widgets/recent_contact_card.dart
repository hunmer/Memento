import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 最近联系人卡片小组件
class RecentContactCardWidget extends StatelessWidget {
  /// 联系人数量
  final int contactCount;

  /// 标签
  final String label;

  /// 联系人列表
  final List<RecentContactItem> contacts;

  /// 更多数量
  final int moreCount;

  /// 是否为内联模式
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const RecentContactCardWidget({
    super.key,
    required this.contactCount,
    required this.label,
    required this.contacts,
    this.moreCount = 0,
    this.inline = false,
    this.size = const MediumSize(),
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory RecentContactCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final contactsList = (props['contacts'] as List<dynamic>?)
            ?.map((e) => RecentContactItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return RecentContactCardWidget(
      contactCount: (props['contactCount'] as int?) ?? 0,
      label: props['label'] as String? ?? '',
      contacts: contactsList,
      moreCount: (props['moreCount'] as int?) ?? 0,
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox.expand(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: inline ? double.maxFinite : null,
          height: inline ? double.maxFinite : null,
          padding: size.getPadding(),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题栏
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: size.getItemSpacing(),
                  vertical: size.getItemSpacing() / 2),
                child: Row(
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: size.getSubtitleFontSize(),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$contactCount',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: size.getSubtitleFontSize(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // 联系人列表
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: size.getItemSpacing() / 2),
                  shrinkWrap: true,
                  itemCount: contacts.length + (moreCount > 0 ? 1 : 0),
                  separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                      ),
                  itemBuilder: (context, index) {
                    if (index < contacts.length) {
                      final contact = contacts[index];
                      return _buildContactItem(context, contact, size, theme);
                    } else {
                      // 显示"更多"项
                      return _buildMoreItem(context, size, theme);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context,
    RecentContactItem contact,
    HomeWidgetSize size,
    ThemeData theme,
  ) {
    return InkWell(
      onTap: () => _navigateToDetail(context, contact.id),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: size.getItemSpacing() / 2),
        child: Row(
          children: [
            _buildAvatar(context, contact, size, theme),
            SizedBox(width: size.getItemSpacing()),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    contact.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: size.getSubtitleFontSize(),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (contact.lastContactTime.isNotEmpty)
                    Text(
                      contact.lastContactTime,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: size.getSubtitleFontSize(),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(
    BuildContext context,
    RecentContactItem contact,
    HomeWidgetSize size,
    ThemeData theme,
  ) {
    final iconSize = size.getIconSize() * 0.5;
    final icon = IconData(contact.iconCodePoint, fontFamily: 'MaterialIcons');
    final color = Color(contact.iconColorValue);

    if (contact.hasAvatar) {
      return Container(
        width: size.getIconSize(),
        height: size.getIconSize(),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.2),
        ),
        child: Icon(icon, size: iconSize, color: color),
      );
    }

    return Container(
      width: size.getIconSize(),
      height: size.getIconSize(),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.primaryContainer,
      ),
      child: Center(
        child: Text(
          contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: size.getIconSize() * 0.4,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }

  Widget _buildMoreItem(
    BuildContext context,
    HomeWidgetSize size,
    ThemeData theme,
  ) {
    return Center(
      child: TextButton(
        onPressed: () => _navigateToMore(context),
        style: TextButton.styleFrom(
          foregroundColor: theme.colorScheme.primary,
          padding: EdgeInsets.symmetric(vertical: size.getItemSpacing() / 2),
        ),
        child: Text(
          '+$moreCount',
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: size.getSubtitleFontSize(),
          ),
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, String contactId) {
    // TODO: 导航到联系人详情页
    debugPrint('Navigate to contact: $contactId');
  }

  void _navigateToMore(BuildContext context) {
    // TODO: 显示更多联系人列表
    debugPrint('Show more contacts');
  }
}

/// 最近联系人项数据模型
class RecentContactItem {
  final String id;
  final String name;
  final String lastContactTime;
  final bool hasAvatar;
  final int iconCodePoint;
  final int iconColorValue;

  RecentContactItem({
    required this.id,
    required this.name,
    required this.lastContactTime,
    this.hasAvatar = false,
    required this.iconCodePoint,
    required this.iconColorValue,
  });

  factory RecentContactItem.fromJson(Map<String, dynamic> json) {
    return RecentContactItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      lastContactTime: json['lastContactTime'] as String? ?? '',
      hasAvatar: json['hasAvatar'] as bool? ?? false,
      iconCodePoint: (json['icon'] as int?) ?? 0,
      iconColorValue: (json['iconColor'] as int?) ?? 0xFF9C27B0,
    );
  }
}
