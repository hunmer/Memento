import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/core/storage/storage_manager.dart';
import 'package:Memento/core/event/event_manager.dart';
import 'package:Memento/core/event/item_event_args.dart';
import 'package:Memento/core/services/plugin_widget_sync_helper.dart';
import 'package:Memento/plugins/notes/models/folder.dart';
import 'package:Memento/plugins/notes/models/note.dart';
import 'package:Memento/plugins/notes/data/notes_sample_data.dart';

/// Notes 缓存更新事件参数
class NotesCacheUpdatedEventArgs extends EventArgs {
  final List<Map<String, dynamic>> folders;
  final List<String> noteIds;
  final DateTime cacheDate;

  NotesCacheUpdatedEventArgs({
    required this.folders,
    required this.noteIds,
    required this.cacheDate,
  }) : super('notes_cache_updated');
}

class NotesController {
  final StorageManager _storage;
  final Map<String, Folder> _folders = {};
  final Map<String, List<Note>> _notes = {};
  final Set<String> _noteIds = {}; // 内存中的笔记ID集合，用于快速访问

  // 发送事件通知
  void _notifyEvent(String action, Note note) {
    final eventArgs = ItemEventArgs(
      eventName: 'note_$action',
      itemId: note.id,
      title: note.title,
      action: action,
    );
    EventManager.instance.broadcast('note_$action', eventArgs);
  }

  NotesController(this._storage);

  Future<void> initialize() async {
    // 确保插件目录存在
    await _storage.ensurePluginDirectoryExists('notes');
    await _loadFolders();
    await _loadNotes();
  }

  Future<void> _loadFolders() async {
    try {
      // 读取文件内容为字符串
      final data = await _storage
          .readPluginFile('notes', 'folders.json')
          .catchError((_) => '');

      if (data.isNotEmpty) {
        final List<dynamic> jsonList = json.decode(data);
        for (var item in jsonList) {
          final folder = Folder.fromJson(item);
          _folders[folder.id] = folder;
        }
      } else {
        // 加载示例文件夹数据
        final sampleFolders = NotesSampleData.getSampleFolders();
        for (var folder in sampleFolders) {
          _folders[folder.id] = folder;
        }
        await _saveFolders();
      }
    } catch (e) {
      debugPrint('Error loading folders: $e');
      rethrow;
    }
  }

  Future<void> _loadNotes() async {
    try {
      // 确保 notes 子目录存在
      await _storage.ensurePluginDirectoryExists('notes/notes');

      // 尝试读取笔记索引文件
      final indexData = await _storage
          .readPluginFile('notes', 'notes/index.json')
          .catchError((_) => '');

      if (indexData.isNotEmpty) {
        // 新格式：按 ID 分文件存储
        final List<dynamic> noteIds = json.decode(indexData);
        for (var id in noteIds) {
          _noteIds.add(id.toString());
          final noteData = await _storage
              .readPluginFile('notes', 'notes/$id.json')
              .catchError((_) => '');
          if (noteData.isNotEmpty) {
            final note = Note.fromJson(json.decode(noteData));
            _notes.putIfAbsent(note.folderId, () => []).add(note);
          }
        }
      } else {
        // 兼容旧格式：尝试读取 notes.json
        final legacyData = await _storage
            .readPluginFile('notes', 'notes.json')
            .catchError((_) => '');

        if (legacyData.isNotEmpty) {
          // 迁移旧数据到新格式
          final List<dynamic> jsonList = json.decode(legacyData);
          final noteIds = <String>[];
          for (var item in jsonList) {
            final note = Note.fromJson(item);
            _notes.putIfAbsent(note.folderId, () => []).add(note);
            noteIds.add(note.id);
            _noteIds.add(note.id);
            // 保存每个笔记到单独文件
            await _saveNoteToFile(note);
          }
          // 保存索引文件
          await _saveNoteIndex(noteIds);
          // 删除旧文件
          await _storage.deleteFile('notes/notes.json');
        } else {
          // 加载示例笔记数据
          final sampleNotes = NotesSampleData.getSampleNotes();
          final noteIds = <String>[];
          for (var note in sampleNotes) {
            _notes.putIfAbsent(note.folderId, () => []).add(note);
            noteIds.add(note.id);
            _noteIds.add(note.id);
            await _saveNoteToFile(note);
          }
          await _saveNoteIndex(noteIds);
        }
      }
    } catch (e) {
      debugPrint('Error loading notes: $e');
      rethrow;
    }
  }

