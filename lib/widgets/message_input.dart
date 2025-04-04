import 'package:flutter/material.dart';
import '../services/image_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MessageInput extends StatefulWidget {
  final Function(String) onMessageSent;
  final TextEditingController? controller;
  final Function(String)? onChanged;

  const MessageInput({
    super.key,
    required this.onMessageSent,
    this.controller,
    this.onChanged,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  late final TextEditingController _controller;
  bool _isComposing = false;
  bool _showAttachments = false;

  // 用于控制输入框高度
  final FocusNode _focusNode = FocusNode();

  void _insertMarkdownStyle(String style) {
    final text = _controller.text;
    final selection = _controller.selection;

    // 检查选择是否有效
    if (selection.isValid &&
        selection.start >= 0 &&
        selection.end <= text.length) {
      // 有效的选择范围
      final selectedText = selection.textInside(text);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$style$selectedText$style',
      );

      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start + style.length * 2 + selectedText.length,
        ),
      );
    } else {
      // 无效的选择范围，插入样式标记并将光标放在中间
      final cursorPosition =
          selection.baseOffset >= 0 && selection.baseOffset <= text.length
              ? selection.baseOffset
              : text.length;

      final newText =
          text.substring(0, cursorPosition) +
          style +
          style +
          text.substring(cursorPosition);

      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: cursorPosition + style.length,
        ),
      );
    }
  }

  void _handleSubmitted() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onMessageSent(text);
      _controller.clear();
      setState(() {
        _isComposing = false;
      });
    }
  }

  void _toggleAttachments() {
    setState(() {
      _showAttachments = !_showAttachments;
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _isComposing = _controller.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            children: [
              // Markdown 样式按钮
              IconButton(
                icon: const Icon(Icons.format_bold),
                onPressed: () {
                  _insertMarkdownStyle('**');
                },
              ),
              IconButton(
                icon: const Icon(Icons.format_italic),
                onPressed: () {
                  _insertMarkdownStyle('*');
                },
              ),
              IconButton(
                icon: const Icon(Icons.format_strikethrough),
                onPressed: () {
                  _insertMarkdownStyle('~~');
                },
              ),
              // 加号按钮（附件）
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _toggleAttachments,
              ),
              // 自适应高度的输入框
              Expanded(
                child: RawKeyboardListener(
                  focusNode: FocusNode(),
                  onKey: (RawKeyEvent event) {
                    if (event is RawKeyDownEvent &&
                        event.isControlPressed &&
                        event.logicalKey == LogicalKeyboardKey.enter) {
                      _handleSubmitted();
                    }
                  },
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: null, // 允许多行
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (text) {
                      setState(() {
                        _isComposing = text.trim().isNotEmpty;
                      });
                      if (widget.onChanged != null) {
                        widget.onChanged!(text);
                      }
                    },
                    decoration: const InputDecoration(
                      hintText: '输入消息...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 10.0,
                        horizontal: 12.0,
                      ),
                    ),
                  ),
                ),
              ),
              // 发送按钮
              IconButton(
                icon: const Icon(Icons.send),
                color: Theme.of(context).colorScheme.primary,
                onPressed: _isComposing ? _handleSubmitted : null,
              ),
            ],
          ),
        ),
        // 附件抽屉
        if (_showAttachments) _buildAttachmentsDrawer(),
      ],
    );
  }

  Widget _buildAttachmentsDrawer() {
    return Container(
      height: 100,
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildAttachmentOption(Icons.image, '图片', () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('发送图片功能尚未实现')));
            setState(() {
              _showAttachments = false;
            });
          }),
          _buildAttachmentOption(Icons.file_present, '文件', () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('发送文件功能尚未实现')));
            setState(() {
              _showAttachments = false;
            });
          }),
          _buildAttachmentOption(Icons.camera_alt, '拍照', () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('拍照功能尚未实现')));
            setState(() {
              _showAttachments = false;
            });
          }),
          _buildAttachmentOption(Icons.location_on, '位置', () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('发送位置功能尚未实现')));
            setState(() {
              _showAttachments = false;
            });
          }),
        ],
      ),
    );
  }

  Widget _buildAttachmentOption(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 28,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
