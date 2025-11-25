import 'package:Memento/core/plugin_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import '../l10n/notes_localizations.dart';
import 'notes_screen/folder_item.dart';
import 'notes_screen/folder_operations.dart';
import 'notes_screen/folder_selection_dialog.dart';
import 'notes_screen/note_card.dart';
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

  bool _fabExpanded = false;
  String? _selectedTag;
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.iconTheme.color,
          ),
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
                    hintText: NotesLocalizations.of(context).search,
                    border: InputBorder.none,
                  ),
                  onChanged: handleSearch,
                )
                : Text(
                  currentFolder?.name ?? 'Root',
                  style: TextStyle(color: theme.textTheme.titleLarge?.color),
                ),
        actions: [
          IconButton(
            icon: Icon(
              isSearching ? Icons.close : Icons.search,
              color: theme.iconTheme.color,
            ),
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
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _buildExpandableFab(),
    );
  }

  Widget _buildExpandableFab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 子按钮 - 使用AnimatedOpacity实现平滑显示/隐藏
        AnimatedOpacity(
          opacity: _fabExpanded ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: !_fabExpanded,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildFabChild(
                  icon: Icons.create_new_folder,
                  label: NotesLocalizations.of(context).newFolder,
                  onPressed: () {
                    setState(() {
                      _fabExpanded = false;
                    });
                    createNewFolder();
                  },
                ),
                const SizedBox(height: 16),
                _buildFabChild(
                  icon: Icons.note_add,
                  label: NotesLocalizations.of(context).newNote,
                  onPressed: () {
                    setState(() {
                      _fabExpanded = false;
                    });
                    createNewNote();
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        // 主按钮
        FloatingActionButton(
          onPressed: () {
            setState(() {
              _fabExpanded = !_fabExpanded;
            });
          },
          backgroundColor: const Color(0xFF607AFB),
          child: AnimatedRotation(
            turns: _fabExpanded ? 0.45 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildFabChild({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(fontSize: 14),
      ),
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF607AFB),
      elevation: 4,
      heroTag: null, // 避免多个Fab的heroTag冲突
    );
  }

  Widget _buildBody() {
    return CustomScrollView(
      slivers: [
        // Filter Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    icon: Icons.folder_outlined,
                    label: currentFolder?.name ?? 'Root',
                    onTap: () {
                      _showFolderPicker();
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    icon: Icons.label_outline,
                    label: _selectedTag ?? 'All Tags',
                    onTap: () {
                      _showTagPicker();
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    icon: Icons.calendar_today,
                    label: _selectedDate != null
                        ? DateFormat('yyyy/MM/dd').format(_selectedDate!)
                        : DateFormat('yyyy/MM/dd').format(DateTime.now()),
                    onTap: () {
                      _showDatePicker();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Subfolders Horizontal List (if any)
        if (subFolders.isNotEmpty)
          SliverToBoxAdapter(
            child: Container(
              height: 50, // Adjust height as needed
              margin: const EdgeInsets.only(bottom: 16),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: subFolders.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final folder = subFolders[index];
                  return ActionChip(
                    avatar: const Icon(Icons.folder, size: 18),
                    label: Text(folder.name),
                    onPressed: () => navigateToFolder(folder),
                    backgroundColor: Theme.of(context).cardColor,
                    side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                  );
                },
              ),
            ),
          ),

        // Notes Grid
        if (notes.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childCount: notes.length,
              itemBuilder: (context, index) {
                return NoteCard(
                  note: notes[index],
                  onTap: () => editNote(notes[index]),
                );
              },
            ),
          ),

        // Empty State
        if (subFolders.isEmpty && notes.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.note_outlined,
                    size: 64,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isSearching
                        ? NotesLocalizations.of(context).noSearchResults
                        : NotesLocalizations.of(context).emptyFolder,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).disabledColor,
                        ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom padding for FAB
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7), // Zinc 800 / 200
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isDark ? const Color(0xFFD4D4D8) : const Color(0xFF52525B),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF27272A),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: isDark ? const Color(0xFFD4D4D8) : const Color(0xFF52525B),
            ),
          ],
        ),
      ),
    );
  }

  // 显示文件夹选择器
  void _showFolderPicker() {
    final allFolders = plugin.controller.getAllFolders();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('选择文件夹'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: allFolders.length,
              itemBuilder: (context, index) {
                final folder = allFolders[index];
                return ListTile(
                  leading: Icon(
                    folder.icon,
                    color: folder.color,
                  ),
                  title: Text(folder.name),
                  onTap: () {
                    setState(() {
                      // 导航到选中的文件夹
                      if (folder.id != currentFolder?.id) {
                        navigateToFolder(folder);
                      }
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消'),
            ),
          ],
        );
      },
    );
  }

  // 显示标签选择器
  void _showTagPicker() {
    // 获取所有笔记中的标签
    final allTags = <String>{};
    final allNotes = plugin.controller.getAllNotes();

    for (var noteList in allNotes.values) {
      for (var note in noteList) {
        for (var tag in note.tags) {
          allTags.add(tag);
        }
      }
    }

    final tagsList = allTags.toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('选择标签'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: tagsList.isEmpty
                ? Center(child: Text('暂无标签'))
                : ListView.builder(
                    itemCount: tagsList.length + 1, // +1 for "All Tags" option
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // "All Tags" option
                        return ListTile(
                          leading: Icon(Icons.label),
                          title: Text('All Tags'),
                          onTap: () {
                            setState(() {
                              _selectedTag = null;
                              // 这里可以添加清除标签过滤的逻辑
                            });
                            Navigator.pop(context);
                          },
                        );
                      }

                      final tag = tagsList[index - 1];
                      return ListTile(
                        leading: Icon(Icons.label_outline),
                        title: Text(tag),
                        onTap: () {
                          setState(() {
                            _selectedTag = tag;
                            // 这里可以添加按标签过滤的逻辑
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消'),
            ),
          ],
        );
      },
    );
  }

  // 显示日期选择器
  void _showDatePicker() {
    showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    ).then((selectedDate) {
      if (selectedDate != null) {
        setState(() {
          _selectedDate = selectedDate;
          // 这里可以添加按日期过滤的逻辑
        });
      }
    });
  }
}
