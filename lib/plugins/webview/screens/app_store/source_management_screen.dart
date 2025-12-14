import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../models/app_store_models.dart';
import '../../services/app_store_manager.dart';

/// 源管理界面
class SourceManagementScreen extends StatelessWidget {
  const SourceManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appStoreManager = context.watch<AppStoreManager>();

    return Scaffold(
      appBar: AppBar(
        title: Text('webview_manage_sources'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'webview_add_source'.tr,
            onPressed: () => _showAddSourceDialog(context),
          ),
        ],
      ),
      body: appStoreManager.sources.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.source, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'webview_no_sources'.tr,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: appStoreManager.sources.length,
              itemBuilder: (context, index) {
                final source = appStoreManager.sources[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(
                      source.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          source.url,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Base URL: ${source.baseUrl}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (source.lastFetchedAt != null)
                          Text(
                            'Last fetched: ${_formatDate(source.lastFetchedAt!)} • ${source.appCount ?? 0} apps',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (source.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Default',
                              style: TextStyle(fontSize: 11, color: Colors.white),
                            ),
                          ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                _showEditSourceDialog(context, source);
                                break;
                              case 'delete':
                                _confirmDelete(context, source);
                                break;
                              case 'set_default':
                                _setAsDefault(context, source);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  const Icon(Icons.edit, size: 20),
                                  const SizedBox(width: 8),
                                  Text('webview_edit_source'.tr),
                                ],
                              ),
                            ),
                            if (!source.isDefault)
                              PopupMenuItem(
                                value: 'set_default',
                                child: Row(
                                  children: [
                                    const Icon(Icons.star, size: 20),
                                    const SizedBox(width: 8),
                                    const Text('Set as Default'),
                                  ],
                                ),
                              ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete, size: 20, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Text('delete'.tr, style: const TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showAddSourceDialog(BuildContext context) {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    final baseUrlController = TextEditingController();
    final appStoreManager = context.read<AppStoreManager>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('webview_add_source'.tr),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'webview_source_name'.tr,
                    hintText: 'My App Store',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: urlController,
                  decoration: InputDecoration(
                    labelText: 'webview_source_url'.tr,
                    hintText: 'https://example.com/apps.json',
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: baseUrlController,
                  decoration: InputDecoration(
                    labelText: 'webview_source_base_url'.tr,
                    hintText: 'https://example.com',
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 8),
                Text(
                  'Base URL is used to download app files',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('cancel'.tr),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    urlController.text.isNotEmpty &&
                    baseUrlController.text.isNotEmpty) {
                  final source = AppStoreSource(
                    id: const Uuid().v4(),
                    name: nameController.text,
                    url: urlController.text,
                    baseUrl: baseUrlController.text,
                    createdAt: DateTime.now(),
                  );
                  appStoreManager.addSource(source);
                  Navigator.pop(dialogContext);
                }
              },
              child: Text('add'.tr),
            ),
          ],
        );
      },
    );
  }

  void _showEditSourceDialog(BuildContext context, AppStoreSource source) {
    final nameController = TextEditingController(text: source.name);
    final urlController = TextEditingController(text: source.url);
    final baseUrlController = TextEditingController(text: source.baseUrl);
    final appStoreManager = context.read<AppStoreManager>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('webview_edit_source'.tr),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'webview_source_name'.tr,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: urlController,
                  decoration: InputDecoration(
                    labelText: 'webview_source_url'.tr,
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: baseUrlController,
                  decoration: InputDecoration(
                    labelText: 'webview_source_base_url'.tr,
                  ),
                  keyboardType: TextInputType.url,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('cancel'.tr),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    urlController.text.isNotEmpty &&
                    baseUrlController.text.isNotEmpty) {
                  final updated = source.copyWith(
                    name: nameController.text,
                    url: urlController.text,
                    baseUrl: baseUrlController.text,
                  );
                  appStoreManager.updateSource(updated);
                  Navigator.pop(dialogContext);
                }
              },
              child: Text('save'.tr),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, AppStoreSource source) async {
    final appStoreManager = context.read<AppStoreManager>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('confirm'.tr),
          content: Text('Delete source "${source.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('cancel'.tr),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('delete'.tr),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      appStoreManager.deleteSource(source.id);
    }
  }

  void _setAsDefault(BuildContext context, AppStoreSource source) {
    final manager = context.read<AppStoreManager>();

    // 将所有源的 isDefault 设为 false
    for (var s in manager.sources) {
      if (s.id != source.id && s.isDefault) {
        manager.updateSource(s.copyWith(isDefault: false));
      }
    }

    // 将当前源设为默认
    manager.updateSource(source.copyWith(isDefault: true));
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
