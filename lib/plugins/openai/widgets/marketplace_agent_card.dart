import 'dart:io';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/utils/image_utils.dart';
import 'package:Memento/plugins/openai/models/ai_agent.dart';
import 'package:Memento/plugins/openai/screens/agent_edit_screen.dart';

/// 商场 Agent 卡片
/// 在基础 AgentCard 的基础上增加安装状态显示
class MarketplaceAgentCard extends StatefulWidget {
  final AIAgent agent;
  final bool isInstalled;
  final bool hasUpdate;
  final VoidCallback? onAgentChanged; // 安装/更新后的回调

  const MarketplaceAgentCard({
    super.key,
    required this.agent,
    this.isInstalled = false,
    this.hasUpdate = false,
    this.onAgentChanged,
  });

  @override
  State<MarketplaceAgentCard> createState() => _MarketplaceAgentCardState();
}

class _MarketplaceAgentCardState extends State<MarketplaceAgentCard> {
  final GlobalKey _cardKey = GlobalKey();

  AIAgent get agent => widget.agent;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: _cardKey,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final result = await NavigationHelper.openContainerWithHero(
            context,
            (context) => AgentEditScreen(
              agent: agent,
              // 传递是否来自商场的标识
              isFromMarketplace: true,
            ),
            sourceKey: _cardKey,
            heroTag: 'marketplace_agent_card_${agent.id}',
          );

          // 如果安装成功，通知父组件刷新
          if (result == true && widget.onAgentChanged != null) {
            widget.onAgentChanged!();
          }
        },
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Agent Icon
                Expanded(child: Center(child: _buildAgentIcon())),

                // Agent Info
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agent.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '服务商: ${agent.serviceProviderId}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      _buildTags(),
                    ],
                  ),
                ),
              ],
            ),

            // 安装状态标识
            if (widget.isInstalled || widget.hasUpdate)
              Positioned(top: 8, right: 8, child: _buildStatusBadge()),
          ],
        ),
      ),
    );
  }

  /// 构建状态徽章
  Widget _buildStatusBadge() {
    if (widget.hasUpdate) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.update, size: 14, color: Colors.white),
            SizedBox(width: 4),
            Text(
              '可更新',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (widget.isInstalled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 14, color: Colors.white),
            SizedBox(width: 4),
            Text(
              '已安装',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildAgentIcon() {
    // 如果有头像，优先显示头像
    if (agent.avatarUrl != null && agent.avatarUrl!.isNotEmpty) {
      return FutureBuilder<String>(
        future: ImageUtils.getAbsolutePath(agent.avatarUrl),
        builder: (context, snapshot) {
          return SizedBox(
            width: 80,
            height: 80,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getColorForServiceProvider(
                    agent.serviceProviderId,
                  ).withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: ClipOval(
                    child:
                        agent.avatarUrl!.startsWith('http')
                            ? Image.network(
                              agent.avatarUrl!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) =>
                                      _buildDefaultIcon(),
                            )
                            : snapshot.hasData
                            ? Image.file(
                              File(snapshot.data!),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) =>
                                      _buildDefaultIcon(),
                            )
                            : _buildDefaultIcon(),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    // 如果有自定义图标，使用自定义图标
    if (agent.icon != null) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              agent.iconColor ??
              _getColorForServiceProvider(agent.serviceProviderId),
        ),
        child: Icon(agent.icon, size: 40, color: Colors.white),
      );
    }

    // 默认图标
    return _buildDefaultIcon();
  }

  Widget _buildDefaultIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getColorForServiceProvider(agent.serviceProviderId),
      ),
      child: const Icon(Icons.smart_toy, size: 40, color: Colors.white),
    );
  }

  Color _getColorForServiceProvider(String providerId) {
    switch (providerId) {
      case 'openai':
        return Colors.green;
      case 'azure':
        return Colors.blue;
      case 'ollama':
        return Colors.orange;
      case 'deepseek':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTags() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children:
          agent.tags.take(2).map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                ),
              ),
            );
          }).toList(),
    );
  }
}
