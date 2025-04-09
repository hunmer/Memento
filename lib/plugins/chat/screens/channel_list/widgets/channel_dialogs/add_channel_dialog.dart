import 'package:flutter/material.dart';
import '../../../../models/channel.dart';
import '../../../../../../widgets/circle_icon_picker.dart';
import '../../../../l10n/chat_localizations.dart';
// import '../../../../models/serialization_helpers.dart';

class AddChannelDialog extends StatefulWidget {
  final Function(Channel) onAddChannel;

  const AddChannelDialog({super.key, required this.onAddChannel});

  @override
  State<AddChannelDialog> createState() => _AddChannelDialogState();
}

class _AddChannelDialogState extends State<AddChannelDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _groupController = TextEditingController();
  IconData _selectedIcon = Icons.chat;
  Color _selectedColor = Colors.blue;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(ChatLocalizations.of(context)?.newChannel ?? 'New Channel'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Channel Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter channel name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _groupController,
                decoration: const InputDecoration(labelText: 'Channel Group (Optional)'),
              ),
              const SizedBox(height: 16),
              CircleIconPicker(
                currentIcon: _selectedIcon,
                backgroundColor: _selectedColor,
                onIconSelected: (icon) {
                  setState(() {
                    _selectedIcon = icon;
                  });
                },
                onColorSelected: (color) {
                  setState(() {
                    _selectedColor = color;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final newChannel = Channel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: _titleController.text,
                groups: _groupController.text.isNotEmpty
                    ? [_groupController.text]
                    : ['Default'],
                icon: _selectedIcon,
                backgroundColor: _selectedColor,
                priority: 0,
                members: [], // 添加空的成员列表
                messages: [], // 添加空的消息列表
              );
              widget.onAddChannel(newChannel);
              Navigator.of(context).pop();
            }
          },
          child: Text(ChatLocalizations.of(context)?.newChannel ?? 'New Channel'),
        ),
      ],
    );
  }
}