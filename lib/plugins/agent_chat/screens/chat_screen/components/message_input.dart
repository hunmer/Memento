import 'dart:io';
import 'package:flutter/material.dart';
import '../../../controllers/chat_controller.dart';
import '../../../models/chat_command.dart';
import '../../../models/saved_tool_template.dart';
import '../../../../../utils/file_picker_helper.dart';
import 'suggested_questions_dialog.dart';
import 'command_selector.dart';
import 'tool_template_selector.dart';

/// 消息输入框组件
class MessageInput extends StatefulWidget {
  final ChatController controller;

  const MessageInput({super.key, required this.controller});

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // 命令模式状态
  bool _isCommandMode = false;
  List<ChatCommand> _filteredCommands = [];

  // 工具模板搜索状态
  bool _isSearchingTools = false;
  List<SavedToolTemplate> _searchResults = [];
  bool _isLoadingToolResults = false;
  String? _toolSearchKeyword;

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
    final text = _textController.text;
    widget.controller.setInputText(text);

    // 检测命令模式
    setState(() {
      if (text.startsWith('/') && !text.contains('\n')) {
        _isCommandMode = true;
        _filteredCommands = ChatCommand.filterCommands(text);
      } else {
        _isCommandMode = false;
        _filteredCommands = [];
      }
    });
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 工具模板搜索结果
          if (_isSearchingTools) _buildToolTemplateSearchArea(),

          // 命令选择器
          if (_isCommandMode && _filteredCommands.isNotEmpty)
            CommandSelector(
              commands: _filteredCommands,
              onCommandSelected: _handleCommandSelected,
            ),

