import 'package:Memento/core/plugin_manager.dart';
import 'package:flutter/material.dart';
import '../l10n/notes_localizations.dart';
import 'notes_screen/folder_item.dart';
import 'notes_screen/folder_operations.dart';
import 'notes_screen/folder_selection_dialog.dart';
import 'notes_screen/note_item.dart';
import 'notes_screen/note_operations.dart';
import 'notes_screen/notes_screen_state.dart';

class NotesMainView extends StatefulWidget {
  const NotesMainView({super.key});

  @override
  State<NotesMainView> createState() => _NotesMainViewState();
}

class _NotesMainViewState extends NotesMainViewState
    with
        FolderOperations,
        NoteOperations,
        FolderSelectionDialog,
        FolderItem,
        NoteItem {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed:
              () =>
                  currentFolder?.parentId != null
                      ? navigateBack()
                      : PluginManager.toHomeScreen(context),
        ),
        title:
            isSearching
                ? TextField(
                  controller: searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText:
                        NotesLocalizations.of(context).search,
                    border: InputBorder.none,
                  ),
                  onChanged: handleSearch,
                )
                : Text(currentFolder?.name ?? 'Root'),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (isSearching) {
                  searchController.clear();
                  loadCurrentFolder();
                }
                isSearching = !isSearching;
              });
            },
          ),
          PopupMenuButton(
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'new_folder',
                    child: ListTile(
                      leading: const Icon(Icons.create_new_folder),
                      title: Text(
                        NotesLocalizations.of(context).newFolder,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'new_note',
                    child: ListTile(
                      leading: const Icon(Icons.note_add),
                      title: Text(
                        NotesLocalizations.of(context).newNote,
                      ),
                    ),
                  ),
                ],
            onSelected: (value) {
              switch (value) {
                case 'new_folder':
                  createNewFolder();
                  break;
                case 'new_note':
                  createNewNote();
                  break;
              }
            },
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: createNewNote,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    return ListView(
      children: [
        if (subFolders.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              NotesLocalizations.of(context).folders,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            itemCount: subFolders.length,
            itemBuilder:
                (context, index) => buildFolderItem(subFolders[index], index),
          ),
        ],
        if (notes.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              NotesLocalizations.of(context).notes,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            itemCount: notes.length,
            itemBuilder: (context, index) => buildNoteItem(notes[index], index),
          ),
        ],
        if (subFolders.isEmpty && notes.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                isSearching
                    ? NotesLocalizations.of(context).noSearchResults
                    : NotesLocalizations.of(context).emptyFolder,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
      ],
    );
  }
}
