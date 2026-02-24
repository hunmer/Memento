import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:Memento/plugins/day/models/memorial_day.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/utils/image_utils.dart';

/// 纪念日卡片组件
///
/// 用于展示纪念日信息的卡片组件，支持背景颜色、图片、图标和倒计时显示。
///
/// 使用示例：
/// ```dart
/// MemorialDayCardWidget(
///   memorialDay: MemorialDay(
///     title: '生日',
///     targetDate: DateTime(2025, 6, 15),
///     backgroundColor: Colors.pink[300]!,
///   ),
/// )
/// ```
class MemorialDayCardWidget extends StatefulWidget {
  /// 纪念日数据
  final MemorialDay memorialDay;

  /// 点击回调
  final VoidCallback? onTap;

  /// 编辑回调
  final VoidCallback? onEdit;

  /// 删除回调
  final VoidCallback? onDelete;

  /// 是否可拖拽
  final bool isDraggable;

  const MemorialDayCardWidget({
    super.key,
    required this.memorialDay,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.isDraggable = false,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory MemorialDayCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return MemorialDayCardWidget(
      memorialDay: MemorialDay.fromJson(
        props['memorialDay'] as Map<String, dynamic>? ?? {},
      ),
      onTap: props['onTap'] as VoidCallback?,
      onEdit: props['onEdit'] as VoidCallback?,
      onDelete: props['onDelete'] as VoidCallback?,
      isDraggable: props['isDraggable'] as bool? ?? false,
    );
  }

  @override
  State<MemorialDayCardWidget> createState() => _MemorialDayCardWidgetState();
}

class _MemorialDayCardWidgetState extends State<MemorialDayCardWidget> {
  ImageProvider? _imageProvider;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant MemorialDayCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldUrl = oldWidget.memorialDay.backgroundImageUrl;
    final newUrl = widget.memorialDay.backgroundImageUrl;
    if (oldUrl != newUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final imageUrl = widget.memorialDay.backgroundImageUrl;
    if (imageUrl == null) {
      setState(() {
        _imageProvider = null;
      });
      return;
    }

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      setState(() {
        _imageProvider = NetworkImage(imageUrl);
      });
    } else {
      try {
        final absolutePath = await ImageUtils.getAbsolutePath(imageUrl);
        setState(() {
          _imageProvider = FileImage(File(absolutePath));
        });
      } catch (e) {
        debugPrint('Error loading image: $e');
        setState(() {
          _imageProvider = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final memorialDay = widget.memorialDay;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: memorialDay.backgroundColor,
            image: _imageProvider != null
                ? DecorationImage(image: _imageProvider!, fit: BoxFit.cover)
                : null,
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.all(16.0 * _getScaleFactor()),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题行：图标 + 标题
                    Row(
                      children: [
                        if (memorialDay.icon != null)
                          Container(
                            width: 32 * _getScaleFactor(),
                            height: 32 * _getScaleFactor(),
                            decoration: BoxDecoration(
                              color: memorialDay.iconColor ??
                                  Colors.white.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              memorialDay.icon,
                              color: Colors.white,
                              size: 20 * _getScaleFactor(),
                            ),
                          ),
                        if (memorialDay.icon != null)
                          SizedBox(width: 8 * _getScaleFactor()),
                        Expanded(
                          child: Text(
                            memorialDay.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontSize: _getTitleFontSize(theme),
                              shadows: [
                                const Shadow(
                                  offset: Offset(1, 1),
                                  blurRadius: 3.0,
                                  color: Colors.black45,
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      memorialDay.formattedTargetDate,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontSize: _getBodyFontSize(theme),
                        shadows: [
                          const Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 3.0,
                            color: Colors.black45,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 4 * _getScaleFactor()),
                    Text(
                      memorialDay.isExpired
                          ? '${memorialDay.daysPassed}天已过'
                          : '${memorialDay.daysRemaining}天',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: _getSubtitleFontSize(theme),
                        shadows: [
                          const Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 3.0,
                            color: Colors.black45,
                          ),
                        ],
                      ),
                    ),
                    if (memorialDay.notes.isNotEmpty) ...[
                      SizedBox(height: 8 * _getScaleFactor()),
                      Text(
                        memorialDay.notes.first,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontSize: _getSmallFontSize(theme),
                          shadows: [
                            const Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 3.0,
                              color: Colors.black45,
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 根据尺寸类别获取缩放因子
  double _getScaleFactor() {
    // 使用 size 提供的语义化方法来计算缩放
    // 2x3 是当前组件的默认尺寸
    return 1.0;
  }

  double _getTitleFontSize(ThemeData theme) {
    return theme.textTheme.titleLarge?.fontSize ?? 22;
  }

  double _getSubtitleFontSize(ThemeData theme) {
    return theme.textTheme.titleMedium?.fontSize ?? 18;
  }

  double _getBodyFontSize(ThemeData theme) {
    return theme.textTheme.bodyMedium?.fontSize ?? 14;
  }

  double _getSmallFontSize(ThemeData theme) {
    return theme.textTheme.bodySmall?.fontSize ?? 12;
  }
}
