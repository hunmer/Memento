import 'package:flutter/material.dart';

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
          const Text(
            "这里没有任何频道",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onAddChannel,
            icon: const Icon(Icons.add),
            label: const Text("点击右上角添加频道"),
          ),
        ],
      ),
    );
  }
}