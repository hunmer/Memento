import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../webview_plugin.dart';
import '../models/webview_tab.dart';
import '../services/tab_manager.dart';

/// 标签页管理界面
class TabManagerScreen extends StatelessWidget {
  const TabManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final plugin = WebViewPlugin.instance;

    return ChangeNotifierProvider.value(
      value: plugin.tabManager,
      child: Scaffold(
        appBar: AppBar(
          title: Text('webview_tab_manager'.tr),
          actions: [
            // 关闭所有标签页
            Consumer<TabManager>(
              builder: (context, tabManager, _) {
                if (tabManager.tabs.isEmpty) return const SizedBox();
                return IconButton(
                  icon: const Icon(Icons.close_fullscreen),
                  onPressed: () => _confirmCloseAll(context),
                  tooltip: 'webview_close_all_tabs'.tr,
                );
              },
            ),
          ],
        ),
        body: Consumer<TabManager>(
          builder: (context, tabManager, child) {
            if (tabManager.tabs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.tab_unselected,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'webview_no_tabs'.tr,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _getCrossAxisCount(context),
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: tabManager.tabs.length + 1, // +1 for new tab button
              itemBuilder: (context, index) {
                if (index == tabManager.tabs.length) {
                  // 新建标签页按钮
                  return _buildNewTabButton(context);
                }

                final tab = tabManager.tabs[index];
                return _TabPreviewCard(
                  tab: tab,
                  isActive: tab.id == tabManager.activeTabId,
                  onTap: () {
                    tabManager.switchToTab(tab.id);
                    Navigator.pop(context);
                  },
                  onClose: () => _closeTab(context, tab.id),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _createNewTab(context),
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

  Widget _buildNewTabButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _createNewTab(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey[400]!,
              width: 2,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add,
                  size: 48,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 8),
                Text(
                  'webview_new_tab'.tr,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createNewTab(BuildContext context) async {
    final plugin = WebViewPlugin.instance;

    if (!plugin.tabManager.canAddTab) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('webview_max_tabs_reached'.tr)),
      );
      return;
    }

    await plugin.tabManager.createTab(
      url: 'about:blank',
      title: '新标签页',
      setActive: true,
    );

    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _closeTab(BuildContext context, String tabId) async {
    final plugin = WebViewPlugin.instance;
    await plugin.tabManager.closeTab(tabId);

    if (plugin.tabManager.tabs.isEmpty && context.mounted) {
      Navigator.pop(context);
      Navigator.pop(context); // 也退出浏览器界面
    }
  }

  Future<void> _confirmCloseAll(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('webview_close_all_tabs'.tr),
        content: Text('webview_confirm_close_all'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              MaterialLocalizations.of(context).okButtonLabel,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await WebViewPlugin.instance.tabManager.closeAllTabs();
      if (context.mounted) {
        Navigator.pop(context);
        Navigator.pop(context); // 也退出浏览器界面
      }
    }
  }
}

/// 标签页预览卡片
class _TabPreviewCard extends StatelessWidget {
  final WebViewTab tab;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _TabPreviewCard({
    required this.tab,
    required this.isActive,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isActive
          ? theme.primaryColor.withOpacity(0.1)
          : (isDark ? Colors.grey[850] : Colors.grey[100]),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? theme.primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部栏（标题和关闭按钮）
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                ),
                child: Row(
                  children: [
                    // Favicon
                    if (tab.favicon != null && tab.favicon!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Image.network(
                          tab.favicon!,
                          width: 16,
                          height: 16,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.language,
                            size: 16,
                          ),
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(Icons.language, size: 16),
                      ),

                    // 标题
                    Expanded(
                      child: Text(
                        tab.title.isNotEmpty ? tab.title : '新标签页',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // 关闭按钮
                    InkWell(
                      onTap: onClose,
                      borderRadius: BorderRadius.circular(10),
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(Icons.close, size: 16),
                      ),
                    ),
                  ],
                ),
              ),

              // 预览区域
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(10),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.language,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            _getDisplayUrl(tab.url),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDisplayUrl(String url) {
    if (url == 'about:blank') return '新标签页';
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (_) {
      return url;
    }
  }
}
