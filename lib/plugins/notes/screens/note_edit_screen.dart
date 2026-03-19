import 'package:flutter/material.dart';
import 'package:Memento/core/event/event_manager.dart';
import 'package:Memento/core/route/route_history_manager.dart';
import 'package:Memento/plugins/notes/models/note.dart';
import 'package:Memento/plugins/notes/notes_plugin.dart';
import 'package:Memento/widgets/quill_editor.dart';

class NoteEditScreen extends StatefulWidget {
  final Note? note;
  final Function(String title, String content) onSave;

  const NoteEditScreen({super.key, this.note, required this.onSave});

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  late final EventManager _eventManager;
  Note? _currentNote;
  int _contentVersion = 0; // 内容版本号，用于强制重建编辑器

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;
    _eventManager = EventManager.instance;
    // 订阅同步刷新事件
    _eventManager.subscribe('notes_refresh', _handleSyncRefresh);
    // 初始化时设置路由上下文
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateRouteContext();
    });
  }

  @override
  void dispose() {
    _eventManager.unsubscribe('notes_refresh', _handleSyncRefresh);
    super.dispose();
  }

  /// 处理同步刷新事件
  void _handleSyncRefresh(EventArgs args) {
    // 仅在编辑现有笔记时处理
    if (_currentNote == null) return;

    // 从 controller 获取最新的笔记数据
    final updatedNote = NotesPlugin.instance.controller.getNoteById(_currentNote!.id);
    if (updatedNote != null && mounted) {
      debugPrint('[NoteEditScreen] 检测到笔记更新: ${updatedNote.title}');
      // 更新当前笔记引用并增加版本号以触发编辑器重建
      setState(() {
        _currentNote = updatedNote;
        _contentVersion++;
      });
    }
  }

  /// 更新路由上下文，使"询问当前上下文"功能能获取到当前正在编辑的笔记信息
  void _updateRouteContext() {
    final isNew = _currentNote == null;
    final noteTitle = _currentNote?.title ?? '新建笔记';
    final params = <String, String>{
      'isNew': isNew.toString(),
      'noteTitle': noteTitle,
    };

    // 如果是编辑现有笔记，添加笔记ID
    if (!isNew) {
      params['noteId'] = _currentNote!.id;
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
        // 使用版本号确保同步更新时能重建编辑器
        key: _currentNote != null
            ? Key('note_${_currentNote!.id}_v$_contentVersion')
            : null,
        initialTitle: _currentNote?.title,
        initialContent: _currentNote?.content,
        onSave: (title, content) {
          widget.onSave(title, content);
          Navigator.pop(context);
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }
}