          // 当前状态显示区域（工具模板和文件）
          if (!_isSearchingTools &&
              (widget.controller.selectedToolTemplate != null ||
                  widget.controller.selectedFiles.isNotEmpty))
            _buildCurrentStatus(),

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
                      enabled: widget.controller.currentAgent != null,
                      decoration: InputDecoration(
                        hintText:
                            widget.controller.currentAgent != null
                                ? '输入消息...'
                                : '请先选择Agent...',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        // 显示token统计和"你可以问"按钮
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Token统计
                              if (widget.controller.inputText.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Text(
                                    '~${widget.controller.inputTokenCount}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              // "你可以问"按钮
                              if (widget.controller.currentAgent != null)
                                InkWell(
                                  onTap: _showSuggestedQuestions,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.lightbulb_outline,
                                      size: 20,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // 发送按钮
                Container(
                  decoration: BoxDecoration(
                    color:
                        widget.controller.inputText.trim().isEmpty ||
                                widget.controller.isSending ||
                                widget.controller.currentAgent == null
                            ? Colors.grey[300]
                            : Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon:
                        widget.controller.isSending
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(Icons.send, color: Colors.white),
                    onPressed:
                        widget.controller.inputText.trim().isEmpty ||
                                widget.controller.isSending ||
                                widget.controller.currentAgent == null
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

  /// 构建当前状态显示
  Widget _buildCurrentStatus() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 工具模板
          if (widget.controller.selectedToolTemplate != null) ...[
            Row(
              children: [
                Icon(Icons.build_circle, size: 16, color: Colors.orange[700]),
                const SizedBox(width: 6),
                Text(
                  '使用工具模板',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildToolTemplateChip(widget.controller.selectedToolTemplate!),
          ],

          // 分隔
          if (widget.controller.selectedToolTemplate != null &&
              widget.controller.selectedFiles.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey[300]),
            const SizedBox(height: 12),
          ],

          // 文件
          if (widget.controller.selectedFiles.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.attach_file, size: 16, color: Colors.blue[700]),
                const SizedBox(width: 6),
                Text(
                  '已选择 ${widget.controller.selectedFiles.length} 个文件',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  widget.controller.selectedFiles.asMap().entries.map((entry) {
                    final index = entry.key;
                    final file = entry.value;
                    return _buildFileChip(file, index);
                  }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建工具模板芯片
  Widget _buildToolTemplateChip(SavedToolTemplate template) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.build_circle, size: 18, color: Colors.orange[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[900],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${template.steps.length} 个步骤',
                  style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => widget.controller.clearSelectedToolTemplate(),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Icon(Icons.close, size: 14, color: Colors.orange[700]),
            ),
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
            child: const Icon(Icons.close, size: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// 显示附件菜单
  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
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

  /// 显示预设问题对话框
  Future<void> _showSuggestedQuestions() async {
    final selectedQuestion = await showSuggestedQuestionsDialog(context);

    if (selectedQuestion != null && mounted) {
      // 将选中的问题填充到输入框
      _textController.text = selectedQuestion;
      widget.controller.setInputText(selectedQuestion);

      // 聚焦到输入框
      _focusNode.requestFocus();
    }
  }

  /// 构建工具模板搜索区域
  Widget _buildToolTemplateSearchArea() {
    if (_isLoadingToolResults) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey[300]!),
            bottom: BorderSide(color: Colors.grey[300]!),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              '正在加载工具模板...',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty && (_toolSearchKeyword?.isNotEmpty ?? false)) {
      return _buildToolSearchEmptyState();
    }

    return ToolTemplateSelector(
      templates: _searchResults,
      onTemplateSelected: _handleTemplateSelected,
      onCancel: () {
        setState(() {
          _isSearchingTools = false;
          _isLoadingToolResults = false;
          _searchResults = [];
          _toolSearchKeyword = null;
        });
      },
    );
  }

  Widget _buildToolSearchEmptyState() {
    final keyword = _toolSearchKeyword ?? '';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Icon(Icons.search_off, size: 20, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '找不到 $keyword',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    setState(() {
                      _isSearchingTools = false;
                      _isLoadingToolResults = false;
                      _searchResults = [];
                      _toolSearchKeyword = null;
                    });
                  },
                  tooltip: '取消',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              '没有找到匹配的工具模板，请尝试其他关键词。',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 处理命令选择
  void _handleCommandSelected(ChatCommand command) {
    switch (command.type) {
      case ChatCommandType.files:
        _executeFilesCommand();
        break;
      case ChatCommandType.tools:
        // 如果需要参数，填充命令模板
        if (command.requiresArgument) {
          _textController.text = '/${command.command} ';
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: _textController.text.length),
          );
          _focusNode.requestFocus();
        } else {
          _executeToolsCommand(null);
        }
        break;
    }
  }

  /// 执行 /files 命令
  void _executeFilesCommand() {
    // 清空输入框
    _textController.clear();
    widget.controller.setInputText('');

    // 显示附件菜单
    _showAttachmentMenu();
  }

  /// 执行 /tools 命令
  void _executeToolsCommand(String? searchQuery) {
    // 清空输入框
    _textController.clear();
    widget.controller.setInputText('');

    final keyword = searchQuery?.trim();
    final normalizedKeyword =
        (keyword == null || keyword.isEmpty) ? null : keyword;

    setState(() {
      _isSearchingTools = true;
      _isLoadingToolResults = true;
      _searchResults = [];
      _toolSearchKeyword = normalizedKeyword;
    });

    widget.controller
        .fetchToolTemplates(keyword: normalizedKeyword)
        .then((results) {
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isLoadingToolResults = false;
      });
    }).catchError((error) {
      if (!mounted) return;
      setState(() {
        _isLoadingToolResults = false;
        _searchResults = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('加载工具模板失败: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  /// 处理模板选择
  void _handleTemplateSelected(SavedToolTemplate template) {
    // 选中模板
    widget.controller.setSelectedToolTemplate(template);

    // 关闭搜索
    setState(() {
      _isSearchingTools = false;
      _searchResults = [];
      _toolSearchKeyword = null;
    });

    // 聚焦输入框
    _focusNode.requestFocus();
  }

  /// 发送消息
  Future<void> _sendMessage() async {
    final text = widget.controller.inputText.trim();
    if (text.isEmpty) return;

    // 检查是否是命令
    if (text.startsWith('/')) {
      final (commandType, argument) = ChatCommand.parseInput(text);

      if (commandType != null) {
        // 执行命令
        switch (commandType) {
          case ChatCommandType.files:
            _executeFilesCommand();
            return;
          case ChatCommandType.tools:
            _executeToolsCommand(argument);
            return;
        }
      } else {
        // 无效命令
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无效的命令'), backgroundColor: Colors.red),
          );
        }
        return;
      }
    }

    // 正常发送消息
    try {
      await widget.controller.sendMessage();
      _focusNode.requestFocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发送失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
