import 'package:flutter/material.dart';
import 'package:Memento/plugins/chat/l10n/chat_localizations.dart';

class EmptyChannelView extends StatelessWidget {
  final VoidCallback onAddChannel;

  const EmptyChannelView({
    super.key,
    required this.onAddChannel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            ChatLocalizations.of(context).channelList,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onAddChannel,
            icon: const Icon(Icons.add),
            label: Text(
              ChatLocalizations.of(context).newChannel,
            ),
          ),
        ],
      ),
    );
  }
}