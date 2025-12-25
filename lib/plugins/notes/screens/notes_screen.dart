import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper/index.dart';
import 'package:Memento/widgets/folder_breadcrumbs.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/route/route_history_manager.dart';
import 'package:Memento/plugins/notes/models/folder.dart';
import 'package:Memento/plugins/notes/models/note.dart';
import 'package:Memento/plugins/notes/models/folder_tree_node.dart';
import 'package:Memento/plugins/notes/widgets/folder_selection_sheet.dart';
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

  /// 更新路由上下文，使"询问当前上下文"功能能获取到当前笔记列表的过滤状态
  void _updateRouteContext() {
    final folderName = currentFolder?.name ?? 'Root';
    final params = <String, String>{
      'folderId': currentFolderId,
      'folderName': folderName,
    };

    // 构建标题描述
    final titleParts = <String>['笔记列表 - $folderName'];

    // 添加标签过滤
    if (_selectedTag != null) {
      params['tag'] = _selectedTag!;
      titleParts.add('标签: $_selectedTag');
    }

    // 添加日期过滤
    if (_selectedDate != null) {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      params['date'] = dateStr;
      titleParts.add('日期: $dateStr');
    }

    // 添加搜索关键词
    if (isSearching && searchController.text.isNotEmpty) {
      params['searchQuery'] = searchController.text;
      titleParts.add('搜索: ${searchController.text}');
    }

    final title = titleParts.join(' | ');

    RouteHistoryManager.updateCurrentContext(
      pageId: '/notes_list',
      title: title,
      params: params,
    );
  }

  @override
  void initState() {
    super.initState();
    // 延迟执行以确保 currentFolder 已初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateRouteContext();
    });
  }

  @override
  void loadCurrentFolder() {
    super.loadCurrentFolder();
    _updateRouteContext();
  }

  @override
  void navigateToFolder(Folder folder) {
    super.navigateToFolder(folder);
    _updateRouteContext();
  }

  @override
  void navigateBack() {
    super.navigateBack();
    _updateRouteContext();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SuperCupertinoNavigationWrapper(
      title: Text(
        currentFolder?.name ?? 'notes_defaultFolderName'.tr,
        style: TextStyle(color: theme.textTheme.titleLarge?.color),
      ),
      largeTitle: 'notes_myNotes'.tr,

      body: _buildBody(),
      enableLargeTitle: true,
      enableSearchBar: true,
      enableMultiFilter: true,
      multiFilterItems: _buildFilterItems(),
      multiFilterBarHeight: 50,
      onMultiFilterChanged: _applyMultiFilters,
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
      largeTitleActions: [],
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
    // 更新路由上下文
    _updateRouteContext();
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
                    NavigationHelper.openContainerWithHero(
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

  /// 构建面包屑导航项
  List<FolderBreadcrumbItem> _buildBreadcrumbItems() {
    final path = plugin.controller.getFolderPath(currentFolderId);
    return path.map((folder) {
      return FolderBreadcrumbItem(id: folder.id, name: folder.name);
    }).toList();
  }

  Widget _buildBody() {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // Folder Breadcrumbs (显示当前文件夹路径)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16, top: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FolderBreadcrumbs(
                  folders: _buildBreadcrumbItems(),
                  onFolderTap: (folderId) {
                    // 点击面包屑导航到对应文件夹
                    setState(() {
                      currentFolderId = folderId;
                      loadCurrentFolder();
                    });
                  },
                ),
              ),
            ),

            // Subfolders Horizontal List (子文件夹列表)
            if (subFolders.isNotEmpty)
              SliverToBoxAdapter(
                child: Container(
                  height: 50,
                  margin: const EdgeInsets.only(bottom: 16),
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
                      onDelete: () => deleteNote(notes[index]),
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

  /// 显示文件夹选择器
  Future<Folder?> _showFolderPicker() async {
    final rootFolder = plugin.controller.getFolder('root')!;
    final allFolders = plugin.controller.getAllFolders();

    // 构建文件夹树
    final folderMap = <String, Folder>{};
    for (var folder in allFolders) {
      folderMap[folder.id] = folder;
    }

    final rootNode = FolderTreeNode.buildTree(rootFolder, folderMap);

    // 显示底部抽屉选择器
    final selectedFolder = await FolderSelectionSheet.show(
      context: context,
      rootNode: rootNode,
      note: null, // 不传递笔记，因为这是过滤而不是移动笔记
    );

    return selectedFolder;
  }

  /// 构建多条件过滤列表
  List<FilterItem> _buildFilterItems() {
    // 获取所有标签
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

    return [
      // 文件夹选择过滤
      FilterItem(
        id: 'folder',
        title: 'notes_folder'.tr,
        type: FilterType.custom,
        builder: (context, currentValue, onChanged) {
          final selectedFolder = currentValue as Folder?;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.folder_outlined, size: 16),
                label: Text(
                  selectedFolder?.name ?? 'notes_selectFolder'.tr,
                  style: const TextStyle(fontSize: 13),
                ),
                onPressed: () async {
                  final folder = await _showFolderPicker();
                  if (folder != null) {
                    onChanged(folder);
                  }
                },
              ),
              if (selectedFolder != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  onPressed: () => onChanged(null),
                ),
            ],
          );
        },
        getBadge: (value) {
          if (value is Folder) {
            return value.name;
          }
          return null;
        },
      ),

      // 标签多选过滤
      if (tagsList.isNotEmpty)
        FilterItem(
          id: 'tags',
          title: 'notes_tags'.tr,
          type: FilterType.tagsMultiple,
          builder: (context, currentValue, onChanged) {
            return FilterBuilders.buildTagsFilter(
              context: context,
              currentValue: currentValue,
              onChanged: onChanged,
              availableTags: tagsList,
            );
          },
          getBadge: FilterBuilders.tagsBadge,
        ),

      // 日期过滤
      FilterItem(
        id: 'date',
        title: 'notes_date'.tr,
        type: FilterType.date,
        builder: (context, currentValue, onChanged) {
          return FilterBuilders.buildDateFilter(
            context: context,
            currentValue: currentValue,
            onChanged: onChanged,
          );
        },
        getBadge: FilterBuilders.dateBadge,
      ),
    ];
  }

  /// 应用多条件过滤
  void _applyMultiFilters(Map<String, dynamic> filters) {
    setState(() {
      // 提取文件夹过滤
      final folderFilter = filters['folder'] as Folder?;

      // 提取标签过滤
      final tagFilters = filters['tags'] as List<String>?;

      // 提取日期过滤
      final dateFilter = filters['date'] as DateTime?;

      // 如果选择了文件夹过滤，先获取该文件夹的笔记
      List<Note> baseNotes;
      if (folderFilter != null) {
        baseNotes = plugin.controller.getFolderNotes(folderFilter.id);
      } else {
        // 否则使用当前文件夹的笔记
        baseNotes = plugin.controller.getFolderNotes(currentFolderId);
      }

      // 应用标签和日期过滤
      if (searchController.text.isNotEmpty ||
          (tagFilters != null && tagFilters.isNotEmpty) ||
          dateFilter != null) {
        // 对基础笔记列表应用额外过滤
        notes =
            baseNotes.where((note) {
              // 搜索文本过滤
              if (searchController.text.isNotEmpty) {
                final query = searchController.text.toLowerCase();
                if (!note.title.toLowerCase().contains(query) &&
                    !note.content.toLowerCase().contains(query)) {
                  return false;
                }
              }

              // 标签过滤
              if (tagFilters != null && tagFilters.isNotEmpty) {
                if (!tagFilters.any((tag) => note.tags.contains(tag))) {
                  return false;
                }
              }

              // 日期过滤
              if (dateFilter != null) {
                final noteDate = DateTime(
                  note.createdAt.year,
                  note.createdAt.month,
                  note.createdAt.day,
                );
                final filterDate = DateTime(
                  dateFilter.year,
                  dateFilter.month,
                  dateFilter.day,
                );
                if (!noteDate.isAtSameMomentAs(filterDate)) {
                  return false;
                }
              }

              return true;
            }).toList();
      } else {
        notes = baseNotes;
      }

      // 更新旧的状态变量（保持兼容性）
      _selectedTag =
          tagFilters != null && tagFilters.isNotEmpty ? tagFilters.first : null;
      _selectedDate = dateFilter;
    });

    // 更新路由上下文
    _updateRouteContext();
  }
}
