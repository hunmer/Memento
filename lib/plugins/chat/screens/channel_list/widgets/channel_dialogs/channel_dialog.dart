import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/plugins/chat/models/channel.dart';
import 'package:Memento/widgets/picker/circle_icon_picker.dart';
import '../../../../../../../core/services/toast_service.dart';

class ChannelDialog extends StatefulWidget {
  // 用于区分是添加还是编辑模式
  final bool isEditMode;
  // 编辑模式时传入的频道
  final Channel? channel;
  // 添加频道的回调
  final Future<void> Function(Channel)? onAddChannel;
  // 更新频道的回调
  final Function(Channel)? onUpdateChannel;
  // 默认的频道分组
  final String? defaultGroup;

  const ChannelDialog({
    super.key,
    this.isEditMode = false,
    this.channel,
    this.onAddChannel,
    this.onUpdateChannel,
    this.defaultGroup,
  }) : assert(
         (isEditMode && channel != null && onUpdateChannel != null) ||
             (!isEditMode && onAddChannel != null),
         '编辑模式需要提供channel和onUpdateChannel，添加模式需要提供onAddChannel',
       );

  @override
  State<ChannelDialog> createState() => _ChannelDialogState();
}

class _ChannelDialogState extends State<ChannelDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _groupController;
  late IconData _selectedIcon;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode && widget.channel != null) {
      // 编辑模式，初始化为现有频道数据
      _titleController = TextEditingController(text: widget.channel!.title);
      _groupController = TextEditingController(
        text:
            widget.channel!.groups.isNotEmpty
                ? widget.channel!.groups.join(', ')
                : '',
      );
      _selectedIcon = widget.channel!.icon;
      _selectedColor = widget.channel!.backgroundColor;
    } else {
      // 添加模式，使用默认值
      _titleController = TextEditingController();
      _groupController = TextEditingController(text: widget.defaultGroup ?? '');
      _selectedIcon = Icons.chat;
      _selectedColor = Colors.blue;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _groupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.isEditMode ? '编辑频道' : ('chat_newChannel'.tr);

    return AlertDialog(
      title: Text(title),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'chat_channelName'.tr,
                ),
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
                decoration: InputDecoration(
                  labelText: 'chat_channelGroupLabel'.tr,
                  hintText: 'chat_channelGroupHint'.tr,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('chat_cancel'.tr),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final List<String> groups =
                  _groupController.text.isEmpty
                      ? []
                      : _groupController.text
                          .replaceAll('，', ',')
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();

              if (widget.isEditMode && widget.channel != null) {
                // 编辑模式
                final updatedChannel = Channel(
                  id: widget.channel!.id,
                  title: _titleController.text,
                  groups: groups,
                  icon: _selectedIcon,
                  backgroundColor: _selectedColor,
                  priority: widget.channel!.priority,
                  lastMessage: widget.channel!.lastMessage,
                  draft: widget.channel!.draft,
                  messages: widget.channel!.messages,
                  backgroundPath: widget.channel!.backgroundPath, // 保留背景图片路径
                );

                widget.onUpdateChannel!(updatedChannel);
                Navigator.of(context).pop();
              } else {
                // 添加模式
                // 显示加载指示器
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return const Center(child: CircularProgressIndicator());
                  },
                );

                try {
                  final newChannel = Channel(
                    id: const Uuid().v4(),
                    title: _titleController.text,
                    groups: groups,
                    icon: _selectedIcon,
                    backgroundColor: _selectedColor,
                    priority: 0,
                    messages: [], // 添加空的消息列表
                  );

                  // 异步调用添加频道
                  await widget.onAddChannel!(newChannel);

                  // 关闭加载指示器和对话框
                  if (context.mounted) {
                    Navigator.of(context).pop(); // 关闭加载指示器
                    Navigator.of(context).pop(); // 关闭添加频道对话框
                  }
                } catch (e) {
                  // 关闭加载指示器
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    // 显示错误提示
                    toastService.showToast('${'chat_channelCreationFailed'.tr}: $e');
                  }
                }
              }
            }
          },
          child: Text(
            widget.isEditMode
                ? 'save'.tr
                : 'chat_create'.tr,
          ),
        ),
      ],
    );
  }
}
