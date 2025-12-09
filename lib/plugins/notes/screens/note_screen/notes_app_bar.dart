import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/notes/models/folder.dart';

class NotesAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Folder? currentFolder;
  final bool isSearching;
  final TextEditingController searchController;
  final VoidCallback onNavigateBack;
  final VoidCallback onSearchToggle;
  final Function(String) onSearch;
  final VoidCallback onCreateNewNote;
  final VoidCallback onCreateNewFolder;

  const NotesAppBar({
    super.key,
    required this.currentFolder,
    required this.isSearching,
    required this.searchController,
    required this.onNavigateBack,
    required this.onSearchToggle,
    required this.onSearch,
    required this.onCreateNewNote,
    required this.onCreateNewFolder,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading:
          currentFolder?.parentId != null
              ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onNavigateBack,
              )
              : null,
      title:
          isSearching
              ? TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  hintText: '搜索笔记...',
                  border: InputBorder.none,
                ),
                onChanged: onSearch,
              )
              : Text(currentFolder?.name ?? 'Notes'),
      actions: [
        IconButton(
          icon: Icon(isSearching ? Icons.close : Icons.search),
          onPressed: onSearchToggle,
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'new_note':
                onCreateNewNote();
                break;
              case 'new_folder':
                onCreateNewFolder();
                break;
            }
          },
          itemBuilder:
              (context) => [
                PopupMenuItem(
                  value: 'new_note',
                  child: ListTile(
                    leading: const Icon(Icons.note_add),
                    title: Text('notes_newNote'.tr),
                  ),
                ),
                PopupMenuItem(
                  value: 'new_folder',
                  child: ListTile(
                    leading: const Icon(Icons.create_new_folder),
                    title: Text('notes_newFolder'.tr),
                  ),
                ),
              ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
