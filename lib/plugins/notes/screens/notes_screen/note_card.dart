import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:Memento/plugins/notes/models/note.dart';
import 'package:Memento/widgets/quill_viewer/quill_viewer.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/widgets/smooth_bottom_sheet.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  // Pastel colors from the HTML reference
  static const List<Map<String, Color>> _colors = [
    // Greenish
    {'light': Color(0xFFDCFCE7), 'dark': Color(0xFF163A24), 'text': Color(0xFF14532D), 'textDark': Color(0xFFBBF7D0)},
    // Yellowish
    {'light': Color(0xFFFEF9C3), 'dark': Color(0xFF423910), 'text': Color(0xFF713F12), 'textDark': Color(0xFFFDE047)},
    // Pinkish
    {'light': Color(0xFFFFE4E6), 'dark': Color(0xFF521319), 'text': Color(0xFF881337), 'textDark': Color(0xFFFECDD3)},
    // Bluish
    {'light': Color(0xFFE0E7FF), 'dark': Color(0xFF1E284C), 'text': Color(0xFF3730A3), 'textDark': Color(0xFFC7D2FE)},
    // Purpleish
    {'light': Color(0xFFFAE8FF), 'dark': Color(0xFF43194A), 'text': Color(0xFF701A75), 'textDark': Color(0xFFF5D0FE)},
  ];

  /// 显示底部抽屉菜单
  void _showBottomSheet(BuildContext context) {
    SmoothBottomSheet.show(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.copy),
            title: Text('app_copy'.tr),
            onTap: () {
              Navigator.pop(context);
              _copyNoteContent();
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: Text('app_edit'.tr),
            onTap: () {
              Navigator.pop(context);
              if (onEdit != null) {
                onEdit!();
              } else {
                onTap();
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: Text(
              'app_delete'.tr,
              style: const TextStyle(color: Colors.red),
            ),
            onTap: () {
              Navigator.pop(context);
              onDelete?.call();
            },
          ),
        ],
      ),
    );
  }

  /// 复制笔记内容到剪贴板
  void _copyNoteContent() {
    final textToCopy = '${note.title}\n\n${note.content}';
    Clipboard.setData(ClipboardData(text: textToCopy));
    Toast.success('已复制到剪贴板');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Deterministic color based on note ID hash
    final colorIndex = note.id.hashCode.abs() % _colors.length;
    final colorSet = _colors[colorIndex];

    final bgColor = isDark ? colorSet['dark']! : colorSet['light']!;
    final textColor = isDark ? colorSet['textDark']! : colorSet['text']!;
    final subTextColor = isDark ? colorSet['textDark']!.withOpacity(0.7) : colorSet['text']!.withOpacity(0.7);

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showBottomSheet(context),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder - if we had image support in Note, we'd parse it here.
            // For now, we'll skip the image part unless we parse markdown for image links.
            
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title.isEmpty ? 'No Title' : note.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 使用 QuillViewer 只读渲染富文本内容
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 200, // 限制最大高度，模拟 maxLines: 8
                    ),
                    child: ClipRect(
                      child: DefaultTextStyle(
                        style: TextStyle(
                          fontSize: 14,
                          color: subTextColor,
                          height: 1.5,
                        ),
                        child: QuillViewer(
                          data: note.content,
                          selectable: false,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      if (note.tags.isNotEmpty)
                        ...note.tags.take(3).map((tag) => _buildChip(tag, textColor, isDark)),
                      if (note.tags.isEmpty)
                         _buildDateChip(note.updatedAt, textColor, isDark),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.label_outline, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateChip(DateTime date, Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            DateFormat('MMM d').format(date),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
