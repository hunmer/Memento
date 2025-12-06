import 'dart:io';

import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/plugins/database/l10n/database_localizations.dart';
import 'package:Memento/plugins/database/controllers/database_controller.dart';
import 'package:Memento/plugins/database/widgets/database_detail_widget.dart';
import 'package:Memento/plugins/database/widgets/database_edit_widget.dart';
import 'package:Memento/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:uuid/uuid.dart';
import '../../../../widgets/super_cupertino_navigation_wrapper.dart';
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
    final l10n = DatabaseLocalizations.of(context);
    final theme = Theme.of(context);

    return SuperCupertinoNavigationWrapper(
      title: Text(l10n.databaseListTitle),
      largeTitle: l10n.databaseListTitle,
      enableLargeTitle: true,
      automaticallyImplyLeading: !(Platform.isAndroid || Platform.isIOS),
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
                    l10n.loadFailedMessage,
                    style: theme.textTheme.titleMedium?.copyWith(color: Colors.red),
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
                      setState(() {
                        _databasesFuture = widget.service.getAllDatabases();
                      });
                    },
                    child: Text(AppLocalizations.of(context)!.retry),
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
                    DatabaseLocalizations.of(context).noDatabasesMessage,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DatabaseLocalizations.of(context).addDatabaseHint,
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
                      NavigationHelper.push(
                        context,
                        DatabaseDetailWidget(
                          controller: DatabaseController(widget.service),
                          databaseId: database.id,
                        ),
                      ).then(
                        (_) => setState(() {
                          _databasesFuture = widget.service.getAllDatabases();
                        }),
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
    await showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(AppLocalizations.of(context)!.edit),
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
                    setState(() {
                      _databasesFuture = widget.service.getAllDatabases();
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: Text(AppLocalizations.of(context)!.copy),
                onTap: () async {
                  Navigator.pop(context);
                  final newDatabase = database.copyWith(id: Uuid().v4());
                  await widget.service.createDatabase(newDatabase);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          DatabaseLocalizations.of(context).copySuccess,
                        ),
                      ),
                    );
                    setState(() {
                      _databasesFuture = widget.service.getAllDatabases();
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  DatabaseLocalizations.of(context).deleteAction,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text(
                            DatabaseLocalizations.of(
                              context,
                            ).confirmDeleteTitle,
                          ),
                          content: Text(
                            DatabaseLocalizations.of(context)
                                .confirmDeleteMessage
                                .replaceFirst('%s', database.name),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(AppLocalizations.of(context)!.cancel),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(
                                DatabaseLocalizations.of(context).delete,
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              DatabaseLocalizations.of(
                                context,
                              ).deleteSuccessMessage,
                            ),
                          ),
                        );
                        setState(() {
                          _databasesFuture = widget.service.getAllDatabases();
                        });
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              DatabaseLocalizations.of(context)
                                  .deleteFailedMessage
                                  .replaceFirst('%s', e.toString()),
                            ),
                          ),
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
}
