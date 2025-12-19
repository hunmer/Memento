import 'dart:io';

import 'package:Memento/plugins/webview/services/download_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

import '../webview_plugin.dart';
import '../models/webview_card.dart';
import '../services/card_manager.dart';
import '../services/app_store_manager.dart';
import 'components/webview_card_item.dart';
import 'webview_browser_screen.dart';
import 'proxy_settings_screen.dart';
import 'app_store/app_store_screen.dart';

/// WebView 主界面 - 网址卡片列表
class WebViewMainScreen extends StatefulWidget {
  const WebViewMainScreen({super.key});

  @override
  State<WebViewMainScreen> createState() => _WebViewMainScreenState();
}

class _WebViewMainScreenState extends State<WebViewMainScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  CardType? _filterType;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('webview_name'.tr),
        actions: [
          // 代理设置按钮
          IconButton(
            icon: const Icon(Icons.wifi_tethering),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProxySettingsScreen(),
                ),
              );
            },
            tooltip: 'webview_proxy_settings'.tr,
          ),
          // 筛选按钮
          PopupMenuButton<CardType?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (type) {
              setState(() {
                _filterType = type;
              });
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: null,
                    child: Text('webview_all_cards'.tr),
                  ),
                  PopupMenuItem(
                    value: CardType.url,
                    child: Text('webview_online_urls'.tr),
                  ),
                  PopupMenuItem(
                    value: CardType.localFile,
                    child: Text('webview_local_files'.tr),
                  ),
                ],
          ),

          // 源切换按钮
          Consumer<AppStoreManager>(
            builder: (context, appStoreManager, _) {
              return IconButton(
                icon: const Icon(Icons.source),
                tooltip:
                    appStoreManager.currentSource?.name ??
                    'webview_select_source'.tr,
                onPressed: () => _showSourcePicker(context),
              );
            },
          ),

          // 商场入口按钮
          IconButton(
            icon: const Icon(Icons.store),
            tooltip: 'webview_app_store'.tr,
            onPressed: () {
              // 先捕获 Provider 实例，避免闭包中 context 失效
              final appStoreManager = context.read<AppStoreManager>();
              final downloadManager = context.read<DownloadManager>();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MultiProvider(
                    providers: [
                      ChangeNotifierProvider.value(value: appStoreManager),
                      ChangeNotifierProvider.value(value: downloadManager),
                    ],
                    child: const AppStoreScreen(),
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
                hintText: 'webview_search_placeholder'.tr,
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              onSubmitted: (value) {
                // 如果输入的是有效 URL，直接打开
                if (_isValidUrl(value)) {
                  _openUrl(value);
                }
              },
            ),
          ),

          // 卡片列表
          Expanded(
            child: Consumer<CardManager>(
              builder: (context, cardManager, child) {
                var cards = cardManager.cards;

                // 应用搜索过滤
                if (_searchQuery.isNotEmpty) {
                  cards = cardManager.searchCards(_searchQuery);
                }

                // 应用类型过滤
                if (_filterType != null) {
                  cards = cards.where((c) => c.type == _filterType).toList();
                }

                if (cards.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.web_asset_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'webview_no_cards'.tr,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // 分组显示：固定的卡片在前
                final pinnedCards = cards.where((c) => c.isPinned).toList();
                final unpinnedCards = cards.where((c) => !c.isPinned).toList();

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // 固定的卡片
                    if (pinnedCards.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'webview_pinned'.tr,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _getCrossAxisCount(context),
                          childAspectRatio: 1.2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: pinnedCards.length,
                        itemBuilder: (context, index) {
                          return WebViewCardItem(
                            card: pinnedCards[index],
                            onTap: () => _openCard(pinnedCards[index]),
                            onLongPress:
                                () => _showCardOptions(pinnedCards[index]),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 普通卡片
                    if (unpinnedCards.isNotEmpty) ...[
                      if (pinnedCards.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'webview_all_cards'.tr,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _getCrossAxisCount(context),
                          childAspectRatio: 1.2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: unpinnedCards.length,
                        itemBuilder: (context, index) {
                          return WebViewCardItem(
                            card: unpinnedCards[index],
                            onTap: () => _openCard(unpinnedCards[index]),
                            onLongPress:
                                () => _showCardOptions(unpinnedCards[index]),
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 80), // FAB 留空
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCardDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 5;
    if (width > 900) return 4;
    if (width > 600) return 3;
    return 2;
  }

  bool _isValidUrl(String text) {
    try {
      final uri = Uri.parse(text);
      return uri.scheme == 'http' || uri.scheme == 'https';
    } catch (_) {
      return false;
    }
  }

  /// 将文件路径转换为正确的 URL 格式
  /// 优先使用 HTTP URL（Windows），否则使用 file:// URL
  String _formatFileUrl(String filePath) {
    // 使用插件的 filePathToUrl 方法
    return WebViewPlugin.instance.filePathToUrl(filePath);
  }

  void _openUrl(String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WebViewBrowserScreen(initialUrl: url),
      ),
    );
  }

  void _openCard(WebViewCard card) async {
    // 增加打开次数
    WebViewPlugin.instance.cardManager.incrementOpenCount(card.id);

    final tabManager = WebViewPlugin.instance.tabManager;

    // 检查是否已经有该卡片的标签页
    final existingTab = tabManager.findTabByCardId(card.id);

    if (existingTab != null) {
      // 已存在，切换到该标签页
      await tabManager.switchToTab(existingTab.id);

      // 导航到浏览器界面
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const WebViewBrowserScreen()),
      );
    } else {
      // 不存在，创建新标签页并导航
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => WebViewBrowserScreen(
                initialUrl: card.url,
                initialTitle: card.title,
                cardId: card.id,
              ),
        ),
      );
    }
  }

  void _showCardOptions(WebViewCard card) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.open_in_new),
                  title: Text('webview_new_tab'.tr),
                  onTap: () {
                    Navigator.pop(context);
                    _openCard(card);
                  },
                ),
                ListTile(
                  leading: Icon(
                    card.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  ),
                  title: Text(
                    card.isPinned ? 'webview_unpin'.tr : 'webview_pin'.tr,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    WebViewPlugin.instance.cardManager.togglePinned(card.id);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: Text('webview_copy_url'.tr),
                  onTap: () {
                    Navigator.pop(context);
                    Clipboard.setData(ClipboardData(text: card.url));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('webview_url_copied'.tr)),
                    );
                  },
                ),
                // 同步复制（仅本地文件且有原始路径）
                if (card.type == CardType.localFile && card.sourcePath != null)
                  ListTile(
                    leading: const Icon(Icons.sync),
                    title: const Text('同步复制'),
                    subtitle: const Text('从原始路径重新复制文件'),
                    onTap: () {
                      Navigator.pop(context);
                      _syncCopyCard(card);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: Text('webview_edit_card'.tr),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditCardDialog(card);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text(
                    'webview_delete_card'.tr,
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteCard(card);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showAddCardDialog() {
    final titleController = TextEditingController();
    final urlController = TextEditingController();
    final descController = TextEditingController();
    final projectNameController = TextEditingController();
    CardType selectedType = CardType.url;
    bool isLocalFileMode = false;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text('webview_add_card'.tr),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            labelText: 'webview_card_title'.tr,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 项目名称输入（本地文件模式）
                        if (isLocalFileMode) ...[
                          TextField(
                            controller: projectNameController,
                            decoration: InputDecoration(
                              labelText: '项目名称（英文/数字/下划线）',
                              border: const OutlineInputBorder(),
                              helperText: '文件将复制到 http_server/项目名称/ 目录',
                              helperMaxLines: 2,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        TextField(
                          controller: urlController,
                          readOnly: isLocalFileMode,
                          decoration: InputDecoration(
                            labelText: 'webview_card_url'.tr,
                            border: const OutlineInputBorder(),
                            helperText:
                                isLocalFileMode
                                    ? 'URL 将自动生成为 ./项目名称/...'
                                    : null,
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.folder_open),
                              tooltip: 'webview_select_local_file'.tr,
                              onPressed: () async {
                                // Android 11+ 需要使用 pickFiles 来获取文件访问权限
                                // 让用户选择目录中的所有文件
                                final result = await FilePicker.platform
                                    .pickFiles(
                                      dialogTitle: '选择项目中的所有文件（包括 index.html）',
                                      allowMultiple: true,
                                      type: FileType.any,
                                      withData: false,
                                      withReadStream: false,
                                    );

                                if (result == null || result.files.isEmpty) {
                                  return;
                                }

                                // 找到包含 index.html 的目录
                                String? indexHtmlPath;
                                for (final file in result.files) {
                                  if (file.path != null &&
                                      file.name == 'index.html') {
                                    indexHtmlPath = file.path;
                                    break;
                                  }
                                }

                                if (indexHtmlPath == null) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('错误：所选文件中未找到 index.html'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                  return;
                                }

                                // 获取目录路径和名称
                                final directoryPath = path.dirname(
                                  indexHtmlPath,
                                );
                                final directoryName = path.basename(
                                  directoryPath,
                                );

                                // 将选中的文件列表保存到 WebViewPlugin 中以备后用
                                WebViewPlugin.instance.pendingFilesToCopy =
                                    result.files
                                        .where((f) => f.path != null)
                                        .map((f) => f.path!)
                                        .toList();

                                setState(() {
                                  isLocalFileMode = true;
                                  selectedType = CardType.localFile;
                                });

                                // 如果标题为空，使用目录名作为标题
                                if (titleController.text.isEmpty) {
                                  titleController.text = directoryName;
                                }

                                // 如果项目名称为空，生成默认名称
                                if (projectNameController.text.isEmpty) {
                                  final projectName = directoryName
                                      .replaceAll(
                                        RegExp(r'[^a-zA-Z0-9_-]'),
                                        '_',
                                      )
                                      .replaceAll(RegExp(r'_+'), '_');
                                  projectNameController.text = projectName;
                                }

                                // 存储目录路径
                                urlController.text = directoryPath;
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: descController,
                          decoration: InputDecoration(
                            labelText: 'webview_card_description'.tr,
                            border: const OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        SegmentedButton<CardType>(
                          segments: [
                            ButtonSegment(
                              value: CardType.url,
                              label: Text('webview_card_type_url'.tr),
                              icon: const Icon(Icons.language),
                            ),
                            ButtonSegment(
                              value: CardType.localFile,
                              label: Text('webview_card_type_local'.tr),
                              icon: const Icon(Icons.folder),
                            ),
                          ],
                          selected: {selectedType},
                          onSelectionChanged: (value) {
                            setState(() {
                              selectedType = value.first;
                              isLocalFileMode =
                                  selectedType == CardType.localFile;
                              if (!isLocalFileMode) {
                                projectNameController.clear();
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        MaterialLocalizations.of(context).cancelButtonLabel,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (titleController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('请输入卡片标题')),
                          );
                          return;
                        }

                        if (isLocalFileMode) {
                          // 本地文件模式：复制文件并生成 ./ 路径
                          if (projectNameController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('请输入项目名称')),
                            );
                            return;
                          }

                          try {
                            final sourcePath = urlController.text;
                            final projectName = projectNameController.text;

                            // 复制文件到 HTTP 服务器目录
                            final relativePath = await WebViewPlugin.instance
                                .copyToHttpServer(
                                  sourcePath: sourcePath,
                                  projectName: projectName,
                                );

                            // 添加卡片（使用 ./ 相对路径，同时保存原始路径）
                            await WebViewPlugin.instance.cardManager.addCard(
                              title: titleController.text,
                              url: relativePath,
                              type: selectedType,
                              description:
                                  descController.text.isNotEmpty
                                      ? descController.text
                                      : null,
                              sourcePath: sourcePath, // 保存原始路径用于同步
                            );

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('本地项目已添加')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('添加失败: $e')),
                              );
                            }
                          }
                        } else {
                          // 在线 URL 模式
                          if (urlController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('请输入 URL')),
                            );
                            return;
                          }

                          await WebViewPlugin.instance.cardManager.addCard(
                            title: titleController.text,
                            url: urlController.text,
                            type: selectedType,
                            description:
                                descController.text.isNotEmpty
                                    ? descController.text
                                    : null,
                          );

                          if (mounted) Navigator.pop(context);
                        }
                      },
                      child: Text(
                        MaterialLocalizations.of(context).saveButtonLabel,
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showEditCardDialog(WebViewCard card) {
    final titleController = TextEditingController(text: card.title);
    final urlController = TextEditingController(text: card.url);
    final descController = TextEditingController(text: card.description ?? '');

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text('webview_edit_card'.tr),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            labelText: 'webview_card_title'.tr,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: urlController,
                          decoration: InputDecoration(
                            labelText: 'webview_card_url'.tr,
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.folder_open),
                              tooltip: 'webview_select_local_file'.tr,
                              onPressed: () async {
                                // 选择本地文件
                                final result = await FilePicker.platform
                                    .pickFiles(
                                      type: FileType.any,
                                      allowMultiple: false,
                                    );

                                if (result != null &&
                                    result.files.single.path != null) {
                                  final filePath = result.files.single.path!;
                                  // 将文件路径转换为正确的 file:// URL
                                  final fileUrl = _formatFileUrl(filePath);
                                  urlController.text = fileUrl;

                                  // 如果标题为空，使用文件名作为标题
                                  if (titleController.text.isEmpty) {
                                    final fileName = result.files.single.name;
                                    titleController.text = fileName;
                                  }
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: descController,
                          decoration: InputDecoration(
                            labelText: 'webview_card_description'.tr,
                            border: const OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        MaterialLocalizations.of(context).cancelButtonLabel,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (titleController.text.isNotEmpty &&
                            urlController.text.isNotEmpty) {
                          final updatedCard = card.copyWith(
                            title: titleController.text,
                            url: urlController.text,
                            description:
                                descController.text.isNotEmpty
                                    ? descController.text
                                    : null,
                          );
                          await WebViewPlugin.instance.cardManager.updateCard(
                            updatedCard,
                          );
                          if (mounted) Navigator.pop(context);
                        }
                      },
                      child: Text(
                        MaterialLocalizations.of(context).saveButtonLabel,
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  /// 同步复制卡片（从原始路径重新复制）
  Future<void> _syncCopyCard(WebViewCard card) async {
    if (card.sourcePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('错误：未保存原始路径'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 检查原始路径是否存在
    final sourceDir = Directory(card.sourcePath!);
    if (!await sourceDir.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('错误：原始路径不存在\n${card.sourcePath}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // 检查是否存在 index.html
    final indexHtmlPath = path.join(card.sourcePath!, 'index.html');
    final indexHtmlFile = File(indexHtmlPath);
    if (!await indexHtmlFile.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('错误：原始目录中未找到 index.html'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 显示加载提示
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('正在同步复制...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      // 从卡片 URL 中提取项目名称
      // 例如：./projectName/index.html -> projectName
      final uri = Uri.parse(card.url);
      final pathSegments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

      if (pathSegments.isEmpty) {
        throw Exception('无法从 URL 中提取项目名称');
      }

      final projectName = pathSegments.first;

      // 重新复制文件到 HTTP 服务器目录
      await WebViewPlugin.instance.copyToHttpServer(
        sourcePath: card.sourcePath!,
        projectName: projectName,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('同步成功！文件已更新'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('同步失败: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

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
      builder: (context) {
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
                          Navigator.pop(context);
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

  void _confirmDeleteCard(WebViewCard card) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('webview_delete_card'.tr),
            content: Text('webview_confirm_delete'.tr),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  MaterialLocalizations.of(context).cancelButtonLabel,
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  await WebViewPlugin.instance.cardManager.deleteCard(card.id);
                  if (mounted) Navigator.pop(context);
                },
                child: Text(
                  MaterialLocalizations.of(context).deleteButtonTooltip,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }
}
