import 'package:flutter/material.dart';
import '../controllers/notes_controller.dart';
import '../models/folder.dart';
import '../models/note.dart';
import 'note_edit_screen.dart';

class NotesScreen extends StatefulWidget {
  final NotesController controller;

  const NotesScreen({super.key, required this.controller});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String _currentFolderId = 'root';
  Folder? _currentFolder;
  List<Folder> _subFolders = [];
  List<Note> _notes = [];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentFolder();
  }

  void _loadCurrentFolder() {
    setState(() {
      _currentFolder = widget.controller.getFolder(_currentFolderId);
      _subFolders = widget.controller.getFolderChildren(_currentFolderId);
      _notes = widget.controller.getFolderNotes(_currentFolderId);
    });
  }

  void _navigateToFolder(Folder folder) {
    setState(() {
      _currentFolderId = folder.id;
      _loadCurrentFolder();
    });
  }

  void _navigateBack() {
    if (_currentFolder?.parentId != null) {
      setState(() {
        _currentFolderId = _currentFolder!.parentId!;
        _loadCurrentFolder();
      });
    }
  }

  Future<void> _createNewNote() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => NoteEditScreen(
              onSave: (title, content) async {
                await widget.controller.createNote(
                  title,
                  content,
                  _currentFolderId,
                );
              },
            ),
      ),
    );
    _loadCurrentFolder();
  }

  Future<void> _editNote(Note note) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => NoteEditScreen(
              note: note,
              onSave: (title, content) async {
                final updatedNote = Note(
                  id: note.id,
                  title: title,
                  content: content,
                  folderId: note.folderId,
                  createdAt: note.createdAt,
                  updatedAt: DateTime.now(),
                  tags: note.tags,
                );
                await widget.controller.updateNote(updatedNote);
              },
            ),
      ),
    );
    _loadCurrentFolder();
  }

  Future<void> _createNewFolder() async {
    final TextEditingController folderNameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('新建文件夹'),
            content: TextField(
              controller: folderNameController,
              autofocus: true,
              decoration: const InputDecoration(hintText: '文件夹名称'),
              onSubmitted: (value) => Navigator.pop(context, value),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, folderNameController.text);
                },
                child: const Text('确定'),
              ),
            ],
          ),
    );
    if (result != null && result.isNotEmpty) {
      await widget.controller.createFolder(result, _currentFolderId);
      _loadCurrentFolder();
    }
  }

  void _handleSearch(String query) {
    if (query.isEmpty) {
      _loadCurrentFolder();
    } else {
      final searchResults = widget.controller.searchNotes(query: query);
      setState(() {
        _notes = searchResults;
        _subFolders = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading:
            _currentFolder?.parentId != null
                ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _navigateBack,
                )
                : null,
        title:
            _isSearching
                ? TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: '搜索笔记...',
                    border: InputBorder.none,
                  ),
                  onChanged: _handleSearch,
                )
                : Text(_currentFolder?.name ?? 'Notes'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _loadCurrentFolder();
                }
              });
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'new_note':
                  _createNewNote();
                  break;
                case 'new_folder':
                  _createNewFolder();
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'new_note',
                    child: ListTile(
                      leading: Icon(Icons.note_add),
                      title: Text('新建笔记'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'new_folder',
                    child: ListTile(
                      leading: Icon(Icons.create_new_folder),
                      title: Text('新建文件夹'),
                    ),
                  ),
                ],
          ),
        ],
      ),
      body:
          _subFolders.isEmpty && _notes.isEmpty
              ? const Center(child: Text('此文件夹为空'))
              : ReorderableListView.builder(
                onReorder: (oldIndex, newIndex) {
                  // 实现排序逻辑
                  setState(() {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }

                    if (oldIndex < _subFolders.length &&
                        newIndex < _subFolders.length) {
                      // 文件夹之间的排序
                      final item = _subFolders.removeAt(oldIndex);
                      _subFolders.insert(newIndex, item);
                    } else if (oldIndex >= _subFolders.length &&
                        newIndex >= _subFolders.length) {
                      // 笔记之间的排序
                      final noteOldIndex = oldIndex - _subFolders.length;
                      final noteNewIndex = newIndex - _subFolders.length;
                      final item = _notes.removeAt(noteOldIndex);
                      _notes.insert(noteNewIndex, item);
                    }
                    // 不允许文件夹和笔记之间混排
                  });
                },
                itemCount: _subFolders.length + _notes.length,
                itemBuilder: (context, index) {
                  if (index < _subFolders.length) {
                    final folder = _subFolders[index];
                    return ListTile(
                      key: Key('folder_${folder.id}'),
                      leading: const Icon(Icons.folder),
                      title: Text(folder.name),
                      onTap: () => _navigateToFolder(folder),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder:
                                (context) => Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.edit),
                                      title: const Text('重命名'),
                                      onTap: () async {
                                        Navigator.pop(context);
                                        final TextEditingController
                                        renameController =
                                            TextEditingController(
                                              text: folder.name,
                                            );
                                        final result = await showDialog<String>(
                                          context: context,
                                          builder:
                                              (context) => AlertDialog(
                                                title: const Text('重命名文件夹'),
                                                content: TextField(
                                                  controller: renameController,
                                                  autofocus: true,
                                                  decoration:
                                                      const InputDecoration(
                                                        hintText: '文件夹名称',
                                                      ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          context,
                                                        ),
                                                    child: const Text('取消'),
                                                  ),
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          context,
                                                          renameController.text,
                                                        ),
                                                    child: const Text('确定'),
                                                  ),
                                                ],
                                              ),
                                        );
                                        renameController.dispose();

                                        if (result != null &&
                                            result.isNotEmpty) {
                                          await widget.controller.renameFolder(
                                            folder.id,
                                            result,
                                          );
                                          _loadCurrentFolder();
                                        }
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      title: const Text(
                                        '删除',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                      onTap: () async {
                                        Navigator.pop(context);
                                        final confirmed = await showDialog<
                                          bool
                                        >(
                                          context: context,
                                          builder:
                                              (context) => AlertDialog(
                                                title: const Text('删除文件夹'),
                                                content: const Text(
                                                  '确定要删除此文件夹吗？此操作将删除文件夹中的所有内容，且不可恢复。',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          context,
                                                          false,
                                                        ),
                                                    child: const Text('取消'),
                                                  ),
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          context,
                                                          true,
                                                        ),
                                                    child: const Text(
                                                      '删除',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                        );

                                        if (confirmed == true) {
                                          await widget.controller.deleteFolder(
                                            folder.id,
                                          );
                                          _loadCurrentFolder();
                                        }
                                      },
                                    ),
                                  ],
                                ),
                          );
                        },
                      ),
                    );
                  } else {
                    final note = _notes[index - _subFolders.length];
                    return ListTile(
                      key: Key('note_${note.id}'),
                      leading: const Icon(Icons.note),
                      title: Text(note.title),
                      subtitle: Text(
                        note.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _editNote(note),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder:
                                (context) => Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.edit),
                                      title: const Text('编辑'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _editNote(note);
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.folder),
                                      title: const Text('移动到'),
                                      onTap: () async {
                                        Navigator.pop(context);
                                        final targetFolder =
                                            await _showFolderSelectionDialog(
                                              note,
                                            );
                                        if (targetFolder != null) {
                                          await widget.controller.moveNote(
                                            note.id,
                                            targetFolder.id,
                                          );
                                          _loadCurrentFolder(); // 刷新当前文件夹视图
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  '已移动到 ${targetFolder.name}',
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      title: const Text(
                                        '删除',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                      onTap: () async {
                                        Navigator.pop(context);
                                        final confirmed =
                                            await showDialog<bool>(
                                              context: context,
                                              builder:
                                                  (context) => AlertDialog(
                                                    title: const Text('删除笔记'),
                                                    content: const Text(
                                                      '确定要删除此笔记吗？此操作不可恢复。',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              context,
                                                              false,
                                                            ),
                                                        child: const Text('取消'),
                                                      ),
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              context,
                                                              true,
                                                            ),
                                                        child: const Text(
                                                          '删除',
                                                          style: TextStyle(
                                                            color: Colors.red,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                            );

                                        if (confirmed == true) {
                                          await widget.controller.deleteNote(
                                            note.id,
                                          );
                                          _loadCurrentFolder();
                                        }
                                      },
                                    ),
                                  ],
                                ),
                          );
                        },
                      ),
                    );
                  }
                },
              ),
    );
  }

  // 递归构建文件夹树形结构
  Widget _buildFolderTree(Folder folder, {bool isRoot = false}) {
    final children = widget.controller.getFolderChildren(folder.id);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isRoot) // 根文件夹不显示自身
          ListTile(
            leading: Icon(folder.icon),
            title: Text(folder.name),
            trailing:
                children.isNotEmpty ? const Icon(Icons.arrow_right) : null,
            onTap: () async {
              if (children.isEmpty) {
                // 如果没有子文件夹，直接选择当前文件夹
                Navigator.pop(context, folder);
              } else {
                // 如果有子文件夹，显示子文件夹选择对话框
                final selectedFolder = await _showFolderSelectionDialog(
                  null,
                  parentFolder: folder,
                );
                if (selectedFolder != null && mounted) {
                  Navigator.pop(context, selectedFolder);
                }
              }
            },
          ),
        if (children.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  children.map((child) => _buildFolderTree(child)).toList(),
            ),
          ),
      ],
    );
  }

  // 显示文件夹选择对话框
  Future<Folder?> _showFolderSelectionDialog(
    Note? note, {
    Folder? parentFolder,
  }) async {
    final rootFolder = widget.controller.getFolder('root')!;

    // 如果指定了父文件夹，则只显示该文件夹的子文件夹
    final startFolder = parentFolder ?? rootFolder;

    // 获取当前笔记所在的文件夹ID
    final currentFolderId = note?.folderId ?? _currentFolder?.id;

    return showDialog<Folder>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(parentFolder != null ? '选择子文件夹' : '选择目标文件夹'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFolderTree(
                    startFolder,
                    isRoot: startFolder.id == 'root',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              if (parentFolder != null && parentFolder.id != currentFolderId)
                TextButton(
                  onPressed: () => Navigator.pop(context, parentFolder),
                  child: const Text('选择当前文件夹'),
                ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
