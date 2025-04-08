import 'package:flutter/material.dart';
import '../../../models/channel.dart';

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

  @override
  Widget build(BuildContext context) {
    if (isMultiSelectMode) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: onExitMultiSelect,
        ),
        title: Text('已选择 $selectedCount 条消息'),
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
            const PopupMenuItem(
              value: 'multiselect',
              child: Row(
                children: [
                  Icon(Icons.check_box_outlined, size: 20),
                  SizedBox(width: 8),
                  Text('多选模式'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'info',
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20),
                  SizedBox(width: 8),
                  Text('频道信息'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.delete_sweep, size: 20),
                  SizedBox(width: 8),
                  Text('清空消息'),
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