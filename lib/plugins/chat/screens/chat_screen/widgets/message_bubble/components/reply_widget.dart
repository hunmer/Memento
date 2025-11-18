import 'package:flutter/material.dart';
import '../../../../../../../plugins/chat/models/message.dart';

class ReplyWidget extends StatelessWidget {
  final Message replyMessage;
  final Function(String) onTap;
  final bool isLoading;
  final Color? highlightColor;

  const ReplyWidget({
    super.key,
    required this.replyMessage,
    required this.onTap,
    this.isLoading = false,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(replyMessage.id),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color:
                highlightColor?.withValues(alpha: 0.1) ??
                theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
            border: Border.all(
              color:
                  highlightColor?.withValues(alpha: 0.3) ??
                  theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                const LinearProgressIndicator(minHeight: 2)
              else
                Row(
                  children: [
                    Icon(
                      Icons.reply,
                      size: 12,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 
                        0.7,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        replyMessage.user.username,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              if (!isLoading) ...[
                const SizedBox(height: 2),
                Text(
                  replyMessage.content,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.8,
                    ),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
