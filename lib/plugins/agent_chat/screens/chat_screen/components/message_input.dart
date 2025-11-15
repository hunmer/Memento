import 'dart:io';
import 'package:flutter/material.dart';
import '../../../controllers/chat_controller.dart';
import '../../../../../utils/file_picker_helper.dart';

/// 消息输入框组件
class MessageInput extends StatefulWidget {
  final ChatController controller;

  const MessageInput({
    super.key,
    required this.controller,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _textController.text = widget.controller.inputText;
    _textController.addListener(_onTextChanged);
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    widget.controller.removeListener(_onControllerChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    widget.controller.setInputText(_textController.text);
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});

      // 同步输入框文本
      if (_textController.text != widget.controller.inputText) {
        _textController.text = widget.controller.inputText;
        _textController.selection = TextSelection.collapsed(
          offset: _textController.text.length,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 文件预览区域
          if (widget.controller.selectedFiles.isNotEmpty)
            _buildFilePreview(),

          // 输入框区域
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 附件按钮
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _showAttachmentMenu,
                  tooltip: '添加附件',
                ),

                // 输入框
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: 40,
                      maxHeight: 120,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: '输入消息...',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        // 显示token统计
                        suffixIcon: widget.controller.inputText.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Center(
                                  widthFactor: 1.0,
                                  child: Text(
                                    '~${widget.controller.inputTokenCount}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // 发送按钮
                Container(
                  decoration: BoxDecoration(
                    color: widget.controller.inputText.trim().isEmpty ||
                            widget.controller.isSending
                        ? Colors.grey[300]
                        : Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: widget.controller.isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                    onPressed: widget.controller.inputText.trim().isEmpty ||
                            widget.controller.isSending
                        ? null
                        : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建文件预览
  Widget _buildFilePreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '已选择 ${widget.controller.selectedFiles.length} 个文件',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.controller.selectedFiles
                .asMap()
                .entries
                .map((entry) {
              final index = entry.key;
              final file = entry.value;
              return _buildFileChip(file, index);
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 构建文件芯片
  Widget _buildFileChip(File file, int index) {
    final isImage = FilePickerHelper.isImageFile(file);
    final fileName = FilePickerHelper.getFileName(file);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isImage ? Icons.image : FilePickerHelper.getFileIcon(file),
            size: 18,
            color: Colors.blue[700],
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              fileName,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => widget.controller.removeFile(index),
            child: const Icon(
              Icons.close,
              size: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// 显示附件菜单
  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('图片'),
              onTap: () {
                Navigator.pop(context);
                widget.controller.pickImages();
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('文档'),
              onTap: () {
                Navigator.pop(context);
                widget.controller.pickDocuments();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 发送消息
  Future<void> _sendMessage() async {
    if (widget.controller.inputText.trim().isEmpty) return;

    try {
      await widget.controller.sendMessage();
      _focusNode.requestFocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('发送失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
