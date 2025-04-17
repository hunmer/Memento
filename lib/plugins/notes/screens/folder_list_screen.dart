import 'package:flutter/material.dart';
import '../controllers/notes_controller.dart';
import '../models/folder.dart';
import '../models/note.dart';
import '../widgets/folder_item.dart';
import '../widgets/note_item.dart';
import 'note_edit_screen.dart';
import 'search_screen.dart';

class FolderListScreen extends StatefulWidget {
  final NotesController controller;

  const FolderListScreen({
    super.key,
    required this.controller,
  });

  @override
  State<FolderListScreen> createState() => _FolderListScreenState();
}

class _FolderListScreenState extends State<FolderListScreen> {
  String currentFolderId = 'root';
  List<Folder> folders = [];
  List<Note> notes = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentFolder();
  }

  void _loadCurrentFolder() {
    setState(() {
      folders = widget.controller.getFolderChildren(currentFolderId);
      notes = widget.controller.getFolderNotes(currentFolderId);
    });
  }

  void _navigateToFolder(Folder folder) {
    setState(() {
      currentFolderId = folder.id;
      _loadCurrentFolder();
    });
  }

  void _navigateBack() {
    final currentFolder = widget.controller.getFolder(currentFolderId);
    if (currentFolder?.parentId != null) {
      setState(() {
        currentFolderId = currentFolder!.parentId!;
        _loadCurrentFolder();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentFolder = widget.controller.getFolder(currentFolderId);

    return Scaffold(
      appBar: AppBar(
        leading: currentFolder?.parentId != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _navigateBack,
              )
            : null,
        title: Text(currentFolder?.name ?? 'Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchScreen(
                    controller: widget.controller,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ReorderableListView(
        onReorder: (oldIndex, newIndex) {
          // Implement reordering logic here
        },
        children: [
          ...folders.map((folder) => FolderItem(
                key: ValueKey(folder.id),
                folder: folder,
                onTap: () => _navigateToFolder(folder),
              )),
          ...notes.map((note) => NoteItem(
                key: ValueKey(note.id),
                note: note,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NoteEditScreen(
                        note: note,
                        onSave: (title, content) {
                          final updatedNote = note.copyWith(
                            title: title,
                            content: content,
                            updatedAt: DateTime.now(),
                          );
                          widget.controller.updateNote(updatedNote);
                        },
                      ),
                    ),
                  ).then((_) => _loadCurrentFolder());
                },
              )),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Create new'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.folder),
                    title: const Text('New folder'),
                    onTap: () {
                      Navigator.pop(context);
                      // Show folder creation dialog
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.note),
                    title: const Text('New note'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NoteEditScreen(
                            onSave: (title, content) {
                              widget.controller.createNote(title, content, currentFolderId);
                            },
                          ),
                        ),
                      ).then((_) => _loadCurrentFolder());
                    },
                  ),
                ],
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}