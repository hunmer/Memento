import 'dart:io';
import 'package:Memento/core/storage/storage_manager.dart';
import 'package:Memento/core/utils/file_utils.dart';
import 'package:Memento/core/utils/zip.dart';
import 'package:Memento/l10n/app_localizations.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  Directory? currentDirectory;
  List<FileSystemEntity> files = [];
  Map<String, bool> selectedItems = {};
  Stack<Directory> directoryStack = Stack<Directory>();

  @override
  void initState() {
    super.initState();
    _loadDocumentsDirectory();
  }

  Future<void> _loadDocumentsDirectory() async {
    try {
      final dir = await StorageManager.getApplicationDocumentsDirectory();
      setState(() {
        currentDirectory = dir;
        directoryStack.push(dir);
      });
      await _refreshFiles();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('无法加载文档目录: ${e.toString()}')));
      debugPrint('Documents directory load error: ${e.toString()}');
    }
  }

  Future<void> _refreshFiles() async {
    if (currentDirectory == null) return;

    try {
      final items = await currentDirectory!.list().toList();
      setState(() {
        files = items;
        files.sort((a, b) {
          if (a is Directory && b is! Directory) return -1;
          if (a is! Directory && b is Directory) return 1;
          return a.path.compareTo(b.path);
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('无法访问目录: ${e.toString()}')));
      debugPrint('Directory access error: ${e.toString()}');
    }
  }

  void _toggleSelection(String path, bool isDirectory) {
    setState(() {
      if (isDirectory) {
        final dir = Directory(path);
        final children = dir.listSync(recursive: true);
        final allSelected =
            !selectedItems.containsKey(path) || !selectedItems[path]!;

        selectedItems[path] = allSelected;
        for (var child in children) {
          selectedItems[child.path] = allSelected;
        }
      } else {
        selectedItems.update(path, (value) => !value, ifAbsent: () => true);
      }
    });
  }

  Future<void> _deleteSelected() async {
    final selectedPaths =
        selectedItems.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList();

    if (selectedPaths.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('确认删除'),
            content: Text('确定要删除选中的 ${selectedPaths.length} 个项目吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('删除', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      for (var path in selectedPaths) {
        final entity =
            FileSystemEntity.isDirectorySync(path)
                ? Directory(path)
                : File(path);
        await entity.delete(recursive: true);
      }
      setState(() {
        selectedItems.clear();
        _refreshFiles();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('删除成功')));
    }
  }

  Future<void> _moveSelected() async {
    final selectedPaths =
        selectedItems.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList();

    if (selectedPaths.isEmpty) return;

    final appDir = await StorageManager.getApplicationDocumentsDirectory();
    final targetDir = await showDialog<Directory>(
      context: context,
      builder:
          (context) => FolderPickerDialog(
            rootDirectory: appDir,
            initialDirectory: currentDirectory ?? appDir,
          ),
    );

    if (targetDir != null) {
      try {
        for (var sourcePath in selectedPaths) {
          final fileName = path.basename(sourcePath);
          final targetPath = path.join(targetDir.path, fileName);
          await File(sourcePath).rename(targetPath);
        }
        setState(() {
          selectedItems.clear();
          _refreshFiles();
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('移动成功')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('移动失败: ${e.toString()}')));
      }
    }
  }

  Future<void> _renameItem(String oldPath, bool isDirectory) async {
    final nameController = TextEditingController(text: path.basename(oldPath));
    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.rename),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: '输入新名称'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, nameController.text),
                child: Text(AppLocalizations.of(context)!.ok),
              ),
            ],
          ),
    );

    if (result != null && result.isNotEmpty) {
      final newPath = path.join(path.dirname(oldPath), result);
      try {
        if (isDirectory) {
          await Directory(oldPath).rename(newPath);
        } else {
          await File(oldPath).rename(newPath);
        }
        _refreshFiles();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('重命名失败: ${e.toString()}')));
      }
    }
  }

  void _showContextMenu(String itemPath, bool isDirectory) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isDirectory)
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: Text(AppLocalizations.of(context)!.edit),
                  onTap: () {
                    Navigator.pop(context);
                    // 这里可以添加编辑文件的逻辑
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('编辑功能待实现')));
                  },
                ),
              ListTile(
                leading: const Icon(Icons.drive_file_rename_outline),
                title: Text(AppLocalizations.of(context)!.rename),
                onTap: () {
                  Navigator.pop(context);
                  _renameItem(itemPath, isDirectory);
                },
              ),
            ],
          ),
    );
  }

  Future<void> _importFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result != null && result.files.isNotEmpty) {
      int successCount = 0;
      int failCount = 0;

      for (var platformFile in result.files) {
        try {
          final file = File(platformFile.path!);
          final targetPath = path.join(
            currentDirectory!.path,
            path.basename(platformFile.name),
          );

          // 覆盖已存在的文件
          if (await File(targetPath).exists()) {
            await File(targetPath).delete();
          }

          await file.copy(targetPath);
          successCount++;
        } catch (e) {
          failCount++;
          debugPrint('导入文件失败: ${e.toString()}');
        }
      }

      _refreshFiles();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入完成: 成功 $successCount 个, 失败 $failCount 个')),
      );
    }
  }

  Future<void> _exportSelected() async {
    final selectedPaths =
        selectedItems.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList();

    if (selectedPaths.isEmpty) return;

    try {
      // 创建一个临时目录来存储要压缩的文件
      final tempDir = await Directory.systemTemp.createTemp('memento_temp_');

      // 复制选中的文件/目录到临时目录
      for (var filePath in selectedPaths) {
        final fileName = path.basename(filePath);
        final targetPath = path.join(tempDir.path, fileName);

        if (FileSystemEntity.isDirectorySync(filePath)) {
          await FileUtils.copyDirectory(
            Directory(filePath),
            Directory(targetPath),
          );
        } else {
          await File(filePath).copy(targetPath);
        }
      }

      // 创建临时 ZIP 文件
      final tempZipPath = '${tempDir.path}/memento_export.zip';
      final zipFile = ZipFileEncoder();
      zipFile.create(tempZipPath);

      // 添加所有文件到ZIP
      await for (final entity in tempDir.list(recursive: true)) {
        if (entity is File) {
          final relativePath = path.relative(entity.path, from: tempDir.path);
          await zipFile.addFile(entity, relativePath);
        }
      }

      zipFile.close();
      final savePath = await exportZIP(
        tempZipPath,
        'memento_export_${DateTime.now().millisecondsSinceEpoch}.zip',
      );

      if (savePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出成功到: $savePath'),
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('导出已取消')));
      }

      // 删除临时目录
      await tempDir.delete(recursive: true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('导出失败: ${e.toString()}'),
          duration: const Duration(seconds: 5),
        ),
      );
      debugPrint('Export error: ${e.toString()}');
      debugPrintStack();
    }
  }

  void _navigateToDirectory(Directory dir) {
    setState(() {
      currentDirectory = dir;
      directoryStack.push(dir);
      _refreshFiles();
    });
  }

  void _navigateUp() {
    if (directoryStack.length > 1) {
      setState(() {
        directoryStack.pop(); // Remove current
        currentDirectory = directoryStack.peek();
        _refreshFiles();
      });
    }
  }

  Future<void> _createNewFile() async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('新建文件'),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: '输入文件名'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, nameController.text),
                child: Text(AppLocalizations.of(context)!.create),
              ),
            ],
          ),
    );

    if (result != null && result.isNotEmpty) {
      final filePath = path.join(currentDirectory!.path, result);
      await File(filePath).create();
      _refreshFiles();
    }
  }

  Future<void> _createNewFolder() async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('新建文件夹'),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: '输入文件夹名'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, nameController.text),
                child: Text(AppLocalizations.of(context)!.create),
              ),
            ],
          ),
    );

    if (result != null && result.isNotEmpty) {
      final dirPath = path.join(currentDirectory!.path, result);
      await Directory(dirPath).create();
      _refreshFiles();
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(currentDirectory?.path.split('/').last ?? '数据管理'),
        leading:
            directoryStack.length > 1
                ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _navigateUp,
                )
                : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshFiles,
            tooltip: '刷新',
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _importFiles,
            tooltip: '导入文件',
          ),
          if (selectedItems.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelected,
              tooltip: '删除选中项',
            ),
            IconButton(
              icon: const Icon(Icons.drive_file_move),
              onPressed: _moveSelected,
              tooltip: '移动选中项',
            ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _exportSelected,
              tooltip: '导出选中项',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child:
                currentDirectory == null
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                      itemCount: files.length,
                      itemBuilder: (context, index) {
                        final file = files[index];
                        final isDirectory = file is Directory;
                        return ListTile(
                          leading:
                              isDirectory
                                  ? const Icon(
                                    Icons.folder,
                                    color: Colors.amber,
                                  )
                                  : const Icon(Icons.insert_drive_file),
                          title: Text(path.basename(file.path)),
                          subtitle:
                              isDirectory
                                  ? null
                                  : Text(
                                    _formatFileSize(
                                      (file as File).lengthSync(),
                                    ),
                                  ),
                          trailing: Checkbox(
                            value: selectedItems[file.path] ?? false,
                            onChanged:
                                (value) =>
                                    _toggleSelection(file.path, isDirectory),
                          ),
                          onTap: () {
                            if (isDirectory) {
                              _navigateToDirectory(file);
                            }
                          },
                          onLongPress: () {
                            _showContextMenu(file.path, isDirectory);
                          },
                        );
                      },
                    ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.create_new_folder),
                    label: const Text('新建文件夹'),
                    onPressed: _createNewFolder,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.note_add),
                    label: const Text('新建文件'),
                    onPressed: _createNewFile,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FolderPickerDialog extends StatefulWidget {
  final Directory rootDirectory;
  final Directory initialDirectory;

  const FolderPickerDialog({
    super.key,
    required this.rootDirectory,
    required this.initialDirectory,
  });

  @override
  State<FolderPickerDialog> createState() => _FolderPickerDialogState();
}

