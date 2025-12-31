import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io' show File;
import 'package:Memento/plugins/day/models/memorial_day.dart';
import 'package:Memento/utils/image_utils.dart';
import 'package:Memento/widgets/smooth_bottom_sheet.dart';

class MemorialDayCard extends StatefulWidget {
  final MemorialDay memorialDay;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isDraggable;

  const MemorialDayCard({
    super.key,
    required this.memorialDay,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.isDraggable = false,
  });

  @override
  State<MemorialDayCard> createState() => _MemorialDayCardState();
}

class _MemorialDayCardState extends State<MemorialDayCard> {
  ImageProvider? _imageProvider;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant MemorialDayCard oldWidget) {
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

  /// 显示底部操作菜单
  void _showBottomSheetMenu(BuildContext context) {
    SmoothBottomSheet.showWithTitle(
      context: context,
      title: widget.memorialDay.title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 编辑按钮
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blue),
            title: Text('day_editMemorialDay'.tr),
            onTap: () {
              Navigator.pop(context);
              widget.onEdit?.call();
            },
          ),
          // 删除按钮
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: Text('day_deleteMemorialDay'.tr),
            onTap: () {
              Navigator.pop(context);
              widget.onDelete?.call();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress:
            widget.onEdit != null || widget.onDelete != null
                ? () => _showBottomSheetMenu(context)
                : null,
        child: Container(
          decoration: BoxDecoration(
            color: widget.memorialDay.backgroundColor,
            image:
                _imageProvider != null
                    ? DecorationImage(image: _imageProvider!, fit: BoxFit.cover)
                    : null,
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题行：图标 + 标题
                    Row(
                      children: [
                        if (widget.memorialDay.icon != null)
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color:
                                  widget.memorialDay.iconColor ??
                                  Colors.white.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.memorialDay.icon,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        if (widget.memorialDay.icon != null)
                          const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.memorialDay.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
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
                      widget.memorialDay.formattedTargetDate,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        shadows: [
                          const Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 3.0,
                            color: Colors.black45,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.memorialDay.isExpired
                          ? 'day_daysPassed'.trParams({
                            'count': widget.memorialDay.daysPassed.toString(),
                          })
                          : 'day_daysRemaining'.trParams({
                            'count':
                                widget.memorialDay.daysRemaining.toString(),
                          }),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          const Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 3.0,
                            color: Colors.black45,
                          ),
                        ],
                      ),
                    ),
                    if (widget.memorialDay.notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.memorialDay.notes.first,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
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
}
