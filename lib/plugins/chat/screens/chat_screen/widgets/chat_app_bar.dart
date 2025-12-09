import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:Memento/plugins/chat/models/channel.dart';
import 'package:Memento/plugins/chat/chat_plugin.dart';
import 'package:Memento/widgets/image_picker_dialog.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Channel channel;
  final bool isMultiSelectMode;
  final int selectedCount;
  final VoidCallback onShowDatePicker;
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
    required this.onCopySelected,
    required this.onDeleteSelected,
    required this.onShowClearConfirmation,
    required this.onExitMultiSelect,
    required this.onEnterMultiSelect,
  });

  String _getLocalizedText(
    BuildContext context,
    String defaultText,
    String Function(ChatLocalizations) getter,
  ) {
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
        title: Text(
          _getLocalizedText(
            context,
            '$selectedCount selected',
            (l) => l.selectedMessages.replaceAll(
              '{count}',
              selectedCount.toString(),
            ),
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.copy), onPressed: onCopySelected),
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
          itemBuilder:
              (context) => [
                PopupMenuItem(
                  value: 'multiselect',
                  child: Row(
                    children: [
                      const Icon(Icons.check_box_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _getLocalizedText(
                          context,
                          'Select Multiple',
                          (l) => l.multiSelectMode,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_sweep, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _getLocalizedText(
                          context,
                          'Clear Messages',
                          (l) => l.clearMessages,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'background',
                  child: Row(
                    children: [
                      const Icon(Icons.wallpaper, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _getLocalizedText(
                          context,
                          'Set Background',
                          (l) => l.setBackground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
          onSelected: (value) async {
            switch (value) {
              case 'multiselect':
                onEnterMultiSelect();
                break;
              case 'clear':
                onShowClearConfirmation();
                break;
              case 'background':
                final result = await showDialog(
                  context: context,
                  builder:
                      (context) => ImagePickerDialog(
                        saveDirectory: path.join('chat', 'backgrounds'),
                        enableCrop: true,
                        cropAspectRatio: 9 / 16, // 竖屏比例
                      ),
                );
                if (result != null && result is Map<String, dynamic>) {
                  // 直接使用result中返回的url路径
                  if (result.containsKey('url') && result['url'] != null) {
                    // 更新频道背景
                    await ChatPlugin.instance.channelService
                        .updateChannelBackground(
                          channel.id,
                          result['url'], // 直接使用返回的url
                        );
                  }
                }
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
