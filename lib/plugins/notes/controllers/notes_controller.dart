import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/storage/storage_manager.dart';
import '../models/folder.dart';
import '../models/note.dart';

class NotesController {
  final StorageManager _storage;
  final Map<String, Folder> _folders = {};
  final Map<String, List<Note>> _notes = {};

  NotesController(this._storage);

  Future<void> initialize() async {
    // 确保插件目录存在
    final pluginPath = _storage.getPluginStoragePath('notes');
    await _storage.ensureDirectoryExists('notes');
    
    await _loadFolders();
    await _loadNotes();
  }

  Future<void> _loadFolders() async {
    try {
      // 确保插件存储目录存在
      final pluginPath = _storage.getPluginStoragePath('notes');
      
      // 读取文件内容为字符串
      final data = await _storage.readString('$pluginPath/folders.json').catchError((_) => '');
      
      if (data.isNotEmpty) {
        final List<dynamic> jsonList = json.decode(data);
        for (var item in jsonList) {
          final folder = Folder.fromJson(item);
          _folders[folder.id] = folder;
        }
      } else {
        // 创建根文件夹
        final rootFolder = Folder(
          id: 'root',
          name: 'Root',
          parentId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _folders[rootFolder.id] = rootFolder;
        await _saveFolders();
      }
    } catch (e) {
      debugPrint('Error loading folders: $e');
      rethrow;
    }
  }

  Future<void> _loadNotes() async {
    try {
      // 获取插件存储路径
      final pluginPath = _storage.getPluginStoragePath('notes');
      
      // 读取文件内容为字符串
      final data = await _storage.readString('$pluginPath/notes.json').catchError((_) => '');
      
      if (data.isNotEmpty) {
        final List<dynamic> jsonList = json.decode(data);
        for (var item in jsonList) {
          final note = Note.fromJson(item);
          _notes.putIfAbsent(note.folderId, () => []).add(note);
        }
      }
    } catch (e) {
      debugPrint('Error loading notes: $e');
      rethrow;
    }
  }

  Future<void> _saveFolders() async {
    try {
      final pluginPath = _storage.getPluginStoragePath('notes');
      final jsonList = _folders.values.map((f) => f.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await _storage.writeString('$pluginPath/folders.json', jsonString);
    } catch (e) {
      debugPrint('Error saving folders: $e');
      rethrow;
    }
  }

  Future<void> _saveNotes() async {
    try {
      final pluginPath = _storage.getPluginStoragePath('notes');
      final allNotes = _notes.values.expand((notes) => notes).toList();
      final jsonList = allNotes.map((n) => n.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await _storage.writeString('$pluginPath/notes.json', jsonString);
    } catch (e) {
      debugPrint('Error saving notes: $e');
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
  
  // 获取指定文件夹的子文件夹
  List<Folder> getFolderChildren(String parentId) {
    return _folders.values
        .where((folder) => folder.parentId == parentId)
        .toList();
  }

  // 获取文件夹中的笔记
  List<Note> getFolderNotes(String folderId) {
    return _notes[folderId] ?? [];
  }

  // 创建新文件夹
  Future<Folder> createFolder(String name, String? parentId) async {
    final folder = Folder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
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
  Future<Note> createNote(String title, String content, String folderId) async {
    final note = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      folderId: folderId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _notes.putIfAbsent(folderId, () => []).add(note);
    await _saveNotes();
    return note;
  }

  // 更新笔记
  Future<void> updateNote(Note note) async {
    final notes = _notes[note.folderId];
    if (notes != null) {
      final index = notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        note.updatedAt = DateTime.now();
        notes[index] = note;
        await _saveNotes();
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
        notes.removeAt(noteIndex);
        await _saveNotes();
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
      
      // 保存更改
      await _saveNotes();
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
        if (note.tags == null || !tags.any((tag) => note.tags!.contains(tag))) {
          return false;
        }
      }

      // 日期范围匹配
      if (startDate != null && note.createdAt.isBefore(startDate)) {
        return false;
      }
      if (endDate != null) {
        final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
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

    // 删除文件夹中的笔记
    _notes.remove(folderId);
    _folders.remove(folderId);
    
    await _saveFolders();
    await _saveNotes();
  }
}