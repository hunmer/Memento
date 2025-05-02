import 'package:flutter/material.dart';
import '../controllers/notes_controller.dart';

class NotesPromptReplacements {
  NotesController? _controller;

  void initialize(NotesController controller) {
    _controller = controller;
  }

  void dispose() {
    _controller = null;
  }

  /// 获取笔记信息的方法
  Future<String> getNotes(Map<String, dynamic> params) async {
    if (_controller == null) {
      return '{"error": "Notes controller is not initialized"}';
    }

    try {
      List<String> noteIds = [];
      
      // 处理folder_ids参数
      if (params.containsKey('folder_ids') && params['folder_ids'] is List) {
        List<String> folderIds = List<String>.from(params['folder_ids']);
        for (String folderId in folderIds) {
          // 获取文件夹下的所有笔记
          final folderNotes = _controller!.getFolderNotes(folderId);
          noteIds.addAll(folderNotes.map((note) => note.id));
        }
      }

      // 处理note_ids参数
      if (params.containsKey('note_ids') && params['note_ids'] is List) {
        List<String> specificNoteIds = List<String>.from(params['note_ids']);
        noteIds.addAll(specificNoteIds);
      }

      // 去重
      noteIds = noteIds.toSet().toList();

      // 获取笔记详细信息
      final List<Map<String, dynamic>> notesInfo = [];
      
      // 遍历所有笔记ID，查找匹配的笔记
      for (String noteId in noteIds) {
        // 使用空字符串作为查询条件，获取所有笔记
        final allNotes = _controller!.searchNotes(query: '');
        final noteIndex = allNotes.indexWhere((note) => note.id == noteId);
        
        if (noteIndex != -1) {
          final note = allNotes[noteIndex];
          notesInfo.add({
            'id': note.id,
            'title': note.title,
            'content': note.content,
            'folder_name': _controller!.getFolder(note.folderId)?.name ?? 'Unfiled',
          });
        }
      }

      return notesInfo.isEmpty 
          ? '{"error": "No notes found"}' 
          : '{"notes": ${notesInfo.toString()}}';
    } catch (e) {
      debugPrint('Error getting notes: $e');
      return '{"error": "Failed to get notes: $e"}';
    }
  }
}