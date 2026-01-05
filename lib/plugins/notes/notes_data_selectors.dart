part of 'notes_plugin.dart';

  // ==================== 数据选择器注册 ====================

  void _registerDataSelectors() {
    // 注册笔记选择器
    pluginDataSelectorService.registerSelector(SelectorDefinition(
      id: 'notes.note',
      pluginId: NotesPlugin.instance.id,
      name: '选择笔记',
      icon: NotesPlugin.instance.icon,
      color: NotesPlugin.instance.color,
      searchable: true,
      selectionMode: SelectionMode.single,
      steps: [
        SelectorStep(
          id: 'note',
          title: '选择笔记',
          viewType: SelectorViewType.list,
          isFinalStep: true,
          dataLoader: (_) async {
            if (!NotesPlugin.instance._isInitialized) return [];

            // 获取所有笔记
            final allNotes = NotesPlugin.instance.controller.searchNotes(query: '');

            // 构建文件夹路径映射
            final folderPaths = <String, String>{};
            for (final folder in NotesPlugin.instance.controller.getAllFolders()) {
              folderPaths[folder.id] = _buildFolderPath(folder.id);
            }

            return allNotes.map((note) {
              final folderPath = folderPaths[note.folderId] ?? '';
              return SelectableItem(
                id: note.id,
                title: note.title,
                subtitle: folderPath.isNotEmpty ? '📁 $folderPath' : null,
                icon: Icons.note_outlined,
                rawData: note,
              );
            }).toList();
          },
          searchFilter: (items, query) {
            if (query.isEmpty) return items;
            final lowerQuery = query.toLowerCase();
            return items.where((item) {
              return item.title.toLowerCase().contains(lowerQuery) ||
                     (item.subtitle?.toLowerCase().contains(lowerQuery) ?? false);
            }).toList();
          },
        ),
      ],
    ));

    // 注册文件夹选择器
    pluginDataSelectorService.registerSelector(SelectorDefinition(
      id: 'notes.folder',
      pluginId: NotesPlugin.instance.id,
      name: 'notes_folderSelectorName'.tr,
      description: 'notes_folderSelectorDesc'.tr,
      icon: Icons.folder,
      color: NotesPlugin.instance.color,
      searchable: true,
      selectionMode: SelectionMode.single,
      steps: [
        SelectorStep(
          id: 'select_folder',
          title: 'notes_selectFolderTitle'.tr,
          viewType: SelectorViewType.list,
          dataLoader: (previousSelections) async {
            if (!NotesPlugin.instance._isInitialized) return [];

            // 获取所有文件夹（不包括 root）
            final allFolders = NotesPlugin.instance.controller.getAllFolders()
                .where((folder) => folder.id != 'root')
                .toList();

            return allFolders.map((folder) {
              // 获取文件夹中的笔记数量
              final notesCount = NotesPlugin.instance.controller.getFolderNotes(folder.id).length;

              // 构建文件夹路径
              final folderPath = _buildFolderPath(folder.id);

              return SelectableItem(
                id: folder.id,
                title: folder.name,
                subtitle: '$folderPath • $notesCount ${'notes_notesCount'.tr}',
                icon: folder.icon,
                color: folder.color,
                rawData: {
                  'id': folder.id,
                  'name': folder.name,
                  'parentId': folder.parentId,
                  'notesCount': notesCount,
                  'folderPath': folderPath,
                  'icon': folder.icon.codePoint,
                  'color': folder.color.value,
                },
              );
            }).toList();
          },
          searchFilter: (items, query) {
            if (query.isEmpty) return items;
            final lowerQuery = query.toLowerCase();
            return items.where((item) {
              return item.title.toLowerCase().contains(lowerQuery) ||
                     (item.subtitle?.toLowerCase().contains(lowerQuery) ?? false);
            }).toList();
          },
          isFinalStep: true,
        ),
      ],
    ));
  }

  /// 构建文件夹完整路径（用于显示在副标题）
  String _buildFolderPath(String folderId) {
    final folder = NotesPlugin.instance.controller.getFolder(folderId);
    if (folder == null || folder.id == 'root') return '';

    final pathParts = <String>[];
    var currentFolder = folder;

    while (currentFolder.id != 'root') {
      pathParts.insert(0, currentFolder.name);
      if (currentFolder.parentId != null) {
        final parent = NotesPlugin.instance.controller.getFolder(currentFolder.parentId!);
        if (parent != null) {
          currentFolder = parent;
        } else {
          break;
        }
      } else {
        break;
      }
    }

    return pathParts.join(' / ');
  }
