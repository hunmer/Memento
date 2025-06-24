import 'package:flutter/material.dart';
import 'types.dart';

/// 消息输入动作抽屉组件
class MessageInputActionsDrawer extends StatelessWidget {
  final List<MessageInputAction> actions;
  final OnFileSelected? onFileSelected;
  final OnSendMessage? onSendMessage;

  const MessageInputActionsDrawer({
    super.key,
    required this.actions,
    this.onFileSelected,
    this.onSendMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.only(
        top: 16.0 + MediaQuery.of(context).padding.top,
        bottom: 16.0 + MediaQuery.of(context).padding.bottom,
        left: 16.0,
        right: 16.0,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Column(
        children: [
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.8,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 24.0,
              ),
              itemCount: actions.length,
              itemBuilder:
                  (context, index) => _buildActionItem(context, actions[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, MessageInputAction action) {
    return InkWell(
      onTap: () {
        Navigator.pop(context); // 关闭抽屉
        action.onTap();
      },
      borderRadius: BorderRadius.circular(12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60.0,
            height: 60.0,
            decoration: BoxDecoration(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[200],
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Icon(
              action.icon,
              color: Theme.of(context).colorScheme.primary,
              size: 28.0,
            ),
          ),
          const SizedBox(height: 12.0),
          Text(
            action.title,
            style: TextStyle(
              fontSize: 14.0,
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[300]
                      : Colors.grey[700],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
