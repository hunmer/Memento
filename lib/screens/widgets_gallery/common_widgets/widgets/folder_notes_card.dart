import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 文件夹笔记卡片数据模型
class FolderNotesCardData {
  final String folderName;
  final String folderPath;
  final int iconCodePoint;
  final int colorValue;
  final int notesCount;
  final List<NoteItemData> notes;

  const FolderNotesCardData({
    required this.folderName,
    required this.folderPath,
    required this.iconCodePoint,
    required this.colorValue,
    required this.notesCount,
    required this.notes,
  });

  /// 从 JSON 创建
  factory FolderNotesCardData.fromJson(Map<String, dynamic> json) {
    final notesList = (json['notes'] as List<dynamic>?)
            ?.map((e) => NoteItemData.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return FolderNotesCardData(
      folderName: json['folderName'] as String? ?? '',
      folderPath: json['folderPath'] as String? ?? '',
      iconCodePoint: json['iconCodePoint'] as int? ?? Icons.folder.codePoint,
      colorValue: json['colorValue'] as int? ?? 0xFF000000,
      notesCount: json['notesCount'] as int? ?? 0,
      notes: notesList,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'folderName': folderName,
      'folderPath': folderPath,
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
      'notesCount': notesCount,
      'notes': notes.map((e) => e.toJson()).toList(),
    };
  }
}

/// 笔记项数据模型
class NoteItemData {
  final String title;
  final String updatedAt;

  const NoteItemData({
    required this.title,
    required this.updatedAt,
  });

  /// 从 JSON 创建
  factory NoteItemData.fromJson(Map<String, dynamic> json) {
    return NoteItemData(
      title: json['title'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'updatedAt': updatedAt,
    };
  }
}

/// 文件夹笔记卡片组件
///
/// 显示文件夹名称、图标和最近的笔记列表
class FolderNotesCardWidget extends StatefulWidget {
  final String folderName;
  final String folderPath;
  final int iconCodePoint;
  final int colorValue;
  final int notesCount;
  final List<NoteItemData> notes;

  const FolderNotesCardWidget({
    super.key,
    required this.folderName,
    required this.folderPath,
    required this.iconCodePoint,
    required this.colorValue,
    required this.notesCount,
    required this.notes,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory FolderNotesCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final notesList = (props['notes'] as List<dynamic>?)
            ?.map((e) => NoteItemData.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return FolderNotesCardWidget(
      folderName: props['folderName'] as String? ?? '',
      folderPath: props['folderPath'] as String? ?? '',
      iconCodePoint: props['iconCodePoint'] as int? ?? Icons.folder.codePoint,
      colorValue: props['colorValue'] as int? ?? 0xFF000000,
      notesCount: props['notesCount'] as int? ?? 0,
      notes: notesList,
    );
  }

  @override
  State<FolderNotesCardWidget> createState() => _FolderNotesCardWidgetState();
}

class _FolderNotesCardWidgetState extends State<FolderNotesCardWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final folderIcon =
        IconData(widget.iconCodePoint, fontFamily: 'MaterialIcons');
    final folderColor = Color(widget.colorValue);

    // 获取小组件尺寸
    final widgetSize = context.findAncestorStateOfType<_FolderNotesCardWidgetParentState>()
            ?.widgetSize ??
        const LargeSize();
    final isMediumSize = widgetSize == const MediumSize();

    // 根据尺寸限制显示的笔记数量
    final displayNotes = widget.notes.take(isMediumSize ? 3 : 5).toList();
    final moreCount = widget.notesCount > displayNotes.length
        ? widget.notesCount - displayNotes.length
        : 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部文件夹信息
              Row(
                children: [
                  Icon(folderIcon, size: 20, color: folderColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.folderPath.isNotEmpty ? widget.folderPath : widget.folderName,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // 笔记数量徽章
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: folderColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.notesCount}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: folderColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 笔记列表（使用滚动容器防止溢出）
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (displayNotes.isNotEmpty) ...[
                        ...displayNotes.map(
                          (note) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _buildNoteItem(context, theme, note, folderColor),
                              ),
                        ),
                        if (moreCount > 0)
                          Text(
                            '还有 $moreCount 条笔记',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer
                                  .withOpacity(0.5),
                            ),
                          ),
                      ] else
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              '空文件夹',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer
                                    .withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建笔记项
  Widget _buildNoteItem(
    BuildContext context,
    ThemeData theme,
    NoteItemData note,
    Color folderColor,
  ) {
    return Row(
      children: [
        Icon(
          Icons.note_alt_outlined,
          size: 14,
          color: theme.colorScheme.onPrimaryContainer.withOpacity(0.5),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            note.title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _formatNoteTime(note.updatedAt),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  /// 格式化笔记时间为相对时间显示
  String _formatNoteTime(String isoTime) {
    try {
      final date = DateTime.parse(isoTime);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return '刚刚';
      if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
      if (diff.inDays < 1) return '${diff.inHours}小时前';
      if (diff.inDays < 7) return '${diff.inDays}天前';
      return '${date.month}/${date.day}';
    } catch (e) {
      return '';
    }
  }
}

/// 内部 StatefulWidget 用于传递尺寸信息
class _FolderNotesCardWidgetParent extends StatefulWidget {
  final HomeWidgetSize widgetSize;
  final Widget child;

  const _FolderNotesCardWidgetParent({
    // ignore: unused_element_parameter
    super.key,
    required this.widgetSize,
    required this.child,
  });

  @override
  State<_FolderNotesCardWidgetParent> createState() =>
      _FolderNotesCardWidgetParentState();
}

class _FolderNotesCardWidgetParentState
    extends State<_FolderNotesCardWidgetParent> {
  HomeWidgetSize get widgetSize => widget.widgetSize;

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
