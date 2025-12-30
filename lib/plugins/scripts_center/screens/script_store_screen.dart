import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/plugins/scripts_center/models/script_store_models.dart';
import 'package:Memento/plugins/scripts_center/services/script_store_manager.dart';
import 'package:Memento/plugins/scripts_center/services/script_download_manager.dart';
import 'package:Memento/widgets/smooth_bottom_sheet.dart';
import 'package:Memento/core/services/toast_service.dart';

/// 脚本商场主界面
class ScriptStoreScreen extends StatefulWidget {
  const ScriptStoreScreen({super.key});

  @override
  State<ScriptStoreScreen> createState() => _ScriptStoreScreenState();
}

class _ScriptStoreScreenState extends State<ScriptStoreScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _selectedTags = [];
  bool _showInstalledOnly = false;

  @override
  Widget build(BuildContext context) {
    final scriptStoreManager = context.watch<ScriptStoreManager>();
    final downloadManager = context.watch<ScriptDownloadManager>();

    final filteredScripts = scriptStoreManager.searchScripts(
      _searchController.text,
      tags: _selectedTags.isEmpty ? null : _selectedTags,
      installedOnly: _showInstalledOnly ? true : null,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('scripts_center_scriptStore'.tr),
        actions: [
          // 源切换按钮
          IconButton(
            icon: const Icon(Icons.source),
            tooltip:
                scriptStoreManager.currentSource?.name ??
                'scripts_center_select_source'.tr,
            onPressed: () => _showSourcePicker(context),
          ),
          // 源管理按钮
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'scripts_center_manage_sources'.tr,
            onPressed: () => _showSourceManagement(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'search'.tr,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // 标签过滤器
          _buildTagFilter(scriptStoreManager),

          // 已安装过滤器
          SwitchListTile(
            title: Text('scripts_center_installed_only'.tr),
            value: _showInstalledOnly,
            onChanged: (value) {
              setState(() {
                _showInstalledOnly = value;
              });
            },
          ),

          const Divider(height: 1),

          // 脚本列表
          Expanded(
            child:
                scriptStoreManager.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : scriptStoreManager.error != null
                    ? _buildErrorView(scriptStoreManager)
                    : filteredScripts.isEmpty
                    ? _buildEmptyView()
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredScripts.length,
                      itemBuilder: (context, index) {
                        return _buildScriptCard(filteredScripts[index]);
                      },
                    ),
          ),

          // 安装进度条
          if (downloadManager.isInstalling)
            _buildInstallProgress(downloadManager.currentTask!),
        ],
      ),
    );
  }

  /// 标签过滤器
  Widget _buildTagFilter(ScriptStoreManager manager) {
    final allTags = manager.getAllTags();
    if (allTags.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: allTags.length,
        itemBuilder: (context, index) {
          final tag = allTags[index];
          final isSelected = _selectedTags.contains(tag);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.remove(tag);
                  }
                });
              },
            ),
          );
        },
      ),
    );
  }

  /// 脚本卡片
  Widget _buildScriptCard(ScriptStoreItem script) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showScriptDetail(script),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部：图标和版本信息
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 左侧图标
                  _buildScriptIcon(script.icon),
                  const SizedBox(width: 12),
                  // 中间信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          script.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (script.author != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${'scripts_center_author'.tr}: ${script.author}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // 右侧版本信息
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (script.isInstalled) ...[
                            const Icon(
                              Icons.check_circle,
                              size: 14,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            script.displayVersion,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (script.hasUpdate) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'scripts_center_update'.tr,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 描述
              if (script.description != null && script.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    script.description!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ),
              // 标签
              if (script.tags.isNotEmpty)
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children:
                      script.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple[50],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.purple[200]!),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.purple[700],
                            ),
                          ),
                        );
                      }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 安装进度条
  Widget _buildInstallProgress(ScriptInstallTask task) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_getStatusText(task.status)} ${task.scriptName}...',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text('${(task.progress * 100).toStringAsFixed(0)}%'),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: task.progress),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${task.completedFiles}/${task.totalFiles} files • ${_formatBytes(task.downloadedBytes)}/${_formatBytes(task.totalBytes)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              if (task.status == ScriptInstallTaskStatus.downloading)
                TextButton(
                  onPressed: () {
                    context.read<ScriptDownloadManager>().cancelInstall();
                  },
                  child: Text('cancel'.tr),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 错误视图
  Widget _buildErrorView(ScriptStoreManager manager) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              manager.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => manager.fetchScripts(),
              icon: const Icon(Icons.refresh),
              label: Text('retry'.tr),
            ),
          ],
        ),
      ),
    );
  }

  /// 空视图
  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.code, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'scripts_center_no_scripts_found'.tr,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  /// 源选择对话框
  void _showSourcePicker(BuildContext context) {
    final manager = context.read<ScriptStoreManager>();
    if (manager.sources.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('scripts_center_no_sources'.tr)));
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('scripts_center_select_source'.tr),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  manager.sources.map((source) {
                    return RadioListTile<String>(
                      title: Text(source.name),
                      subtitle: Text(
                        source.url,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      value: source.id,
                      groupValue: manager.currentSource?.id,
                      onChanged: (value) {
                        if (value != null) {
                          manager.switchSource(value);
                          Navigator.pop(dialogContext);
                        }
                      },
                    );
                  }).toList(),
            ),
          ),
        );
      },
    );
  }

  /// 源管理对话框
  void _showSourceManagement(BuildContext context) {
    final manager = context.read<ScriptStoreManager>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('scripts_center_manage_sources'.tr),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: manager.sources.length,
              itemBuilder: (context, index) {
                final source = manager.sources[index];
                return ListTile(
                  title: Text(source.name),
                  subtitle: Text(
                    source.url,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      showDialog(
                        context: dialogContext,
                        builder: (confirmContext) {
                          return AlertDialog(
                            title: Text('scripts_center_delete_source'.tr),
                            content: Text('${'scripts_center_delete_source_confirm'.tr} ${source.name}?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(confirmContext),
                                child: Text('cancel'.tr),
                              ),
                              TextButton(
                                onPressed: () {
                                  manager.deleteSource(source.id);
                                  Navigator.pop(confirmContext);
                                  Navigator.pop(dialogContext);
                                },
                                child: Text('delete'.tr),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('close'.tr),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _showAddSourceDialog(context);
              },
              child: Text('scripts_center_add_source'.tr),
            ),
          ],
        );
      },
    );
  }

  /// 添加源对话框
  void _showAddSourceDialog(BuildContext context) {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    final baseUrlController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('scripts_center_add_source'.tr),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'scripts_center_source_name'.tr,
                ),
              ),
              TextField(
                controller: urlController,
                decoration: InputDecoration(
                  labelText: 'scripts_center_source_url'.tr,
                ),
              ),
              TextField(
                controller: baseUrlController,
                decoration: InputDecoration(
                  labelText: 'scripts_center_source_base_url'.tr,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('cancel'.tr),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    urlController.text.isEmpty ||
                    baseUrlController.text.isEmpty) {
                  Toast.error('scripts_center_fill_all_fields'.tr);
                  return;
                }

                final manager = context.read<ScriptStoreManager>();
                await manager.addSource(ScriptStoreSource(
                  id: const Uuid().v4(),
                  name: nameController.text,
                  url: urlController.text,
                  baseUrl: baseUrlController.text,
                  createdAt: DateTime.now(),
                ));

                Navigator.pop(dialogContext);
                Toast.success('scripts_center_source_added'.tr);
              },
              child: Text('add'.tr),
            ),
          ],
        );
      },
    );
  }

  /// 显示脚本详情
  void _showScriptDetail(ScriptStoreItem script) {
    final scriptStoreManager = context.read<ScriptStoreManager>();
    final downloadManager = context.read<ScriptDownloadManager>();

    SmoothBottomSheet.show(
      context: context,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            return Column(
              children: [
                // 头部
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      _buildScriptIcon(script.icon, size: 64),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              script.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'v${script.version}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (script.author != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${'scripts_center_author'.tr}: ${script.author}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // 内容
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (script.description != null && script.description!.isNotEmpty) ...[
                          Text(
                            'scripts_center_description'.tr,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(script.description!),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          'scripts_center_tags'.tr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              script.tags.map((tag) {
                                return Chip(
                                  label: Text(tag),
                                  backgroundColor: Colors.purple[50],
                                );
                              }).toList(),
                        ),
                        if (script.permissions.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'scripts_center_permissions'.tr,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...script.permissions.map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.warning, size: 16, color: Colors.orange),
                                const SizedBox(width: 8),
                                Expanded(child: Text(p)),
                              ],
                            ),
                          )),
                        ],
                      ],
                    ),
                  ),
                ),
                // 底部按钮
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (script.isInstalled) ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await scriptStoreManager.uninstallScript(script.id);
                              Toast.success('scripts_center_uninstalled'.tr);
                            },
                            icon: const Icon(Icons.delete),
                            label: Text('scripts_center_uninstall'.tr),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: downloadManager.isInstalling
                                ? null
                                : () async {
                              try {
                                await downloadManager.installScript(script);
                                Toast.success('scripts_center_installed'.tr);
                                Navigator.pop(sheetContext);
                              } catch (e) {
                                Toast.error('${'scripts_center_install_failed'.tr}: $e');
                              }
                            },
                            icon: const Icon(Icons.download),
                            label: Text('scripts_center_install'.tr),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 获取状态文本
  String _getStatusText(ScriptInstallTaskStatus status) {
    switch (status) {
      case ScriptInstallTaskStatus.downloading:
        return 'scripts_center_downloading'.tr;
      case ScriptInstallTaskStatus.installing:
        return 'scripts_center_installing'.tr;
      case ScriptInstallTaskStatus.completed:
        return 'Completed';
      case ScriptInstallTaskStatus.failed:
        return 'Failed';
    }
  }

  /// 格式化字节数
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// 构建脚本图标
  Widget _buildScriptIcon(String? icon, {double size = 48}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: icon != null && icon.isNotEmpty
            ? Center(
              child: Text(
                icon,
                style: TextStyle(fontSize: size * 0.6),
                textAlign: TextAlign.center,
              ),
            )
            : Icon(Icons.code, size: size / 2),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
