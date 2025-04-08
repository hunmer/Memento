import 'package:flutter/material.dart';
import '../../../../models/channel.dart';
import '../../../../widgets/circle_icon_picker.dart';
// import '../../../../models/serialization_helpers.dart';

class EditChannelDialog extends StatefulWidget {
  final Channel channel;
  final Function(Channel) onUpdateChannel;

  const EditChannelDialog({
    super.key,
    required this.channel,
    required this.onUpdateChannel,
  });

  @override
  State<EditChannelDialog> createState() => _EditChannelDialogState();
}

class _EditChannelDialogState extends State<EditChannelDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _groupController;
  late IconData _selectedIcon;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.channel.title);
    _groupController = TextEditingController(
        text: widget.channel.groups.isNotEmpty
            ? widget.channel.groups.join(', ')
            : '');
    _selectedIcon = widget.channel.icon;
    _selectedColor = widget.channel.backgroundColor;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _groupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑频道'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: '频道名称'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入频道名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _groupController,
                decoration: const InputDecoration(
                  labelText: '频道分组（多个分组用逗号分隔）',
                ),
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
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final List<String> groups = _groupController.text.isEmpty
                  ? ['默认']
                  : _groupController.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();

              final updatedChannel = Channel(
                id: widget.channel.id,
                title: _titleController.text,
                groups: groups,
                icon: _selectedIcon,
                backgroundColor: _selectedColor,
                priority: widget.channel.priority,
                lastMessage: widget.channel.lastMessage,
                draft: widget.channel.draft,
                members: widget.channel.members,
                messages: widget.channel.messages,
              );

              widget.onUpdateChannel(updatedChannel);
              Navigator.of(context).pop();
            }
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}