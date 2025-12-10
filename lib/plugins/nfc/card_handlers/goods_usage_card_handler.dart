import 'package:flutter/material.dart';
import 'package:Memento/core/services/plugin_data_selector/index.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:memento_nfc/memento_nfc.dart';
import 'package:get/get.dart';
import 'base_card_handler.dart';

/// 物品使用记录卡片处理器
class GoodsUsageCardHandler extends BaseCardHandler {
  @override
  String get name => '写入物品使用记录';

  @override
  String get description => '选择物品后写入NFC标签，扫描即可添加使用记录';

  @override
  IconData get icon => Icons.inventory_2;

  @override
  Color get color => Colors.orange;

  @override
  Future<void> executeWrite(BuildContext context) async {
    // 打开物品选择器
    final result = await pluginDataSelectorService.showSelector(
      context,
      'goods.item',
    );

    if (result == null || result.cancelled) {
      return;
    }

    // 获取选择的物品 ID 和名称
    final itemId = result.path.isNotEmpty ? result.path.last.selectedItem.id : null;
    final itemName = result.path.isNotEmpty ? result.path.last.selectedItem.title : null;

    if (itemId == null) {
      Toast.error('未能获取物品 ID');
      return;
    }

    // 构建深度链接 URL
    final deepLinkUrl = 'memento://goods/usage?itemId=$itemId&action=add_usage';

    // 显示等待对话框
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('nfc_pleaseBringPhoneNearNFC'.tr),
              const SizedBox(height: 8),
              Text(
                '正在写入物品使用记录数据...\n物品: $itemName',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final nfc = MementoNfc();
      // 同时写入 URI 和 AAR 记录，确保扫描时打开正确的应用
      final writeResult = await nfc.writeNfcRecords([
        {'type': 'URI', 'data': deepLinkUrl},
        {'type': 'AAR', 'data': 'github.hunmer.memento'},
      ]);

      // 关闭等待对话框
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (writeResult.success) {
        Toast.success('写入成功！扫描此标签即可快速添加「$itemName」的使用记录');
      } else {
        Toast.error(writeResult.error ?? '写入失败');
      }
    } catch (e) {
      // 关闭等待对话框
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      Toast.error('写入错误: $e');
    }
  }

  @override
  Widget buildCard(BuildContext context, bool isEnabled, bool isWriting) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: isWriting || !isEnabled ? null : () => executeWrite(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isWriting
                    ? const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                      )
                    : Icon(icon, size: 28, color: isEnabled ? color : Colors.grey),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isWriting ? '写入中...' : name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isEnabled ? color : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
