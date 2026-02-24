import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/widgets/adaptive_image.dart';

/// 联系人性别枚举
enum ContactCardGender {
  male,
  female,
  other,
}

/// 联系人卡片数据模型（用于 JSON 序列化）
class ContactCardData {
  /// 联系人 ID
  final String id;

  /// 姓名
  final String name;

  /// 头像路径
  final String? avatar;

  /// 图标（IconData 的 codePoint）
  final int? iconCodePoint;

  /// 图标颜色
  final int? iconColorValue;

  /// 电话号码
  final String phone;

  /// 组织/公司
  final String? organization;

  /// 邮箱
  final String? email;

  /// 网站
  final String? website;

  /// 地址
  final String? address;

  /// 备注
  final String? notes;

  /// 性别
  final ContactCardGender? gender;

  /// 标签列表
  final List<String> tags;

  /// 交互记录数量（底部显示）
  final int interactionCount;

  /// 小组件尺寸宽度
  final int? sizeWidth;

  /// 小组件尺寸高度
  final int? sizeHeight;

  const ContactCardData({
    required this.id,
    required this.name,
    this.avatar,
    this.iconCodePoint,
    this.iconColorValue,
    required this.phone,
    this.organization,
    this.email,
    this.website,
    this.address,
    this.notes,
    this.gender,
    this.tags = const [],
    this.interactionCount = 0,
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

  /// 从 JSON 创建
  factory ContactCardData.fromJson(Map<String, dynamic> json) {
    return ContactCardData(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      avatar: json['avatar'] as String?,
      iconCodePoint: json['iconCodePoint'] as int?,
      iconColorValue: json['iconColorValue'] as int?,
      phone: json['phone'] as String? ?? '',
      organization: json['organization'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      address: json['address'] as String?,
      notes: json['notes'] as String?,
      gender: json['gender'] != null
          ? ContactCardGender.values.firstWhere(
              (e) => e.name == json['gender'],
              orElse: () => ContactCardGender.other,
            )
          : null,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      interactionCount: json['interactionCount'] as int? ?? 0,
      sizeWidth: json['sizeWidth'] as int?,
      sizeHeight: json['sizeHeight'] as int?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'iconCodePoint': iconCodePoint,
      'iconColorValue': iconColorValue,
      'phone': phone,
      'organization': organization,
      'email': email,
      'website': website,
      'address': address,
      'notes': notes,
      'gender': gender?.name,
      'tags': tags,
      'interactionCount': interactionCount,
      'sizeWidth': sizeWidth,
      'sizeHeight': sizeHeight,
    };
  }

  /// 从 ContactCardData 复制并修改部分字段
  ContactCardData copyWith({
    String? id,
    String? name,
    String? avatar,
    int? iconCodePoint,
    int? iconColorValue,
    String? phone,
    String? organization,
    String? email,
    String? website,
    String? address,
    String? notes,
    ContactCardGender? gender,
    List<String>? tags,
    int? interactionCount,
    int? sizeWidth,
    int? sizeHeight,
  }) {
    return ContactCardData(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      iconColorValue: iconColorValue ?? this.iconColorValue,
      phone: phone ?? this.phone,
      organization: organization ?? this.organization,
      email: email ?? this.email,
      website: website ?? this.website,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      gender: gender ?? this.gender,
      tags: tags ?? List.from(this.tags),
      interactionCount: interactionCount ?? this.interactionCount,
      sizeWidth: sizeWidth ?? this.sizeWidth,
      sizeHeight: sizeHeight ?? this.sizeHeight,
    );
  }
}

/// 联系人卡片组件（公共小组件版本）
///
/// 用于展示联系人信息，支持响应式布局和自定义交互。
///
/// 特性：
/// - 支持头像或图标显示
/// - 显示姓名、电话、地址、备注、标签
/// - 显示性别图标
/// - 显示交互记录数量
/// - 支持点击和长按回调
/// - 根据 HomeWidgetSize 自动调整布局
class ContactCardWidget extends StatefulWidget {
  /// 联系人数据
  final ContactCardData data;

  /// 小组件尺寸（用于响应式布局）
  final HomeWidgetSize? size;

  /// 点击回调
  final VoidCallback? onTap;

  /// 长按回调
  final VoidCallback? onLongPress;

  /// 历史记录按钮点击回调
  final VoidCallback? onHistoryTap;

  /// 是否显示历史记录按钮
  final bool showHistoryButton;

  const ContactCardWidget({
    super.key,
    required this.data,
    this.size,
    this.onTap,
    this.onLongPress,
    this.onHistoryTap,
    this.showHistoryButton = true,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory ContactCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final cardData = props['data'] != null
        ? ContactCardData.fromJson(props['data'] as Map<String, dynamic>)
        : null;

    return ContactCardWidget(
      data: cardData ??
          ContactCardData(
            id: props['id'] as String? ?? '',
            name: props['name'] as String? ?? '',
            phone: props['phone'] as String? ?? '',
            avatar: props['avatar'] as String?,
            iconCodePoint: props['iconCodePoint'] as int?,
            iconColorValue: props['iconColorValue'] as int?,
            organization: props['organization'] as String?,
            email: props['email'] as String?,
            website: props['website'] as String?,
            address: props['address'] as String?,
            notes: props['notes'] as String?,
            gender: props['gender'] != null
                ? ContactCardGender.values.firstWhere(
                    (e) => e.name == props['gender'],
                    orElse: () => ContactCardGender.other,
                  )
                : null,
            tags: (props['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
            interactionCount: props['interactionCount'] as int? ?? 0,
            sizeWidth: props['sizeWidth'] as int?,
            sizeHeight: props['sizeHeight'] as int?,
          ),
      size: size,
      onTap: props['onTap'] as VoidCallback?,
      onLongPress: props['onLongPress'] as VoidCallback?,
      onHistoryTap: props['onHistoryTap'] as VoidCallback?,
      showHistoryButton: props['showHistoryButton'] as bool? ?? true,
    );
  }

  @override
  State<ContactCardWidget> createState() => _ContactCardWidgetState();
}

class _ContactCardWidgetState extends State<ContactCardWidget> {
  /// 根据性别获取图标
  IconData _getGenderIcon() {
    switch (widget.data.gender) {
      case ContactCardGender.female:
        return Icons.female;
      case ContactCardGender.male:
        return Icons.male;
      default:
        return Icons.person;
    }
  }

  /// 根据性别获取颜色
  Color _getGenderColor() {
    switch (widget.data.gender) {
      case ContactCardGender.female:
        return Theme.of(context).colorScheme.secondary;
      case ContactCardGender.male:
        return Theme.of(context).colorScheme.primary;
      default:
        return Colors.grey;
    }
  }

  /// 获取图标颜色
  Color _getIconColor() {
    if (widget.data.iconColorValue != null) {
      return Color(widget.data.iconColorValue!);
    }
    return Colors.grey;
  }

  /// 获取图标
  IconData _getIcon() {
    if (widget.data.iconCodePoint != null) {
      return IconData(widget.data.iconCodePoint!, fontFamily: 'MaterialIcons');
    }
    return Icons.person;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final primaryTextColor =
        theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface;
    final secondaryTextColor =
        theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onSurfaceVariant;
    final chipColor = theme.colorScheme.surfaceVariant;

    return Card(
      elevation: 2,
      shadowColor: theme.colorScheme.shadow.withOpacity(0.3),
      color: theme.colorScheme.surface,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopSection(context, primaryTextColor, secondaryTextColor),
              if (widget.data.notes != null && widget.data.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  widget.data.notes!,
                  style: TextStyle(fontSize: 14, color: secondaryTextColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),
              _buildTags(context, chipColor, secondaryTextColor),
              const SizedBox(height: 12),
              Divider(height: 1, color: theme.dividerColor),
              const SizedBox(height: 8),
              _buildBottomSection(context, primaryTextColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection(
    BuildContext context,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAvatar(size: 64),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.data.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: primaryTextColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                widget.data.phone,
                style: TextStyle(color: secondaryTextColor, fontSize: 14),
              ),
              if (widget.data.gender != null ||
                  widget.data.organization != null) ...[
                const SizedBox(height: 4),
                _buildSecondaryInfo(context),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (widget.showHistoryButton)
          IconButton(
            icon: const Icon(Icons.history, size: 30),
            color: Theme.of(context).colorScheme.primary,
            onPressed: widget.onHistoryTap,
          ),
      ],
    );
  }

  Widget _buildSecondaryInfo(BuildContext context) {
    List<Widget> children = [];

    if (widget.data.organization != null) {
      children.add(
        Text(
          widget.data.organization!,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    if (widget.data.gender != null &&
        widget.data.gender != ContactCardGender.other) {
      children.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getGenderIcon(), color: _getGenderColor(), size: 16),
            const SizedBox(width: 4),
            Text(
              widget.data.gender == ContactCardGender.male ? 'Male' : 'Female',
              style: TextStyle(color: _getGenderColor(), fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    if (children.length == 1) {
      return children[0];
    }

    return Row(
      children: [
        ...children.take(children.length - 1),
        ...children.skip(children.length - 1).map((child) =>
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: child,
            )),
      ],
    );
  }

  Widget _buildAvatar({required double size}) {
    if (widget.data.avatar != null && widget.data.avatar!.isNotEmpty) {
      return ClipOval(
        child: AdaptiveImage(
          imagePath: widget.data.avatar,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }
    return _buildIconAvatar(size);
  }

  Widget _buildIconAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getIconColor().withOpacity(0.2),
      ),
      child: Icon(_getIcon(), color: _getIconColor(), size: size * 0.6),
    );
  }

  Widget _buildTags(BuildContext context, Color chipColor, Color textColor) {
    if (widget.data.tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: widget.data.tags.map((tag) {
        return Chip(
          backgroundColor: chipColor,
          label: Text(
            tag,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide.none,
        );
      }).toList(),
    );
  }

  Widget _buildBottomSection(BuildContext context, Color textColor) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: widget.onHistoryTap,
      child: Row(
        children: [
          if (widget.data.interactionCount > 0) ...[
            Icon(
              Icons.event_note,
              color: theme.colorScheme.primary,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              "View ${widget.data.interactionCount} record(s)",
              style: TextStyle(fontSize: 14, color: textColor),
            ),
          ] else
            Text(
              "No records",
              style: TextStyle(fontSize: 14, color: textColor),
            ),
          const Spacer(),
          Icon(Icons.arrow_forward_ios, size: 14, color: textColor),
        ],
      ),
    );
  }
}
