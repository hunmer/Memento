import 'package:get/get.dart';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'notes_screen/folder_item.dart';
import 'notes_screen/folder_operations.dart';
import 'notes_screen/folder_selection_dialog.dart';
import 'notes_screen/note_card.dart';
import 'notes_screen/note_item.dart';
import 'notes_screen/note_operations.dart';
import 'notes_screen/notes_screen_state.dart';
import 'note_edit_screen.dart';

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
    return SuperCupertinoNavigationWrapper(
      title: Text(
        currentFolder?.name ?? 'notes_defaultFolderName'.tr,
        style: TextStyle(color: theme.textTheme.titleLarge?.color),
      ),
      largeTitle: 'notes_myNotes'.tr,
      automaticallyImplyLeading: !(Platform.isAndroid || Platform.isIOS),
      body: _buildBody(),
      enableLargeTitle: true,
      enableSearchBar: true,
      enableFilterBar: true,
      filterBarHeight: 50,
      filterBarChild: _buildFilterBar(),
      searchPlaceholder: 'notes_searchPlaceholder'.tr,
      onSearchChanged: _handleSearchChanged,
      onSearchSubmitted: _handleSearchSubmitted,
      actions: [
        IconButton(
          icon: Icon(
            isSearching ? Icons.close : Icons.more_vert,
            color: theme.iconTheme.color,
          ),
          onPressed: () {
            if (isSearching) {
              setState(() {
                searchController.clear();
                loadCurrentFolder();
                isSearching = false;
              });
            } else {
              _showMoreOptions();
            }
          },
        ),
      ],
      largeTitleActions: [

      ],
      onCollapsed: (isCollapsed) {
        if (isCollapsed) {
          _saveScrollPosition();
        }
      },
    );
  }

  /// 处理搜索文本变化
  void _handleSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        isSearching = false;
        loadCurrentFolder();
      });
    } else {
      setState(() {
        isSearching = true;
      });
      // 使用基类的搜索方法，然后应用标签和日期过滤
      handleSearch(query);
      // 应用额外的过滤条件
      if (_selectedTag != null || _selectedDate != null) {
        setState(() {
          notes = plugin.controller.searchNotes(
            query: query,
            tags: _selectedTag != null ? [_selectedTag!] : null,
            startDate: _selectedDate,
            endDate: _selectedDate,
          );
        });
      }
    }
  }

  /// 处理搜索提交
  void _handleSearchSubmitted(String query) {
    if (query.isNotEmpty) {
      _handleSearchChanged(query);
    }
  }

  /// 显示更多选项菜单
  void _showMoreOptions() {
    // 实现更多选项菜单
  }

  /// 保存滚动位置
  void _saveScrollPosition() {
    // 实现滚动位置保存
  }

  /// 构建过滤栏
  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              label: _selectedTag ?? 'notes_allTags'.tr,
              onTap: () {
                _showTagPicker();
              },
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              icon: Icons.calendar_today,
              label:
                  _selectedDate != null
                      ? DateFormat('yyyy/MM/dd').format(_selectedDate!)
                      : 'All Dates',
              onTap: () {
                _showDatePicker();
              },
            ),
            const SizedBox(width: 8),
            // 添加清除过滤器按钮
            if (_selectedTag != null || _selectedDate != null)
              _buildClearFilterButton(),
          ],
        ),
      ),
    );
  }

  /// 构建清除过滤器按钮
  Widget _buildClearFilterButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTag = null;
          _selectedDate = null;
          loadCurrentFolder();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.clear_all,
              size: 16,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 4),
            Text(
              'notes_clearAll'.tr,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
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
                  label: 'notes_newFolder'.tr,
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
                  label: 'notes_newNote'.tr,
                  onPressed: () {
                    setState(() {
                      _fabExpanded = false;
                    });
                    NavigationHelper.openContainer(
                      context,
                      (context) => NoteEditScreen(
                        onSave: (title, content) async {
                          await plugin.controller.createNote(
                            title,
                            content,
                            currentFolderId,
                          );
                          loadCurrentFolder();
                        },
                      ),
                    );
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
      label: Text(label, style: const TextStyle(fontSize: 14)),
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF607AFB),
      elevation: 4,
      heroTag: null, // 避免多个Fab的heroTag冲突
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // Subfolders Horizontal List (if any)
            if (subFolders.isNotEmpty)
              SliverToBoxAdapter(
                child: Container(
                  height: 50,
                  margin: const EdgeInsets.only(bottom: 16, top: 16),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: subFolders.length,
                    separatorBuilder:
                        (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final folder = subFolders[index];
                      return ActionChip(
                        avatar: const Icon(Icons.folder, size: 18),
                        label: Text(folder.name),
                        onPressed: () => navigateToFolder(folder),
                        backgroundColor: Theme.of(context).cardColor,
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).dividerColor.withOpacity(0.1),
                        ),
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
                            ? 'notes_noSearchResults'.tr
                            : 'notes_emptyFolder'.tr,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
        // FAB
        Positioned(bottom: 16, right: 16, child: _buildExpandableFab()),
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
          color:
              isDark
                  ? const Color(0xFF27272A)
                  : const Color(0xFFE4E4E7), // Zinc 800 / 200
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
          title: Text('notes_selectFolder'.tr),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: allFolders.length,
              itemBuilder: (context, index) {
                final folder = allFolders[index];
                return ListTile(
                  leading: Icon(folder.icon, color: folder.color),
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
              child: Text('notes_cancel'.tr),
            ),
          ],
        );
      },
    );
  }

  /// 显示标签选择器
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
          title: Text('notes_selectTag'.tr),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child:
                tagsList.isEmpty
                    ? Center(child: Text('notes_noTagsAvailable'.tr))
                    : ListView.builder(
                      itemCount:
                          tagsList.length + 1, // +1 for "All Tags" option
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          // "All Tags" option
                          return ListTile(
                            leading: const Icon(Icons.label),
                            title: Text('notes_allTags'.tr),
                            onTap: () {
                              setState(() {
                                _selectedTag = null;
                                _applyFilters();
                              });
                              Navigator.pop(context);
                            },
                          );
                        }

                        final tag = tagsList[index - 1];
                        return ListTile(
                          leading: const Icon(Icons.label_outline),
                          title: Text(tag),
                          onTap: () {
                            setState(() {
                              _selectedTag = tag;
                              _applyFilters();
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
              child: Text('notes_cancel'.tr),
            ),
          ],
        );
      },
    );
  }

  /// 显示日期选择器
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
          _applyFilters();
        });
      }
    });
  }

  /// 应用当前过滤条件
  void _applyFilters() {
    setState(() {
      if (searchController.text.isNotEmpty) {
        // 如果有搜索文本，应用搜索 + 过滤
        notes = plugin.controller.searchNotes(
          query: searchController.text,
          tags: _selectedTag != null ? [_selectedTag!] : null,
          startDate: _selectedDate,
          endDate: _selectedDate,
        );
      } else {
        // 如果没有搜索文本，仅应用过滤
        if (_selectedTag != null || _selectedDate != null) {
          notes = plugin.controller.searchNotes(
            query: '',
            tags: _selectedTag != null ? [_selectedTag!] : null,
            startDate: _selectedDate,
            endDate: _selectedDate,
          );
        } else {
          loadCurrentFolder();
        }
      }
    });
  }
}
