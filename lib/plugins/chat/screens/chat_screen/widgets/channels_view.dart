import 'package:flutter/material.dart';
import '../../../models/channel.dart';
import '../../../models/message.dart';
import '../controllers/chat_screen_controller.dart';
import './message_list.dart';
import './message_input.dart';
import '../utils/message_list_builder.dart';

class ChannelsView extends StatelessWidget {
  final Channel channel;
  final ChatScreenController controller;
  final Function(Message) onMessageEdit;
  final Future<void> Function(Message) onMessageDelete;
  final Function(Message) onMessageCopy;
  final Function(Message, String?) onSetFixedSymbol;
  final Function(Message, Color?) onSetBubbleColor;

  const ChannelsView({
    super.key,
    required this.channel,
    required this.controller,
    required this.onMessageEdit,
    required this.onMessageDelete,
    required this.onMessageCopy,
    required this.onSetFixedSymbol,
    required this.onSetBubbleColor,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: MessageListBuilder.buildMessageListWithDateSeparators(
        controller.messages,
        controller.selectedDate,
      ),
      builder: (context, snapshot) {
        final messageItems = snapshot.data ?? [];

        return Column(
          children: [
            Expanded(
              child: MessageList(
                items: messageItems,
                isMultiSelectMode: controller.isMultiSelectMode,
                selectedMessageIds: controller.selectedMessageIds,
                onMessageEdit: onMessageEdit,
                onMessageDelete: onMessageDelete,
                onMessageCopy: onMessageCopy,
                onSetFixedSymbol: onSetFixedSymbol,
                onSetBubbleColor: onSetBubbleColor,
                onToggleMessageSelection: controller.toggleMessageSelection,
                scrollController: controller.scrollController,
              ),
            ),
            MessageInput(
              controller: controller.draftController,
              onSendMessage: controller.sendMessage,
              onSaveDraft: controller.saveDraft,
            ),
          ],
        );
      },
    );
  }
}
