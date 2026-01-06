import 'dart:io' show File;

import 'package:get/get.dart';
import 'package:Memento/plugins/database/controllers/database_controller.dart';
import 'package:Memento/plugins/database/widgets/database_detail_widget.dart';
import 'package:Memento/plugins/database/widgets/database_edit_widget.dart';
import 'package:Memento/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/widgets/smooth_bottom_sheet.dart';
import 'package:uuid/uuid.dart';
import '../../../../widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/plugins/database/models/database_model.dart';
import 'package:Memento/plugins/database/services/database_service.dart';

class DatabaseListWidget extends StatefulWidget {
  final DatabaseService service;

  const DatabaseListWidget({super.key, required this.service});

  @override
  State<DatabaseListWidget> createState() => _DatabaseListWidgetState();
}

class _DatabaseListWidgetState extends State<DatabaseListWidget> {
  late Future<List<DatabaseModel>> _databasesFuture;
  String _searchQuery = '';
  List<DatabaseModel> _allDatabases = [];

  @override
  void initState() {
    super.initState();
    _loadDatabases();
  }

  Future<void> _loadDatabases() async {
    _databasesFuture = widget.service.getAllDatabases();
    _allDatabases = await _databasesFuture;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SuperCupertinoNavigationWrapper(
      title: Text('database_database_list_title'.tr),
      largeTitle: 'database_database_list_title'.tr,
      enableLargeTitle: true,

      // 启用搜索栏
      enableSearchBar: true,
      searchPlaceholder: 'database_search_databases'.tr,
      onSearchChanged: (query) {
        setState(() {
          _searchQuery = query;
        });
      },

      // 添加新建按钮
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'database_add_database'.tr,
          onPressed: () => _showAddDatabaseDialog(context),
        ),
      ],

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
                    'database_load_failed_message'.tr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _loadDatabases();
                    },
                    child: Text('app_retry'.tr),
                  ),
                ],
              ),
            );
          }

          // 保存到本地变量并应用搜索过滤
          _allDatabases = snapshot.data ?? [];
          final databases = _searchQuery.isEmpty
              ? _allDatabases
              : _allDatabases.where((db) {
                  return db.name.toLowerCase().contains(_searchQuery.toLowerCase());
                }).toList();

          if (databases.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'database_no_databases_message'.tr,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'database_add_database_hint'.tr,
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
              await _loadDatabases();
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
                      NavigationHelper.push(
                        context,
                        DatabaseDetailWidget(
                          controller: DatabaseController(widget.service),
                          databaseId: database.id,
                        ),
                      ).then(
                        (_) => _loadDatabases(),
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
                                  ? FutureBuilder<String>(
                                    future: ImageUtils.getAbsolutePath(
                                      database.coverImage!,
                                    ),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }
                                      if (snapshot.hasError ||
                                          !snapshot.hasData) {
                                        return _buildIcon();
                                      }
                                      return _buildImageWidget(snapshot.data!);
                                    },
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
    await SmoothBottomSheet.show(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text('app_edit'.tr),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await NavigationHelper.push<bool>(
                    context,
                    DatabaseEditWidget(
                      controller: DatabaseController(widget.service),
                      database: database,
                    ),
                  );
                  if (result == true && mounted) {
                    _loadDatabases();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: Text('app_copy'.tr),
                onTap: () async {
                  Navigator.pop(context);
                  final newDatabase = database.copyWith(id: Uuid().v4());
                  await widget.service.createDatabase(newDatabase);
                  if (mounted) {
                    Toast.success('database_copy_success'.tr);
                    _loadDatabases();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  'database_delete_action'.tr,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text('database_confirm_delete_title'.tr),
                          content: Text(
                            'database_confirm_delete_message'.trParams({
                              'name': database.name,
                            }),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('app_cancel'.tr),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(
                                'database_delete'.tr,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                  );
                  if (confirm == true) {
                    try {
                      await widget.service.deleteDatabase(database.id);
                      if (mounted) {
                        Toast.success('database_delete_success_message'.tr);
                        _loadDatabases();
                      }
                    } catch (e) {
                      if (mounted) {
                        Toast.error(
                          'database_delete_failed_message'.trParams({
                            'error': e.toString(),
                          }),
                        );
                      }
                    }
                  }
                },
              ),
            ],
          ),
    );
  }

  Widget _buildImageWidget(String imageUrl) {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      // 网络图片
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('网络图片加载失败: $error');
          return _buildIcon();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value:
                  loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
            ),
          );
        },
      );
    } else {
      // 本地图片
      try {
        final file = File(imageUrl);
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('本地图片加载失败: $error\n路径: $imageUrl');
            return _buildIcon();
          },
        );
      } catch (e) {
        debugPrint('创建File对象失败: $e\n路径: $imageUrl');
        return _buildIcon();
      }
    }
  }

  Widget _buildIcon() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.broken_image, size: 48),
    );
  }

  /// 显示新建数据库对话框
  Future<void> _showAddDatabaseDialog(BuildContext context) async {
    // 创建一个空的新数据库模型
    final now = DateTime.now();
    final newDatabase = DatabaseModel(
      id: Uuid().v4(),
      name: '',
      fields: [],
      createdAt: now,
      updatedAt: now,
    );

    final result = await NavigationHelper.push<bool>(
      context,
      DatabaseEditWidget(
        controller: DatabaseController(widget.service),
        database: newDatabase,
      ),
    );

    if (result == true && mounted) {
      _loadDatabases();
    }
  }
}