  /// 保存笔记索引
  Future<void> _saveNoteIndex(List<String> noteIds) async {
    final jsonString = json.encode(noteIds);
    await _storage.writePluginFile('notes', 'notes/index.json', jsonString);

    // 触发缓存更新事件
    _notifyCacheUpdatedEvent();
  }

  /// 保存单个笔记到文件
  Future<void> _saveNoteToFile(Note note) async {
    final jsonString = json.encode(note.toJson());
    await _storage.writePluginFile('notes', 'notes/${note.id}.json', jsonString);
  }

  /// 从文件删除笔记
  Future<void> _deleteNoteFile(String noteId) async {
    await _storage.deleteFile('notes/notes/$noteId.json');
  }

  Future<void> _saveFolders() async {
    try {
      final jsonList = _folders.values.map((f) => f.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await _storage.writePluginFile('notes', 'folders.json', jsonString);

      // 触发缓存更新事件
      _notifyCacheUpdatedEvent();
    } catch (e) {
      debugPrint('Error saving folders: $e');
      rethrow;
    }
  }

  // 获取文件夹
  Folder? getFolder(String id) {
    return _folders[id];
  }

  // 获取所有文件夹
  List<Folder> getAllFolders() {
    return _folders.values.toList();
  }

  // 获取所有笔记
  Map<String, List<Note>> getAllNotes() {
    return _notes;
  }

  // 获取指定文件夹的子文件夹
  List<Folder> getFolderChildren(String parentId) {
    return _folders.values
        .where((folder) => folder.parentId == parentId)
        .toList();
  }

  /// 获取文件夹的完整路径(从根文件夹到当前文件夹)
  /// 返回包含所有祖先文件夹的列表,顺序为:根 -> ... -> 父 -> 当前
  List<Folder> getFolderPath(String folderId) {
    final path = <Folder>[];
    String? currentId = folderId;

    // 向上遍历,直到根文件夹
    while (currentId != null) {
      final folder = _folders[currentId];
      if (folder == null) break;

      path.insert(0, folder); // 在开头插入,保证顺序正确
      currentId = folder.parentId;
    }

    return path;
  }

  // 获取文件夹中的笔记
  List<Note> getFolderNotes(String folderId) {
    return _notes[folderId] ?? [];
  }

  // 创建新文件夹
  Future<Folder> createFolder(
    String name,
    String? parentId, {
    String? customId,
  }) async {
    // 如果提供了自定义 ID,检查是否已存在
    if (customId != null) {
      if (_folders.containsKey(customId)) {
        throw Exception('文件夹 ID "$customId" 已存在,请使用不同的 ID');
      }
    }

    final folder = Folder(
      id: customId ?? const Uuid().v4(),
      name: name,
      parentId: parentId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _folders[folder.id] = folder;
    await _saveFolders();
    return folder;
  }

  // 创建新笔记
  Future<Note> createNote(
    String title,
    String content,
    String folderId, {
    String? customId,
  }) async {
    // 如果提供了自定义 ID,检查是否已存在
    if (customId != null) {
      final allNotes = _notes.values.expand((notes) => notes).toList();
      if (allNotes.any((note) => note.id == customId)) {
        throw Exception('笔记 ID "$customId" 已存在,请使用不同的 ID');
      }
    }

    final note = Note(
      id: customId ?? const Uuid().v4(),
      title: title,
      content: content,
      folderId: folderId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _notes.putIfAbsent(folderId, () => []).add(note);
    _noteIds.add(note.id);
    // 保存到单独文件
    await _saveNoteToFile(note);
    await _saveNoteIndex(_noteIds.toList());
    _notifyEvent('added', note);

    // 同步小组件数据
    await _syncWidget();

    return note;
  }

  // 更新笔记
  Future<void> updateNote(Note note) async {
    final notes = _notes[note.folderId];
    if (notes != null) {
      final index = notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        notes[index] = note;
        // 只保存单个笔记到文件
        await _saveNoteToFile(note);

        // 触发更新事件
        _notifyEvent('updated', note);

        // 同步小组件数据
        await _syncWidget();
      }
    }
  }

  // 删除笔记
  Future<void> deleteNote(String noteId) async {
    // 查找包含该笔记的文件夹
    for (var entry in _notes.entries) {
      final notes = entry.value;
      final noteIndex = notes.indexWhere((note) => note.id == noteId);
      if (noteIndex != -1) {
        final note = notes[noteIndex];
        notes.removeAt(noteIndex);
        // 删除单独的文件
        await _deleteNoteFile(noteId);
        _noteIds.remove(noteId);
        await _saveNoteIndex(_noteIds.toList());
        // 发送删除事件
        _notifyEvent('deleted', note);

        // 同步小组件数据
        await _syncWidget();
        break;
      }
    }
  }

  // 通过Note对象删除笔记
  Future<void> deleteNoteObject(Note note) async {
    await deleteNote(note.id);
  }

  // 移动笔记到其他文件夹
  Future<void> moveNote(String noteId, String targetFolderId) async {
    Note? noteToMove;
    String? sourceFolderId;

    // 查找笔记
    for (var entry in _notes.entries) {
      final notes = entry.value;
      final index = notes.indexWhere((note) => note.id == noteId);
      if (index != -1) {
        noteToMove = notes[index];
        sourceFolderId = entry.key;
        notes.removeAt(index);
        break;
      }
    }

    // 如果找到笔记，将其添加到目标文件夹
    if (noteToMove != null && sourceFolderId != null) {
      // 创建一个新的笔记对象，更新文件夹ID
      final movedNote = Note(
        id: noteToMove.id,
        title: noteToMove.title,
        content: noteToMove.content,
        folderId: targetFolderId,
        createdAt: noteToMove.createdAt,
        updatedAt: DateTime.now(), // 更新时间戳
        tags: noteToMove.tags,
      );

      // 添加到新文件夹
      _notes.putIfAbsent(targetFolderId, () => []).add(movedNote);

      // 保存更改（更新单独的文件）
      await _saveNoteToFile(movedNote);
      await _saveNoteIndex(_noteIds.toList());
    }
  }

  // 重命名文件夹
  Future<void> renameFolder(String folderId, String newName) async {
    final folder = _folders[folderId];
    if (folder != null) {
      folder.name = newName;
      folder.updatedAt = DateTime.now();
      await _saveFolders();
    }
  }

  // 删除文件夹
  // 搜索笔记
  List<Note> searchNotes({
    required String query,
    List<String>? tags,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final allNotes = _notes.values.expand((notes) => notes).toList();
    return allNotes.where((note) {
      // 标题和内容匹配
      if (!note.title.toLowerCase().contains(query.toLowerCase()) &&
          !note.content.toLowerCase().contains(query.toLowerCase())) {
        return false;
      }

      // 标签匹配
      if (tags != null && tags.isNotEmpty) {
        if (!tags.any((tag) => note.tags.contains(tag))) {
          return false;
        }
      }

      // 日期范围匹配
      if (startDate != null && note.createdAt.isBefore(startDate)) {
        return false;
      }
      if (endDate != null) {
        final endOfDay = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
        );
        if (note.createdAt.isAfter(endOfDay)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> deleteFolder(String folderId) async {
    // 递归删除子文件夹
    final children = getFolderChildren(folderId);
    for (var child in children) {
      await deleteFolder(child.id);
    }

    // 删除文件夹中的笔记（同时删除文件）
    final folderNotes = _notes[folderId] ?? [];
    for (final note in folderNotes) {
      await _deleteNoteFile(note.id);
      _noteIds.remove(note.id);
    }
    _notes.remove(folderId);
    _folders.remove(folderId);

    await _saveFolders();
    await _saveNoteIndex(_noteIds.toList());

    // 同步小组件数据
    await _syncWidget();
  }

  // 同步小组件数据
  Future<void> _syncWidget() async {
    await PluginWidgetSyncHelper.instance.syncNotes();
  }

  /// 触发缓存更新事件（携带最新数据）
  void _notifyCacheUpdatedEvent() {
    final eventArgs = NotesCacheUpdatedEventArgs(
      folders: _folders.values.map((f) => f.toJson()).toList(),
      noteIds: _noteIds.toList(),
      cacheDate: DateTime.now(),
    );
    EventManager.instance.broadcast('notes_cache_updated', eventArgs);
  }
}
