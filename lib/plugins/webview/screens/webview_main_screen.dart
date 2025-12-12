import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../webview_plugin.dart';
import '../models/webview_card.dart';
import '../services/card_manager.dart';
import 'components/webview_card_item.dart';
import 'webview_browser_screen.dart';
import 'proxy_settings_screen.dart';

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
    final plugin = WebViewPlugin.instance;

    return ChangeNotifierProvider.value(
      value: plugin.cardManager,
      child: Scaffold(
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
              itemBuilder: (context) => [
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
                  suffixIcon: _searchQuery.isNotEmpty
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
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
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
                              onLongPress: () => _showCardOptions(pinnedCards[index]),
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
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
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
                              onLongPress: () => _showCardOptions(unpinnedCards[index]),
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
        MaterialPageRoute(
          builder: (context) => const WebViewBrowserScreen(),
        ),
      );
    } else {
      // 不存在，创建新标签页并导航
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WebViewBrowserScreen(
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
      builder: (context) => SafeArea(
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
              leading: Icon(card.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
              title: Text(card.isPinned ? 'webview_unpin'.tr : 'webview_pin'.tr),
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
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
                                // 选择本地文件或目录
                                final result = await FilePicker.platform
                                    .pickFiles(
                                      type: FileType.custom,
                                      allowedExtensions: ['html', 'htm'],
                                      allowMultiple: false,
                                    );

                                if (result != null &&
                                    result.files.single.path != null) {
                                  final filePath = result.files.single.path!;
                                  final fileName = result.files.single.name;

                                  setState(() {
                                    isLocalFileMode = true;
                                    selectedType = CardType.localFile;
                                  });

                                  // 如果标题为空，使用文件名作为标题
                                  if (titleController.text.isEmpty) {
                                    titleController.text = fileName.replaceAll(
                                      RegExp(r'\.(html|htm)$'),
                                      '',
                                    );
                                  }

                                  // 如果项目名称为空，生成默认名称
                                  if (projectNameController.text.isEmpty) {
                                    final baseName = fileName.replaceAll(
                                      RegExp(r'\.(html|htm)$'),
                                      '',
                                    );
                                    // 转换为合法的项目名称
                                    final projectName = baseName
                                        .replaceAll(
                                          RegExp(r'[^a-zA-Z0-9_-]'),
                                          '_',
                                        )
                                        .replaceAll(RegExp(r'_+'), '_');
                                    projectNameController.text = projectName;
                                  }

                                  // 临时存储文件路径
                                  urlController.text = filePath;
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
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
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

                            // 添加卡片（使用 ./ 相对路径）
                            await WebViewPlugin.instance.cardManager.addCard(
                              title: titleController.text,
                              url: relativePath,
                              type: selectedType,
                              description:
                                  descController.text.isNotEmpty
                                      ? descController.text
                                      : null,
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
                    description: descController.text.isNotEmpty ? descController.text : null,
                  );

                  if (mounted) Navigator.pop(context);
                }
              },
              child: Text(MaterialLocalizations.of(context).saveButtonLabel),
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
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.any,
                          allowMultiple: false,
                        );

                        if (result != null && result.files.single.path != null) {
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
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty && urlController.text.isNotEmpty) {
                final updatedCard = card.copyWith(
                  title: titleController.text,
                  url: urlController.text,
                  description: descController.text.isNotEmpty ? descController.text : null,
                );
                await WebViewPlugin.instance.cardManager.updateCard(updatedCard);
                if (mounted) Navigator.pop(context);
              }
            },
            child: Text(MaterialLocalizations.of(context).saveButtonLabel),
          ),
        ],
        ),
      ),
    );
  }

  void _confirmDeleteCard(WebViewCard card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('webview_delete_card'.tr),
        content: Text('webview_confirm_delete'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
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
