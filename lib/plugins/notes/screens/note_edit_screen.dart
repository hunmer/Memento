import 'package:flutter/material.dart';
import 'package:Memento/core/route/route_history_manager.dart';
import 'package:Memento/plugins/notes/models/note.dart';
import 'package:Memento/widgets/quill_editor.dart';

class NoteEditScreen extends StatefulWidget {
  final Note? note;
  final Function(String title, String content) onSave;

  const NoteEditScreen({super.key, this.note, required this.onSave});

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  @override
  void initState() {
    super.initState();
    // 初始化时设置路由上下文
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateRouteContext();
    });
  }

  /// 更新路由上下文，使"询问当前上下文"功能能获取到当前正在编辑的笔记信息
  void _updateRouteContext() {
    final isNew = widget.note == null;
    final noteTitle = widget.note?.title ?? '新建笔记';
    final params = <String, String>{
      'isNew': isNew.toString(),
      'noteTitle': noteTitle,
    };

    // 如果是编辑现有笔记，添加笔记ID
    if (!isNew) {
      params['noteId'] = widget.note!.id;
    }

    final title = isNew ? '新建笔记' : '编辑笔记 - $noteTitle';

    RouteHistoryManager.updateCurrentContext(
      pageId: '/note_edit',
      title: title,
      params: params,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: QuillEditor(
        initialTitle: widget.note?.title,
        initialContent: widget.note?.content,
        onSave: (title, content) {
          widget.onSave(title, content);
          Navigator.pop(context);
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }
}
