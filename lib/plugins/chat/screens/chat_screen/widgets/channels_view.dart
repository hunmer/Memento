import 'package:flutter/material.dart';
import 'package:Memento/plugins/chat/models/channel.dart';
import 'package:Memento/plugins/chat/models/message.dart';
import 'package:Memento/plugins/chat/screens/chat_screen/controllers/chat_screen_controller.dart';
import './message_list.dart';
import './message_input/message_input.dart';
import 'package:Memento/plugins/chat/screens/chat_screen/utils/message_list_builder.dart';

class ChannelsView extends StatelessWidget {
  final Channel channel;
  final ChatScreenController controller;
  final Function(Message) onMessageEdit;
  final Future<void> Function(Message) onMessageDelete;
  final Function(Message) onMessageCopy;
  final Function(Message, String?) onSetFixedSymbol;
  final Function(Message, Color?) onSetBubbleColor;
  final Function(Message) onReply;
  final Function(String) onReplyTap;
  final Function(Message)? onAvatarTap;
  final Function(Message) onToggleFavorite;
  final bool showAvatar;
  final String? currentUserId;
  final Message? highlightedMessage;
  final bool shouldHighlight;

  const ChannelsView({
    super.key,
    required this.channel,
    required this.controller,
    required this.onMessageEdit,
    required this.onMessageDelete,
    required this.onMessageCopy,
    required this.onSetFixedSymbol,
    required this.onSetBubbleColor,
    required this.onReply,
    required this.onReplyTap,
    required this.onToggleFavorite,
    this.onAvatarTap,
    this.showAvatar = true,
    this.currentUserId,
    this.highlightedMessage,
    this.shouldHighlight = false,
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
        final messageIndexMap = <String, int>{};
        for (var i = 0; i < controller.messages.length; i++) {
          messageIndexMap[controller.messages[i].id] = i;
        }

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
                onReply: onReply,
                onReplyTap: onReplyTap,
                onToggleFavorite: onToggleFavorite,
                onAvatarTap: onAvatarTap,
                showAvatar: showAvatar,
                currentUserId: currentUserId,
                highlightedMessage: highlightedMessage,
                shouldHighlight: shouldHighlight,
                messageIndexMap: messageIndexMap,
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
