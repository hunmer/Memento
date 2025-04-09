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
  
  const ChannelsView({
    super.key,
    required this.channel,
    required this.controller,
    required this.onMessageEdit,
    required this.onMessageDelete,
    required this.onMessageCopy,
    required this.onSetFixedSymbol,
  });

  @override
  Widget build(BuildContext context) {
    final messageItems = MessageListBuilder.buildMessageListWithDateSeparators(
      controller.messages,
      controller.selectedDate,
    );

    return Column(
      children: [
        Expanded(
          child: MessageList(
            items: MessageListBuilder.buildMessageListWithDateSeparators(
              controller.messages,
              controller.selectedDate,
            ),
            isMultiSelectMode: controller.isMultiSelectMode,
            selectedMessageIds: controller.selectedMessageIds,
            onMessageEdit: onMessageEdit,
            onMessageDelete: onMessageDelete,
            onMessageCopy: onMessageCopy,
            onSetFixedSymbol: onSetFixedSymbol,
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
  }
}