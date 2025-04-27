import 'package:flutter/material.dart';
import '../../../models/channel.dart';
import '../../../l10n/chat_localizations.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Channel channel;
  final bool isMultiSelectMode;
  final int selectedCount;
  final VoidCallback onShowDatePicker;
  final VoidCallback onShowChannelInfo;
  final VoidCallback onCopySelected;
  final VoidCallback onDeleteSelected;
  final VoidCallback onShowClearConfirmation;
  final VoidCallback onExitMultiSelect;
  final VoidCallback onEnterMultiSelect;

  const ChatAppBar({
    super.key,
    required this.channel,
    required this.isMultiSelectMode,
    required this.selectedCount,
    required this.onShowDatePicker,
    required this.onShowChannelInfo,
    required this.onCopySelected,
    required this.onDeleteSelected,
    required this.onShowClearConfirmation,
    required this.onExitMultiSelect,
    required this.onEnterMultiSelect,
  });

  String _getLocalizedText(BuildContext context, String defaultText, String Function(ChatLocalizations) getter) {
    final localizations = ChatLocalizations.of(context);
    return localizations != null ? getter(localizations) : defaultText;
  }

  @override
  Widget build(BuildContext context) {
    if (isMultiSelectMode) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: onExitMultiSelect,
        ),
        title: Text(_getLocalizedText(
          context,
          '$selectedCount selected',
          (l) => l.selectedMessages.replaceAll('{count}', selectedCount.toString()),
        )),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: onCopySelected,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: onDeleteSelected,
          ),
        ],
      );
    }

    return AppBar(
      title: Text(channel.title),
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: onShowDatePicker,
        ),
        PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'multiselect',
              child: Row(
                children: [
                  const Icon(Icons.check_box_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text(_getLocalizedText(context, 'Select Multiple', (l) => l.multiSelectMode)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'info',
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20),
                  const SizedBox(width: 8),
                  Text(_getLocalizedText(context, 'Channel Info', (l) => l.channelInfo)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit, size: 20),
                  const SizedBox(width: 8),
                  Text(_getLocalizedText(context, 'Edit Profile', (l) => l.editProfile ?? 'Edit Profile')),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  const Icon(Icons.delete_sweep, size: 20),
                  const SizedBox(width: 8),
                  Text(_getLocalizedText(context, 'Clear Messages', (l) => l.clearMessages)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'multiselect':
                onEnterMultiSelect();
                break;
              case 'info':
                onShowChannelInfo();
                break;
              case 'clear':
                onShowClearConfirmation();
                break;
            }
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}