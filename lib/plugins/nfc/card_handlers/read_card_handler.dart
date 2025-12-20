import 'package:flutter/material.dart';
import 'base_card_handler.dart';

/// 读取 NFC 卡片处理器
class ReadCardHandler extends BaseCardHandler {
  final VoidCallback onRead;

  ReadCardHandler({required this.onRead});

  @override
  String get name => '读取NFC';

  @override
  String get description => '将手机靠近\nNFC标签读取';

  @override
  IconData get icon => Icons.nfc;

  @override
  Color get color => Colors.blue;

  @override
  Future<List<Map<String, String>>?> getRecordsForPreview(BuildContext context) async {
    // 读取操作不需要预览功能
    return null;
  }

  @override
  Future<void> executeWrite(BuildContext context) async {
    onRead();
  }

  @override
  Widget buildCard(BuildContext context, bool isEnabled, bool isReading) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: isReading || !isEnabled ? null : onRead,
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
                  child: isReading
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
                  isReading ? '读取中...' : name,
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
