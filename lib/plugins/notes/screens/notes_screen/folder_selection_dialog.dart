import 'package:get/get.dart';
import 'package:Memento/plugins/notes/models/folder.dart';
import 'package:Memento/plugins/notes/models/note.dart';
import 'package:Memento/plugins/notes/models/folder_tree_node.dart';
import 'package:Memento/plugins/notes/widgets/folder_selection_sheet.dart';
import 'notes_screen_state.dart';
import '../../../../../../core/services/toast_service.dart';

mixin FolderSelectionDialog on NotesMainViewState {
  // 显示文件夹选择底部抽屉
  Future<Folder?> showFolderSelectionDialog(
    Note? note, {
    Folder? parentFolder,
  }) async {
    final rootFolder = plugin.controller.getFolder('root')!;
    final allFolders = plugin.controller.getAllFolders();

    // 构建文件夹树
    final folderMap = <String, Folder>{};
    for (var folder in allFolders) {
      folderMap[folder.id] = folder;
    }

    // 从根文件夹开始构建树
    final rootNode = FolderTreeNode.buildTree(rootFolder, folderMap);

    // 显示底部抽屉
    return FolderSelectionSheet.show(
      context: context,
      rootNode: rootNode,
      note: note,
      parentFolder: parentFolder,
    );
  }

  Future<void> moveNote(Note note) async {
    final targetFolder = await showFolderSelectionDialog(note);
    if (targetFolder != null) {
      await plugin.controller.moveNote(note.id, targetFolder.id);
      loadCurrentFolder(); // 刷新当前文件夹视图
      toastService.showToast(
        'notes_movedToFolder'.trParams({'folderName': targetFolder.name}),
      );
    }
  }
}
