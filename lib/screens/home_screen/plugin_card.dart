import 'package:flutter/material.dart';
import '../../core/plugin_base.dart';
import '../../core/plugin_manager.dart';
import 'card_size.dart';

class PluginCard extends StatelessWidget {
  final PluginBase plugin;
  final bool isReorderMode;
  final CardSize cardSize;
  final Function(BuildContext) onShowSizeMenu;

  const PluginCard({
    super.key,
    required this.plugin,
    required this.isReorderMode,
    required this.cardSize,
    required this.onShowSizeMenu,
  });

  @override
  Widget build(BuildContext context) {
    final customCardView = plugin.buildCardView(context);

    return Builder(
      builder:
          (cardContext) => Material(
            color: Colors.transparent,
            child: InkWell(
              onLongPress: () => onShowSizeMenu(cardContext),
              child: Card(
                elevation: 2.0,
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.all(4.0),
                child: Stack(
                  children: [
                    InkWell(
                      onTap: () {
                        // 使用PluginManager的openPlugin方法
                        PluginManager.instance.openPlugin(context, plugin);
                      },
                      child: customCardView ?? _buildDefaultCard(context),
                    ),
                    if (isReorderMode)
                      Positioned.fill(
                        child: Material(
                          color: Colors.black12,
                          child: const Center(
                            child: Icon(
                              Icons.drag_handle,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildDefaultCard(BuildContext context) {
    // 根据卡片大小计算图标大小
    final iconSize = cardSize.width > 1 || cardSize.height > 1 ? 72.0 : 48.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment:
                  cardSize.height > 1
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    plugin.icon ?? Icons.extension,
                    size: iconSize * 0.5625, // 36/64 = 0.5625
                    color: plugin.color ?? Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  plugin.getPluginName(context) ?? plugin.id,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                  maxLines: cardSize.height > 1 ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
