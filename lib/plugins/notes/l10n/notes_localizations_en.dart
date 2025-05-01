import 'notes_localizations.dart';

/// 英文本地化实现
class NotesLocalizationsEn extends NotesLocalizations {
  NotesLocalizationsEn() : super('en');

  @override
  String get notesPluginName => 'Notes';

  @override
  String get notesPluginDescription => 'A simple note-taking plugin for Memento';

  @override
  String get totalNotes => 'Total Notes';

  @override
  String get recentNotes => 'Recent Notes (7 days)';

  @override
  String get newNote => 'New Note';

  @override
  String get newFolder => 'New Folder';

  @override
  String get editNote => 'Edit';

  @override
  String get moveNote => 'Move to';

  @override
  String get deleteNote => 'Delete';

  @override
  String get deleteNoteConfirm => 'Are you sure you want to delete this note? This action cannot be undone.';

  @override
  String get renameFolder => 'Rename Folder';

  @override
  String get deleteFolder => 'Delete Folder';

  @override
  String get deleteFolderConfirm => 'Are you sure you want to delete this folder? All content in this folder will be deleted and cannot be recovered.';

  @override
  String get emptyFolder => 'This folder is empty';

  @override
  String get searchHint => 'Search notes...';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get moveTo => 'Move to';

  @override
  String get folderNameHint => 'Folder name';
}