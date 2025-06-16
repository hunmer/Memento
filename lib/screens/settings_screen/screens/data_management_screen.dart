import 'dart:io';
import 'dart:typed_data';
import 'package:Memento/core/storage/storage_manager.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
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
    final dir = await StorageManager.getApplicationDocumentsDirectory();
    setState(() {
      currentDirectory = dir;
      directoryStack.push(dir);
      _refreshFiles();
    });
  }

  Future<void> _refreshFiles() async {
    if (currentDirectory != null) {
      setState(() {
        files = currentDirectory!.listSync();
        files.sort((a, b) {
          if (a is Directory && b is! Directory) return -1;
          if (a is! Directory && b is Directory) return 1;
          return a.path.compareTo(b.path);
        });
      });
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
                child: const Text('取消'),
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
            title: const Text('重命名'),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: '输入新名称'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, nameController.text),
                child: const Text('确定'),
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
                  title: const Text('编辑'),
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
                title: const Text('重命名'),
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

    final archive = Archive();
    for (var filePath in selectedPaths) {
      if (FileSystemEntity.isDirectorySync(filePath)) {
        _addDirectoryToArchive(archive, Directory(filePath));
      } else {
        final file = File(filePath);
        final data = await file.readAsBytes();
        archive.addFile(
          ArchiveFile(path.basename(filePath), data.length, data),
        );
      }
    }

    final encoder = ZipEncoder();
    final zipData = encoder.encode(archive);
    if (zipData != null) {
      final tempDir = await getTemporaryDirectory();
      final zipFile = File(
        path.join(
          tempDir.path,
          'export_${DateTime.now().millisecondsSinceEpoch}.zip',
        ),
      );
      await zipFile.writeAsBytes(zipData);

      final savePath = await FilePicker.platform.saveFile(
        fileName: 'data_export.zip',
        dialogTitle: '保存导出文件',
      );

      if (savePath != null) {
        await zipFile.copy(savePath);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('导出成功')));
      }
    }
  }

  void _addDirectoryToArchive(Archive archive, Directory directory) {
    final files = directory.listSync(recursive: true);
    for (var file in files) {
      if (file is File) {
        final relativePath = path.relative(
          file.path,
          from: directory.parent.path,
        );
        final data = file.readAsBytesSync();
        archive.addFile(ArchiveFile(relativePath, data.length, data));
      }
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
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, nameController.text),
                child: const Text('创建'),
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
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, nameController.text),
                child: const Text('创建'),
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
            icon: const Icon(Icons.create_new_folder),
            onPressed: _createNewFolder,
            tooltip: '新建文件夹',
          ),
          IconButton(
            icon: const Icon(Icons.note_add),
            onPressed: _createNewFile,
            tooltip: '新建文件',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshFiles,
            tooltip: '刷新',
          ),
          IconButton(
            icon: const Icon(Icons.file_upload),
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
              icon: const Icon(Icons.ios_share),
              onPressed: _exportSelected,
              tooltip: '导出选中项',
            ),
          ],
        ],
      ),
      body:
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
                            ? const Icon(Icons.folder, color: Colors.amber)
                            : const Icon(Icons.insert_drive_file),
                    title: Text(path.basename(file.path)),
                    subtitle:
                        isDirectory
                            ? null
                            : Text('${(file as File).lengthSync()} bytes'),
                    trailing: Checkbox(
                      value: selectedItems[file.path] ?? false,
                      onChanged:
                          (value) => _toggleSelection(file.path, isDirectory),
                    ),
                    onTap: () {
                      if (isDirectory) {
                        _navigateToDirectory(file as Directory);
                      }
                    },
                    onLongPress: () {
                      _showContextMenu(file.path, isDirectory);
                    },
                  );
                },
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
  final Stack<Directory> directoryStack = Stack<Directory>();

  @override
  void initState() {
    super.initState();
    currentDirectory = widget.initialDirectory;
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final items = currentDirectory.listSync();
    setState(() {
      folders = items.where((item) => item is Directory).toList();
      folders.sort((a, b) => a.path.compareTo(b.path));
      directoryStack.push(currentDirectory);
    });
  }

  void _navigateTo(Directory dir) {
    setState(() {
      currentDirectory = dir;
      _loadFolders();
    });
  }

  void _navigateUp() {
    if (directoryStack.length > 1) {
      setState(() {
        directoryStack.pop();
        currentDirectory = directoryStack.peek();
        _loadFolders();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          if (directoryStack.length > 1)
            IconButton(
              icon: const Icon(Icons.arrow_upward),
              onPressed: _navigateUp,
              tooltip: '上一级',
            ),
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
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: folders.length,
          itemBuilder: (context, index) {
            final folder = folders[index] as Directory;
            return ListTile(
              leading: const Icon(Icons.folder, color: Colors.amber),
              title: Text(path.basename(folder.path)),
              onTap: () => _navigateTo(folder),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
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
