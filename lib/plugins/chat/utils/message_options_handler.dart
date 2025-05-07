import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';
import '../models/file_message.dart';
import '../widgets/message_options_dialog.dart';

/// 统一管理消息选项的处理逻辑
class MessageOptionsHandler {
  /// 显示消息选项对话框
  static Future<void> showOptionsDialog({
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
    return MessageOptionsDialog.show(
      context: context,
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
    );
  }

  /// 复制消息内容到剪贴板
  static void copyMessageContent(BuildContext context, Message message) {
    if (message.type == MessageType.received || message.type == MessageType.sent) {
      Clipboard.setData(ClipboardData(text: message.content));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已复制到剪贴板')),
      );
    }
  }

  /// 保存最近使用的固定符号
  static Future<void> saveRecentSymbol(String symbol) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> recentSymbols = prefs.getStringList('recent_symbols') ?? [];
      
      // 如果符号已存在，先移除它
      recentSymbols.remove(symbol);
      
      // 将符号添加到列表开头
      recentSymbols.insert(0, symbol);
      
      // 保持列表不超过10个项目
      if (recentSymbols.length > 10) {
        recentSymbols = recentSymbols.sublist(0, 10);
      }
      
      await prefs.setStringList('recent_symbols', recentSymbols);
    } catch (e) {
      debugPrint('保存最近符号失败: $e');
    }
  }

  /// 获取最近使用的固定符号
  static Future<List<String>> getRecentSymbols() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList('recent_symbols') ?? [];
    } catch (e) {
      debugPrint('获取最近符号失败: $e');
      return [];
    }
  }

  /// 分享消息内容
  static void shareMessage(BuildContext context, Message message) {
    String shareContent = '';
    
    // 根据消息类型准备分享内容
    if (message.type == MessageType.received || message.type == MessageType.sent) {
      shareContent = message.content;
    } else if (message.type == MessageType.file || 
               message.type == MessageType.image ||
               message.type == MessageType.video) {
      try {
        final fileInfo = FileMessage.fromJson(
          Map<String, dynamic>.from(
            message.metadata![Message.metadataKeyFileInfo],
          ),
        );
        shareContent = fileInfo.filePath;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('无法分享文件: $e')),
        );
        return;
      }
    }
    
    // 调用系统分享
    if (shareContent.isNotEmpty) {
      Share.share(shareContent);
    }
  }
}