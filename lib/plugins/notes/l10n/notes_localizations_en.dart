import 'notes_localizations.dart';

/// 英文本地化实现
class NotesLocalizationsEn extends NotesLocalizations {
  NotesLocalizationsEn() : super('en');

  @override
  String get name => 'Notes';

  @override
  String get notesPluginDescription =>
      'A simple note-taking plugin for Memento';

  @override
  String get totalNotes => 'Total';

  @override
  String get recentNotes => 'Recent';

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
  String get deleteNoteConfirm =>
      'Are you sure you want to delete this note? This action cannot be undone.';

  @override
  String get renameFolder => 'Rename Folder';

  @override
  String get deleteFolder => 'Delete Folder';

  @override
  String get deleteFolderConfirm =>
      'Are you sure you want to delete this folder? All content in this folder will be deleted and cannot be recovered.';

  @override
  String get emptyFolder => 'This folder is empty';

  @override
  String get searchHint => 'Search notes...';

  @override
  String get search => 'Search';

  @override
  String get noSearchResults => 'No search results';

  @override
  String get folders => 'Folders';

  @override
  String get notes => 'Notes';

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

  @override
  String get createNew => 'Create new';
  @override
  String get movedTo => 'Moved to {folderName}';

  @override
  String get filter => 'Filter';

  @override
  String get tags => 'Tags';

  @override
  String get dateRange => 'Date Range';

  @override
  String get clearAll => 'Clear All';

  @override
  String get apply => 'Apply';

  @override
  String get typeToSearch => 'Type to search';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get movedToFolder => 'Moved to {folderName}';

  @override
  String get selectSubfolder => 'Select subfolder';
}
