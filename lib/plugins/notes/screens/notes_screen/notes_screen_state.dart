import 'package:Memento/plugins/notes/notes_plugin.dart';
import 'package:flutter/material.dart';
import '../../models/folder.dart';
import '../../models/note.dart';
import '../notes_screen.dart';

class NotesMainViewState extends State<NotesMainView> {
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

  late NotesPlugin plugin;
  @override
  void initState() {
    super.initState();
    plugin = NotesPlugin.instance;
    loadCurrentFolder();
  }

  @protected
  void loadCurrentFolder() {
    setState(() {
      currentFolder = plugin.controller.getFolder(currentFolderId);
      subFolders = plugin.controller.getFolderChildren(currentFolderId);
      notes = plugin.controller.getFolderNotes(currentFolderId);
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
      final searchResults = plugin.controller.searchNotes(query: query);
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
    throw UnimplementedError();
  }
}