class _FolderPickerDialogState extends State<FolderPickerDialog> {
  late Directory currentDirectory;
  List<FileSystemEntity> folders = [];
  bool isLoading = false;
  String? errorMessage;
  final Stack<Directory> directoryStack = Stack<Directory>();

  @override
  void initState() {
    super.initState();
    currentDirectory = widget.initialDirectory;
    directoryStack.push(currentDirectory);
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final items = await currentDirectory.list().toList();
      final dirs = items.whereType<Directory>().toList();
      dirs.sort((a, b) => a.path.compareTo(b.path));

      setState(() {
        folders = [
          Directory('..'), // 特殊项表示跳到上级目录
          ...dirs,
        ];
      });
    } catch (e) {
      setState(() {
        errorMessage = '无法加载目录: ${e.toString()}';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _navigateTo(Directory dir) async {
    setState(() {
      currentDirectory = dir;
    });
    await _loadFolders();
    directoryStack.push(dir);
  }

  Future<void> _navigateUp() async {
    if (directoryStack.length > 1) {
      directoryStack.pop();
      setState(() {
        currentDirectory = directoryStack.peek();
      });
      await _loadFolders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Expanded(
            child: Text(
              path.basename(currentDirectory.path),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                ? Center(child: Text(errorMessage!))
                : folders.isEmpty
                ? const Center(child: Text('没有子目录'))
                : ListView.builder(
                  shrinkWrap: true,
                  itemCount: folders.length,
                  itemBuilder: (context, index) {
                    final folder = folders[index] as Directory;
                    return ListTile(
                      leading:
                          folder.path == '..'
                              ? const Icon(Icons.arrow_upward)
                              : const Icon(Icons.folder, color: Colors.amber),
                      title:
                          folder.path == '..'
                              ? const Text('跳到上级目录')
                              : Text(path.basename(folder.path)),
                      onTap:
                          folder.path == '..'
                              ? () => _navigateUp()
                              : () => _navigateTo(folder),
                    );
                  },
                ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, currentDirectory),
          child: const Text('选择'),
        ),
      ],
    );
  }
}

class Stack<T> {
  final List<T> _items = [];

  void push(T item) => _items.add(item);
  T pop() => _items.removeLast();
  T peek() => _items.last;
  int get length => _items.length;
}
