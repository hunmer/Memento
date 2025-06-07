import 'package:Memento/plugins/database/controllers/database_controller.dart';
import 'package:Memento/plugins/database/widgets/database_detail_widget.dart';
import 'package:Memento/plugins/database/widgets/database_edit_widget.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/database_model.dart';
import '../services/database_service.dart';

class DatabaseListWidget extends StatefulWidget {
  final DatabaseService service;

  const DatabaseListWidget({super.key, required this.service});

  @override
  State<DatabaseListWidget> createState() => _DatabaseListWidgetState();
}

class _DatabaseListWidgetState extends State<DatabaseListWidget> {
  late Future<List<DatabaseModel>> _databasesFuture;

  @override
  void initState() {
    super.initState();
    _databasesFuture = widget.service.getAllDatabases();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('数据库列表'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final date = DateTime.now();
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder:
                  (context) => DatabaseEditWidget(
                    controller: DatabaseController(widget.service),
                    database: DatabaseModel(
                      id: '',
                      name: 'New Database',
                      description: '',
                      fields: [],
                      createdAt: date,
                      updatedAt: date,
                    ),
                  ),
            ),
          );
          if (result == true && mounted) {
            setState(() {
              _databasesFuture = widget.service.getAllDatabases();
            });
          }
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<DatabaseModel>>(
        future: _databasesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    '加载失败',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _databasesFuture = widget.service.getAllDatabases();
                      });
                    },
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          final databases = snapshot.data ?? [];

          if (databases.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    '暂无数据库',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点击右下角按钮添加',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _databasesFuture = widget.service.getAllDatabases();
              });
              if (mounted) {
                await _databasesFuture;
              }
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: databases.length,
              itemBuilder: (context, index) {
                final database = databases[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (context) => DatabaseDetailWidget(
                                controller: DatabaseController(widget.service),
                                databaseId: database.id,
                              ),
                        ),
                      );
                    },
                    onLongPress: () {
                      _showBottomSheet(context, database);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child:
                              database.coverImage != null
                                  ? Image.network(
                                    database.coverImage!,
                                    fit: BoxFit.cover,
                                  )
                                  : Container(
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.cloud, size: 48),
                                  ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            database.name,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _showBottomSheet(
    BuildContext context,
    DatabaseModel database,
  ) async {
    await showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('编辑'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder:
                          (context) => DatabaseEditWidget(
                            controller: DatabaseController(widget.service),
                            database: database,
                          ),
                    ),
                  );
                  if (result == true && mounted) {
                    setState(() {
                      _databasesFuture = widget.service.getAllDatabases();
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('复制'),
                onTap: () async {
                  Navigator.pop(context);
                  final newDatabase = database.copyWith(id: Uuid().v4());
                  await widget.service.createDatabase(newDatabase);
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('复制成功')));
                    setState(() {
                      _databasesFuture = widget.service.getAllDatabases();
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('删除', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('确认删除'),
                          content: Text('确定要删除数据库 "${database.name}" 吗？'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('取消'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                '删除',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                  );
                  if (confirm == true) {
                    try {
                      await widget.service.deleteDatabase(database.id);
                      if (mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(content: Text('删除成功')));
                        setState(() {
                          _databasesFuture = widget.service.getAllDatabases();
                        });
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('删除失败: $e')));
                      }
                    }
                  }
                },
              ),
            ],
          ),
    );
  }
}
