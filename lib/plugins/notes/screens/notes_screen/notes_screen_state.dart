import 'package:flutter/material.dart';
import '../../controllers/notes_controller.dart';
import '../../models/folder.dart';
import '../../models/note.dart';
import '../note_edit_screen.dart';
import '../notes_screen.dart';

class NotesScreenState extends State<NotesScreen> {
  @protected
  String currentFolderId = 'root';
  @protected
  Folder? currentFolder;
  @protected
  List<Folder> subFolders = [];
  @protected
  List<Note> notes = [];
  @protected
  bool isSearching = false;
  @protected
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadCurrentFolder();
  }

  @protected
  void loadCurrentFolder() {
    setState(() {
      currentFolder = widget.controller.getFolder(currentFolderId);
      subFolders = widget.controller.getFolderChildren(currentFolderId);
      notes = widget.controller.getFolderNotes(currentFolderId);
    });
  }

  @protected
  void navigateToFolder(Folder folder) {
    setState(() {
      currentFolderId = folder.id;
      loadCurrentFolder();
    });
  }

  @protected
  void navigateBack() {
    if (currentFolder?.parentId != null) {
      setState(() {
        currentFolderId = currentFolder!.parentId!;
        loadCurrentFolder();
      });
    }
  }

  @protected
  void handleSearch(String query) {
    if (query.isEmpty) {
      loadCurrentFolder();
    } else {
      final searchResults = widget.controller.searchNotes(query: query);
      setState(() {
        notes = searchResults;
        subFolders = [];
      });
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}
