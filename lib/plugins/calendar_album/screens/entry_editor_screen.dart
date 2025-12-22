import 'package:flutter/material.dart';
import 'package:Memento/core/route/route_history_manager.dart';
import 'package:Memento/plugins/calendar_album/models/calendar_entry.dart';
import 'entry_editor/entry_editor_controller.dart';
import 'entry_editor/entry_editor_ui.dart';

class EntryEditorScreen extends StatefulWidget {
  final CalendarEntry? entry;
  final DateTime? initialDate;
  final bool isEditing;

  const EntryEditorScreen({
    super.key,
    this.entry,
    this.initialDate,
    required this.isEditing,
  });

  @override
  State<EntryEditorScreen> createState() => _EntryEditorScreenState();
}

class _EntryEditorScreenState extends State<EntryEditorScreen> {
  late EntryEditorController _controller;

  @override
  void initState() {
    super.initState();
    _controller = EntryEditorController(
      entry: widget.entry,
      isEditing: widget.isEditing,
      initialDate: widget.initialDate,
    );
    // 初始化时设置路由上下文
    _updateRouteContext();
  }

  /// 更新路由上下文，使"询问当前上下文"功能能获取到当前编辑状态
  void _updateRouteContext() {
    final date = widget.entry?.createdAt ?? widget.initialDate ?? DateTime.now();
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final mode = widget.isEditing ? '编辑' : '新建';
    final title = widget.entry?.title ?? '新日记';

    RouteHistoryManager.updateCurrentContext(
      pageId: '/calendar_album_entry_editor',
      title: '$mode日记 - $title',
      params: {
        'date': dateStr,
        'mode': mode,
        'title': title,
        'isEditing': widget.isEditing.toString(),
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EntryEditorUI(
      controller: _controller,
      isEditing: widget.isEditing,
      parentContext: context,
    );
  }
}
