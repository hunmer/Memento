import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../models/app_store_models.dart';
import '../../services/app_store_manager.dart';
import '../../services/download_manager.dart';

/// 应用详情底部抽屉
class AppDetailSheet extends StatefulWidget {
  final MiniApp app;

  const AppDetailSheet({super.key, required this.app});

  @override
  State<AppDetailSheet> createState() => _AppDetailSheetState();
}

class _AppDetailSheetState extends State<AppDetailSheet> {
  List<AppFile>? _files;
  bool _isLoadingFiles = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFileList();
  }

  Future<void> _loadFileList() async {
    setState(() {
      _isLoadingFiles = true;
      _error = null;
    });

    try {
      // 获取对应源的 baseUrl
      final appStoreManager = context.read<AppStoreManager>();
      final source = appStoreManager.sources.firstWhere(
        (s) => s.id == widget.app.sourceId,
        orElse: () => throw Exception('Source not found'),
      );

      // 拼接完整的 URL: {baseUrl}/{filesUrl}
      final fullUrl =
          '${source.baseUrl.replaceAll(RegExp(r'\/+$'), '')}/${widget.app.filesUrl}';

      final response = await http
          .get(Uri.parse(fullUrl))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(
          utf8.decode(response.bodyBytes),
        );
        setState(() {
          _files =
              jsonList
                  .map((json) => AppFile.fromJson(json as Map<String, dynamic>))
                  .toList();
          _isLoadingFiles = false;
        });
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingFiles = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final downloadManager = context.watch<DownloadManager>();

    final totalSize = _files?.fold<int>(0, (sum, file) => sum + file.size) ?? 0;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // 顶部指示器
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 应用图标和标题
                    Row(
                      children: [
                        _buildAppIcon(widget.app.icon, size: 64),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.app.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Version ${widget.app.version}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              if (widget.app.author != null) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.app.author!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 描述
                    if (widget.app.desc != null) ...[
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(widget.app.desc!),
                      const SizedBox(height: 24),
                    ],

                    // 主页按钮
                    if (widget.app.homepage != null) ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _openHomepage(widget.app.homepage!),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Visit Homepage'),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // 标签
                    if (widget.app.tags.isNotEmpty) ...[
                      const Text(
                        'Tags',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            widget.app.tags.map((tag) {
                              return Chip(label: Text(tag));
                            }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // 权限
                    if (widget.app.permissions.isNotEmpty) ...[
                      const Text(
                        'Permissions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...widget.app.permissions.map((permission) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.check, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(permission)),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                    ],

                    // 文件列表
                    const Text(
                      'Files',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isLoadingFiles)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_error != null)
                      Text(
                        'Error loading files: $_error',
                        style: const TextStyle(color: Colors.red),
                      )
                    else if (_files != null) ...[
                      Text(
                        '${_files!.length} files • ${_formatBytes(totalSize)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _files!.length,
                          itemBuilder: (context, index) {
                            final file = _files![index];
                            return ListTile(
                              dense: true,
                              title: Text(
                                file.path,
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Text(
                                _formatBytes(file.size),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // 底部按钮
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
                ),
                child:
                    widget.app.isInstalled
                        ? Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _confirmUninstall(context),
                                child: Text('webview_uninstall'.tr),
                              ),
                            ),
                            if (widget.app.hasUpdate) ...[
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed:
                                      downloadManager.isInstalling
                                          ? null
                                          : () => _installApp(context),
                                  child: Text('webview_update'.tr),
                                ),
                              ),
                            ],
                          ],
                        )
                        : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                downloadManager.isInstalling || _files == null
                                    ? null
                                    : () => _installApp(context),
                            child: Text('webview_install'.tr),
                          ),
                        ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _installApp(BuildContext context) async {
    final downloadManager = context.read<DownloadManager>();

    // 确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final totalSize = _files!.fold<int>(0, (sum, file) => sum + file.size);
        return AlertDialog(
          title: Text('webview_confirm_install'.tr),
          content: Text(
            'This will download ${_files!.length} files (${_formatBytes(totalSize)}).\n\nContinue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('cancel'.tr),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text('confirm'.tr),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      Navigator.pop(context); // 关闭详情页

      try {
        await downloadManager.installApp(widget.app);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.app.title} installed successfully'),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Installation failed: $e')));
        }
      }
    }
  }

  void _confirmUninstall(BuildContext context) async {
    final appStoreManager = context.read<AppStoreManager>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('webview_confirm_uninstall'.tr),
          content: Text(
            'Are you sure you want to uninstall ${widget.app.title}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('cancel'.tr),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('webview_uninstall'.tr),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      Navigator.pop(context); // 关闭详情页

      try {
        await appStoreManager.uninstallApp(widget.app.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${widget.app.title} uninstalled')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Uninstall failed: $e')));
        }
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _openHomepage(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Cannot open URL: $url')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening URL: $e')));
      }
    }
  }

  /// 构建应用图标（支持网络图片、emoji文本、默认图标）
  Widget _buildAppIcon(String? icon, {double size = 64}) {
    // 判断是否为网络图片 URL
    final bool isNetworkImage = icon != null &&
        (icon.startsWith('http://') || icon.startsWith('https://'));

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isNetworkImage ? null : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: isNetworkImage
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
}
