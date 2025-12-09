import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/plugins/chat/models/channel.dart';

class DeleteChannelDialog extends StatelessWidget {
  final Channel channel;
  final Function(String) onDeleteChannel;

  const DeleteChannelDialog({
    super.key,
    required this.channel,
    required this.onDeleteChannel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('chat_deleteChannel'.tr),
      content: Text('chat_deleteChannelConfirmation'.tr),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            onDeleteChannel(channel.id);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white, // 设置文字颜色为白色，确保在红色背景上清晰可见
          ),
          child: Text(
            AppLocalizations.of(context)!.delete,
            style: TextStyle(
              fontWeight: FontWeight.bold, // 加粗文字增强可见性
            ),
          ),
        ),
      ],
    );
  }
}
