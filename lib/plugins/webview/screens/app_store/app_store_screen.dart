import 'package:Memento/plugins/webview/screens/app_store/source_management_screen.dart';
import 'package:Memento/plugins/webview/screens/app_store/app_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../models/app_store_models.dart';
import '../../services/app_store_manager.dart';
import '../../services/download_manager.dart';
import 'package:Memento/widgets/smooth_bottom_sheet.dart';

/// 小应用商场主界面
class AppStoreScreen extends StatefulWidget {
  const AppStoreScreen({super.key});

  @override
  State<AppStoreScreen> createState() => _AppStoreScreenState();
}

class _AppStoreScreenState extends State<AppStoreScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _selectedTags = [];
  bool _showInstalledOnly = false;

  @override
  Widget build(BuildContext context) {
    final appStoreManager = context.watch<AppStoreManager>();
    final downloadManager = context.watch<DownloadManager>();

    final filteredApps = appStoreManager.searchApps(
      _searchController.text,
      tags: _selectedTags.isEmpty ? null : _selectedTags,
      installedOnly: _showInstalledOnly ? true : null,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('webview_app_store'.tr),
        actions: [
          // 源切换按钮
          IconButton(
            icon: const Icon(Icons.source),
            tooltip:
                appStoreManager.currentSource?.name ??
                'webview_select_source'.tr,
            onPressed: () => _showSourcePicker(context),
          ),
          // 源管理按钮
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'webview_manage_sources'.tr,
            onPressed: () {
              final appStoreManager = context.read<AppStoreManager>();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => ChangeNotifierProvider.value(
                        value: appStoreManager,
                        child: const SourceManagementScreen(),
                      ),
                ),
              );
            },
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
          _buildTagFilter(appStoreManager),

          // 已安装过滤器
          SwitchListTile(
            title: Text('webview_installed_only'.tr),
            value: _showInstalledOnly,
            onChanged: (value) {
              setState(() {
                _showInstalledOnly = value;
              });
            },
          ),

          const Divider(height: 1),

          // 应用列表
          Expanded(
            child:
                appStoreManager.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : appStoreManager.error != null
                    ? _buildErrorView(appStoreManager)
                    : filteredApps.isEmpty
                    ? _buildEmptyView()
                    : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.1,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: filteredApps.length,
                      itemBuilder: (context, index) {
                        return _buildAppCard(filteredApps[index]);
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
  Widget _buildTagFilter(AppStoreManager manager) {
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

  /// 应用卡片
  Widget _buildAppCard(MiniApp app) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: () => _showAppDetail(app),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部：图标和版本信息
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 左侧图标（小尺寸）
                  _buildAppIcon(app.icon, size: 48),
                  const Spacer(),
                  // 右侧版本信息
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (app.isInstalled) ...[
                            const Icon(
                              Icons.check_circle,
                              size: 14,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            app.displayVersion,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (app.hasUpdate) ...[
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
                            'webview_update'.tr,
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
              const SizedBox(height: 10),
              // 标题
              Text(
                app.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // 描述
              Text(
                app.desc ?? '',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // 标签（最多展示2个）
              if (app.tags.isNotEmpty)
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children:
                      app.tags.take(2).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue[700],
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
  Widget _buildInstallProgress(InstallTask task) {
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
                  '${_getStatusText(task.status)} ${task.appName}...',
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
              if (task.status == InstallTaskStatus.downloading)
                TextButton(
                  onPressed: () {
                    context.read<DownloadManager>().cancelInstall();
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
  Widget _buildErrorView(AppStoreManager manager) {
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
              onPressed: () => manager.fetchApps(),
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
            Icon(Icons.apps, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No apps found',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  /// 源选择对话框
  void _showSourcePicker(BuildContext context) {
    final manager = context.read<AppStoreManager>();
    if (manager.sources.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('webview_no_sources'.tr)));
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('webview_select_source'.tr),
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

  /// 显示应用详情
  void _showAppDetail(MiniApp app) {
    final appStoreManager = context.read<AppStoreManager>();
    final downloadManager = context.read<DownloadManager>();

    SmoothBottomSheet.show(
      context: context,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: appStoreManager),
            ChangeNotifierProvider.value(value: downloadManager),
          ],
          child: AppDetailSheet(app: app),
        ),
      ),
    );
  }

  /// 获取状态文本
  String _getStatusText(InstallTaskStatus status) {
    switch (status) {
      case InstallTaskStatus.downloading:
        return 'webview_downloading_files'.tr;
      case InstallTaskStatus.installing:
        return 'webview_installing'.tr;
      case InstallTaskStatus.completed:
        return 'Completed';
      case InstallTaskStatus.failed:
        return 'Failed';
    }
  }

  /// 格式化字节数
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// 构建应用图标（支持网络图片、emoji文本、默认图标）
  Widget _buildAppIcon(String? icon, {double size = 48}) {
    // 判断是否为网络图片 URL
    final bool isNetworkImage =
        icon != null &&
        (icon.startsWith('http://') || icon.startsWith('https://'));

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isNetworkImage ? null : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child:
            isNetworkImage
                ? Image.network(
                  icon,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: size,
                      height: size,
                      color: Colors.grey[300],
                      child: Icon(Icons.apps, size: size / 2),
                    );
                  },
                )
                : icon != null && icon.isNotEmpty
                ? Center(
                  child: Text(
                    icon,
                    style: TextStyle(fontSize: size * 0.6),
                    textAlign: TextAlign.center,
                  ),
                )
                : Icon(Icons.apps, size: size / 2),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
