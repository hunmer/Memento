import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 笔记数据模型
class NoteItem {
  final String title;
  final String time;
  final String preview;
  final String? imageUrl;

  const NoteItem({
    required this.title,
    required this.time,
    required this.preview,
    this.imageUrl,
  });

  /// 从 JSON 创建（用于公共小组件系统）
  factory NoteItem.fromJson(Map<String, dynamic> json) {
    return NoteItem(
      title: json['title'] as String? ?? '',
      time: json['time'] as String? ?? '',
      preview: json['preview'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'time': time,
      'preview': preview,
      'imageUrl': imageUrl,
    };
  }

  /// 创建副本
  NoteItem copyWith({
    String? title,
    String? time,
    String? preview,
    String? imageUrl,
  }) {
    return NoteItem(
      title: title ?? this.title,
      time: time ?? this.time,
      preview: preview ?? this.preview,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

/// 笔记列表卡片小组件
class NotesListCardWidget extends StatefulWidget {
  final List<NoteItem> notes;
  final String? title; // 可配置标题
  final Color? headerColor; // 可配置头部颜色
  final VoidCallback? onNoteTap; // 笔记点击回调

  const NotesListCardWidget({
    super.key,
    required this.notes,
    this.title,
    this.headerColor,
    this.onNoteTap,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory NotesListCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final notesList = (props['notes'] as List<dynamic>?)
            ?.map((e) => NoteItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return NotesListCardWidget(
      notes: notesList,
      title: props['title'] as String?,
      headerColor: props['headerColor'] != null
          ? Color(props['headerColor'] as int)
          : null,
    );
  }

  @override
  State<NotesListCardWidget> createState() => _NotesListCardWidgetState();
}

class _NotesListCardWidgetState extends State<NotesListCardWidget>
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

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: 360,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(context, isDark),
                  _buildDivider(isDark),
                  ...List.generate(widget.notes.length, (index) {
                    return _buildNoteItem(
                      context,
                      widget.notes[index],
                      index,
                      isDark: isDark,
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final defaultHeaderColor = widget.headerColor ?? const Color(0xFFFFC107);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: defaultHeaderColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.folder_open,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 10),
          Text(
            widget.title ?? 'Notes',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 2,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            width: 2,
          ),
        ),
      ),
      child: CustomPaint(
        painter: _DashedLinePainter(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildNoteItem(
    BuildContext context,
    NoteItem note,
    int index, {
    required bool isDark,
  }) {
    // 计算每个元素的延迟动画
    final itemAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        index * 0.1,
        0.5 + index * 0.1,
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: itemAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: itemAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - itemAnimation.value)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.grey.shade800.withOpacity(0.5)
                        : Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: InkWell(
                onTap: widget.onNoteTap,
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.title,
                            style: TextStyle(
                              color: isDark ? Colors.grey.shade100 : Colors.grey.shade900,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${note.time} ${note.preview}',
                            style: TextStyle(
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                              fontSize: 12,
                              height: 1.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (note.imageUrl != null) ...[
                      const SizedBox(width: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          note.imageUrl!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.image,
                                size: 20,
                                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 虚线绘制器
class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 5.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
