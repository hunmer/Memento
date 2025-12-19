import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/plugins/chat/models/tag.dart';

/// 标签卡片组件
/// 显示标签名称和消息数量，支持点击跳转
class TagCard extends StatelessWidget {
  final MessageTag tag;
  final VoidCallback onTap;

  const TagCard({
    super.key,
    required this.tag,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 标签名称（带#前缀）
              Row(
                children: [
                  Icon(
                    Icons.tag,
                    size: 16,
                    color: tag.color ?? colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '#${tag.name}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // 消息数量
              Text(
                'chat_messageCount'.trParams({'count': tag.messageCount.toString()}),
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
