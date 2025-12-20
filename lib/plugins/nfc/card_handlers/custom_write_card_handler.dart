import 'package:flutter/material.dart';
import '../widgets/nfc_write_dialog.dart';
import 'base_card_handler.dart';

/// 自定义写入卡片处理器
class CustomWriteCardHandler extends BaseCardHandler {
  final Function(List<Map<String, String>>) onWrite;

  CustomWriteCardHandler({required this.onWrite});

  @override
  String get name => '写入NFC';

  @override
  String get description => '输入数据后\n靠近标签写入';

  @override
  IconData get icon => Icons.edit;

  @override
  Color get color => Colors.orange;

  @override
  Future<List<Map<String, String>>?> getRecordsForPreview(BuildContext context) async {
    // 自定义写入通过对话框输入数据，不需要单独的预览功能
    return null;
  }

  @override
  Future<void> executeWrite(BuildContext context) async {
    showDialog(
      context: context,
      builder: (dialogContext) => NfcWriteDialog(
        onWrite: (records) {
          Navigator.pop(dialogContext);
          onWrite(records);
        },
      ),
    );
  }

  @override
  Widget buildCard(BuildContext context, bool isEnabled, bool isWriting) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: isWriting || !isEnabled ? null : () => executeWrite(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: isWriting
                      ? const Center(
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          ),
                        )
                      : Icon(icon, size: 32, color: isEnabled ? color : Colors.grey),
                ),
                const SizedBox(height: 12),
                Text(
                  isWriting ? '写入中...' : name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
