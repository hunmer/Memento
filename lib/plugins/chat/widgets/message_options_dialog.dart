import 'package:Memento/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';
import '../utils/message_options_handler.dart';
import '../l10n/chat_localizations.dart';

/// 消息选项对话框组件
class MessageOptionsDialog extends StatelessWidget {
  final Message message;
  final void Function(Message) onMessageEdit;
  final Future<void> Function(Message) onMessageDelete;
  final void Function(Message) onMessageCopy;
  final void Function(Message, String?) onSetFixedSymbol;
  final void Function(Message, Color?) onSetBubbleColor;
  final void Function(Message)? onReply; // 添加回复回调函数
  final void Function(Message)? onToggleFavorite; // 添加收藏回调函数
  final bool useRecentSymbols;
  final bool initiallyShowFixedSymbolDialog;

  const MessageOptionsDialog({
    super.key,
    required this.message,
    required this.onMessageEdit,
    required this.onMessageDelete,
    required this.onMessageCopy,
    required this.onSetFixedSymbol,
    required this.onSetBubbleColor,
    this.onReply,
    this.onToggleFavorite,
    this.useRecentSymbols = true,
    this.initiallyShowFixedSymbolDialog = false,
  });

  /// 显示消息选项对话框的静态方法
  static Future<void> show({
    required BuildContext context,
    required Message message,
    required void Function(Message) onMessageEdit,
    required Future<void> Function(Message) onMessageDelete,
    required void Function(Message) onMessageCopy,
    required void Function(Message, String?) onSetFixedSymbol,
    required void Function(Message, Color?) onSetBubbleColor,
    void Function(Message)? onReply,
    void Function(Message)? onToggleFavorite,
    bool useRecentSymbols = true,
    bool initiallyShowFixedSymbolDialog = false,
  }) {
    return showDialog(
      context: context,
      builder:
          (context) => MessageOptionsDialog(
            message: message,
            onMessageEdit: onMessageEdit,
            onMessageDelete: onMessageDelete,
            onMessageCopy: onMessageCopy,
            onSetFixedSymbol: onSetFixedSymbol,
            onSetBubbleColor: onSetBubbleColor,
            onReply: onReply,
            onToggleFavorite: onToggleFavorite,
            useRecentSymbols: useRecentSymbols,
            initiallyShowFixedSymbolDialog: initiallyShowFixedSymbolDialog,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 如果需要直接显示固态符号对话框，在构建后使用微任务调用
    if (initiallyShowFixedSymbolDialog) {
      Future.microtask(() {
        Navigator.pop(context);
        _showFixedSymbolDialog(context);
      });
    }

    return AlertDialog(
      title: Text(ChatLocalizations.of(context)!.messageOptions),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 设置气泡颜色选项
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 重置按钮
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: GestureDetector(
                      onTap: () {
                        onSetBubbleColor(message, null);
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.grey[400]!,
                            width: 1,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.refresh,
                            size: 20,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 颜色选项
                  ...[
                    const Color(0xFFD6E4FF), // 默认蓝色
                    Colors.pink[100]!,
                    Colors.purple[100]!,
                    Colors.green[100]!,
                    Colors.orange[100]!,
                    Colors.teal[100]!,
                    Colors.amber[100]!,
                    Colors.grey[200]!, // 默认灰色
                  ].map(
                    (color) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: GestureDetector(
                        onTap: () {
                          onSetBubbleColor(message, color);
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.grey[400]!,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          // 功能按钮区域 - 使用Wrap实现自动换行，每行最多5个
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12.0, // 水平间距
              runSpacing: 12.0, // 垂直间距
              children:
                  [
                        // 设置固定标记
                        _buildIconButton(
                          context,
                          Icons.push_pin,
                          Colors.blue,
                          () {
                            Navigator.pop(context);
                            _showFixedSymbolDialog(context);
                          },
                        ),
                        // 编辑
                        _buildIconButton(context, Icons.edit, Colors.green, () {
                          Navigator.pop(context);
                          onMessageEdit(message);
                        }),
                        // 复制
                        _buildIconButton(context, Icons.copy, Colors.amber, () {
                          Navigator.pop(context);
                          onMessageCopy(message);
                        }),
                        // 删除
                        _buildIconButton(context, Icons.delete, Colors.red, () {
                          Navigator.pop(context);
                          onMessageDelete(message);
                        }),
                        // 分享
                        _buildIconButton(
                          context,
                          Icons.share,
                          Colors.purple,
                          () {
                            Navigator.pop(context);
                            MessageOptionsHandler.shareMessage(
                              context,
                              message,
                            );
                          },
                        ),
                        // 回复
                        if (onReply != null)
                          _buildIconButton(
                            context,
                            Icons.reply,
                            Colors.indigo,
                            () {
                              Navigator.pop(context);
                              onReply!(message);
                            },
                          ),
                        // 收藏
                        if (onToggleFavorite != null)
                          _buildIconButton(
                            context,
                            // 根据消息是否已收藏显示不同图标
                            (message.metadata?['isFavorite'] as bool?) == true
                                ? Icons.star
                                : Icons.star_border,
                            Colors.amber,
                            () {
                              Navigator.pop(context);
                              onToggleFavorite!(message);
                            },
                          ),
                      ]
                      .map(
                        (button) => SizedBox(
                          width: 50, // 固定宽度，确保每行最多5个
                          child: button,
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }

  // 获取最近使用的符号列表
  Future<List<String>> _getRecentSymbols() async {
    if (!useRecentSymbols) return [];
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('recentSymbols') ?? [];
  }

  // 添加新使用的符号到列表
  Future<void> _addRecentSymbol(String symbol) async {
    if (!useRecentSymbols) return;
    final prefs = await SharedPreferences.getInstance();
    List<String> recentSymbols = prefs.getStringList('recentSymbols') ?? [];

    // 如果符号已存在，先移除旧的
    recentSymbols.remove(symbol);
    // 将新符号添加到列表开头
    recentSymbols.insert(0, symbol);
    // 保持列表最多20个符号
    if (recentSymbols.length > 20) {
      recentSymbols = recentSymbols.sublist(0, 20);
    }

    await prefs.setStringList('recentSymbols', recentSymbols);
  }

  void _showFixedSymbolDialog(BuildContext context) async {
    final TextEditingController symbolController = TextEditingController();
    final List<String> recentSymbols = await _getRecentSymbols();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(ChatLocalizations.of(context)!.addEmoji),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: symbolController,
                  decoration: InputDecoration(
                    labelText: ChatLocalizations.of(context).tag,
                    hintText: ChatLocalizations.of(context).tagHint,
                  ),
                  maxLength: 1, // 限制只能输入一个字符
                ),
                if (useRecentSymbols && recentSymbols.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    '最近使用',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        recentSymbols
                            .map(
                              (symbol) => ActionChip(
                                label: Text(symbol),
                                onPressed: () {
                                  symbolController.text = symbol;
                                },
                              ),
                            )
                            .toList(),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () async {
                  final symbol =
                      symbolController.text.isEmpty
                          ? null
                          : symbolController.text;
                  if (symbol != null) {
                    await _addRecentSymbol(symbol);
                  }
                  onSetFixedSymbol(message, symbol);
                  Navigator.pop(context);
                },
                child: Text(ChatLocalizations.of(context)!.settings),
              ),
            ],
          ),
    );
  }

  // 构建图标按钮
  Widget _buildIconButton(
    BuildContext context,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
