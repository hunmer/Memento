import 'notes_localizations.dart';

/// 中文本地化实现
class NotesLocalizationsZh extends NotesLocalizations {
  NotesLocalizationsZh() : super('zh');

  @override
  String get notesPluginName => '笔记';

  @override
  String get notesPluginDescription => 'Memento的简单笔记插件';

  @override
  String get totalNotes => '总笔记数';

  @override
  String get recentNotes => '最近笔记（7天）';

  @override
  String get newNote => '新建笔记';

  @override
  String get newFolder => '新建文件夹';

  @override
  String get editNote => '编辑';

  @override
  String get moveNote => '移动到';

  @override
  String get deleteNote => '删除';

  @override
  String get deleteNoteConfirm => '确定要删除这条笔记吗？此操作无法撤销。';

  @override
  String get renameFolder => '重命名文件夹';

  @override
  String get deleteFolder => '删除文件夹';

  @override
  String get deleteFolderConfirm => '确定要删除此文件夹吗？文件夹中的所有内容将被删除且无法恢复。';

  @override
  String get emptyFolder => '此文件夹为空';

  @override
  String get searchHint => '搜索笔记...';

  @override
  String get search => '搜索';

  @override
  String get noSearchResults => '没有搜索结果';

  @override
  String get folders => '文件夹';

  @override
  String get notes => '笔记';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String get edit => '编辑';

  @override
  String get delete => '删除';

  @override
  String get moveTo => '移动到';

  @override
  String get folderNameHint => '文件夹名称';
}