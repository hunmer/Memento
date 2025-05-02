import 'package:flutter/material.dart';
import '../../../../../../../plugins/chat/models/message.dart';

class ReplyWidget extends StatelessWidget {
  final Message replyMessage;
  final Function(String) onTap;

  const ReplyWidget({
    super.key,
    required this.replyMessage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(replyMessage.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "${replyMessage.user.username}: ${replyMessage.content}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}