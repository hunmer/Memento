import 'package:flutter/material.dart';
import 'package:Memento/core/services/plugin_data_selector/index.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:memento_nfc/memento_nfc.dart';
import 'package:get/get.dart';
import 'base_card_handler.dart';

/// 目标追踪进度卡片处理器
class TrackerProgressCardHandler extends BaseCardHandler {
  @override
  String get name => '写入目标追踪进度';

  @override
  String get description => '选择目标后写入NFC标签，扫描即可快速增加进度';

  @override
  IconData get icon => Icons.track_changes;

  @override
  Color get color => Colors.red;

  @override
  Future<List<Map<String, String>>?> getRecordsForPreview(BuildContext context) async {
    // 打开目标选择器
    final result = await pluginDataSelectorService.showSelector(
      context,
      'tracker.goal',
    );

    if (result == null || result.cancelled) {
      return null;
    }

    // 获取选择的目标 ID 和名称
    final goalId = result.path.isNotEmpty ? result.path.last.selectedItem.id : null;
    final goalName = result.path.isNotEmpty ? result.path.last.selectedItem.title : null;

    if (goalId == null) {
      Toast.error('未能获取目标 ID');
      return null;
    }

    // 显示对话框让用户输入增加的值
    if (!context.mounted) return null;

    final valueController = TextEditingController();
    final value = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('设置增加的值'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '目标: $goalName',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: valueController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '增加的值',
                hintText: '请输入要增加的数值',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Text(
              '扫描此标签时将自动为目标「$goalName」增加此数值',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = valueController.text.trim();
              if (text.isEmpty) {
                Toast.error('请输入有效的数值');
                return;
              }
              final parsedValue = double.tryParse(text);
              if (parsedValue == null || parsedValue <= 0) {
                Toast.error('请输入大于0的数值');
                return;
              }
              Navigator.of(dialogContext).pop(parsedValue);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );

    // 用户取消或未输入有效值
    if (value == null) {
      return null;
    }

    // 构建深度链接 URL
    final deepLinkUrl = 'memento://tracker/progress?goalId=$goalId&value=$value';

    // 返回NFC记录数据
    return [
      {'type': 'URI', 'data': deepLinkUrl},
      {'type': 'AAR', 'data': 'github.hunmer.memento'},
    ];
  }

  @override
  Future<void> executeWrite(BuildContext context) async {
    // 获取NFC记录数据
    final records = await getRecordsForPreview(context);

    if (records == null || records.isEmpty) {
      return;
    }

    // 提取goalName和value用于提示
    final deepLinkUrl = records[0]['data'] ?? '';
    final goalNameMatch = RegExp(r'goalId=([^&]+)').firstMatch(deepLinkUrl);
    final goalName = goalNameMatch?.group(1) ?? '未知目标';
    final valueMatch = RegExp(r'value=([^&]+)').firstMatch(deepLinkUrl);
    final value = valueMatch?.group(1) ?? '0';

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
                '正在写入目标追踪数据...\n目标: $goalName\n增加值: $value',
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
      // 使用已构建的records进行写入
      final writeResult = await nfc.writeNfcRecords(records);

      // 关闭等待对话框
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (writeResult.success) {
        Toast.success('写入成功！扫描此标签即可快速为「$goalName」增加 $value');
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
              // 预览数据按钮
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 20),
                onPressed: isWriting ? null : () => showDataPreview(context),
                tooltip: 'nfc_previewData'.tr,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
              ),
              const SizedBox(width: 8),
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
