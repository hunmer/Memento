import 'package:flutter/material.dart';
import 'package:Memento/plugins/notes/controllers/notes_controller.dart';
import 'package:Memento/plugins/notes/models/folder.dart';
import 'package:Memento/plugins/notes/models/note.dart';
import 'notes_app_bar.dart';
import 'notes_list_view.dart';
import 'folder_selection_dialog.dart';
import 'folder_operations.dart';
import 'note_operations.dart';

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
      appBar: NotesAppBar(
        currentFolder: _currentFolder,
        isSearching: _isSearching,
        searchController: _searchController,
        onNavigateBack: _navigateBack,
        onSearchToggle: () {
          setState(() {
            _isSearching = !_isSearching;
            if (!_isSearching) {
              _searchController.clear();
              _loadCurrentFolder();
            }
          });
        },
        onSearch: _handleSearch,
        onCreateNewNote: () async {
          await createNewNote(
            context,
            widget.controller,
            _currentFolderId,
            _loadCurrentFolder,
          );
        },
        onCreateNewFolder: () async {
          await createNewFolder(
            context,
            widget.controller,
            _currentFolderId,
            _loadCurrentFolder,
          );
        },
      ),
      body: NotesListView(
        subFolders: _subFolders,
        notes: _notes,
        controller: widget.controller,
        onNavigateToFolder: _navigateToFolder,
        onReload: _loadCurrentFolder,
        onShowFolderSelectionDialog:
            (note, {parentFolder}) => showFolderSelectionDialog(
              context,
              widget.controller,
              note,
              parentFolder: parentFolder,
              currentFolder: _currentFolder,
            ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
