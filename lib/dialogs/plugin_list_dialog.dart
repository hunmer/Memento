import 'package:Memento/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../core/plugin_manager.dart';
import '../core/plugin_base.dart';

class PluginListDialog extends StatelessWidget {
  final bool sortByRecentlyOpened;

  const PluginListDialog({super.key, this.sortByRecentlyOpened = true});

  @override
  Widget build(BuildContext context) {
    // 获取屏幕宽度以计算合适的网格列数
    final screenWidth = MediaQuery.of(context).size.width;
    // 根据屏幕宽度计算合适的网格列数
    final crossAxisCount = (screenWidth / 120).floor().clamp(2, 5);

    return Dialog(
      // 使用更大的对话框以便展示更多插件
      child: Container(
        width: screenWidth * 0.85,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '插件列表',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Flexible(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount:
                      PluginManager.instance
                          .getAllPlugins(
                            sortByRecentlyOpened: sortByRecentlyOpened,
                          )
                          .length,
                  itemBuilder: (context, index) {
                    final plugin =
                        PluginManager.instance.getAllPlugins(
                          sortByRecentlyOpened: sortByRecentlyOpened,
                        )[index];
                    return _buildPluginCard(context, plugin);
                  },
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context)!.close),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建插件卡片
  Widget _buildPluginCard(BuildContext context, PluginBase plugin) {
    // 如果没有自定义卡片视图，使用默认卡片布局
    return Card(
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () {
          Navigator.of(context).pop();
          PluginManager.instance.openPlugin(context, plugin);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 插件图标
            Icon(
              plugin.icon ?? Icons.extension,
              size: 36,
              color: plugin.color ?? Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 8),
            // 插件名称
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                plugin.getPluginName(context) ?? plugin.id,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 显示插件列表对话框
void showPluginListDialog(
  BuildContext context, {
  bool sortByRecentlyOpened = true,
}) {
  showDialog(
    context: context,
    builder:
        (context) =>
            PluginListDialog(sortByRecentlyOpened: sortByRecentlyOpened),
  );
}
