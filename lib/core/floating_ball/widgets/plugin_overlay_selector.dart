import 'package:flutter/material.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/plugin_base.dart';
import 'package:Memento/core/floating_ball/plugin_overlay_manager.dart';
import 'package:get/get.dart';

/// 显示插件覆盖层对话框
/// 用于选择要在小窗口中打开的插件
void showPluginOverlayDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const PluginOverlaySelector(),
  );
}

/// 插件覆盖层选择器
/// 提供插件选择界面，选择后在小窗口中打开插件
class PluginOverlaySelector extends StatelessWidget {
  const PluginOverlaySelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
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
                '选择插件小窗口',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                '选择要在小窗口中打开的插件：',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Flexible(
                child: _buildPluginGrid(context),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('core_cancel'.tr),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPluginGrid(BuildContext context) {
    final plugins = PluginManager.instance.getAllPlugins(
      sortByRecentlyOpened: true,
    );
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = (screenWidth / 120).floor().clamp(2, 4);

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.85,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: plugins.length,
      itemBuilder: (context, index) {
        final plugin = plugins[index];
        return _buildPluginCard(context, plugin);
      },
    );
  }

  Widget _buildPluginCard(BuildContext context, PluginBase plugin) {
    return Card(
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () {
          Navigator.of(context).pop(); // 关闭选择对话框
          _showPluginOverlay(context, plugin); // 打开插件小窗口
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              plugin.icon ?? Icons.extension,
              size: 36,
              color: plugin.color ?? Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 8),
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

  void _showPluginOverlay(BuildContext context, PluginBase plugin) {
    // 使用PluginOverlayManager来管理覆盖层
    PluginOverlayManager().showPluginOverlay(context, plugin);
  }
}