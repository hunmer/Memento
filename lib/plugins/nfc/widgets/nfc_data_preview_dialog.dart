import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Memento/widgets/smooth_bottom_sheet.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:get/get.dart';

/// NFC 数据预览对话框
///
/// 用于展示NFC写入数据的详细信息，包括字段类型和数据值
/// 即使NFC功能不可用，也可以查看和复制数据
class NfcDataPreviewDialog {
  /// 显示NFC数据预览对话框
  ///
  /// [context] - 上下文
  /// [title] - 对话框标题
  /// [records] - NFC记录列表，每条记录包含 type 和 data 字段
  static Future<void> show({
    required BuildContext context,
    required String title,
    required List<Map<String, String>> records,
  }) {
    return SmoothBottomSheet.showWithTitle(
      context: context,
      title: title,
      showCloseButton: true,
      child: _NfcDataPreviewContent(records: records),
    );
  }
}

/// NFC 数据预览内容组件
class _NfcDataPreviewContent extends StatelessWidget {
  final List<Map<String, String>> records;

  const _NfcDataPreviewContent({
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 说明文字
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'nfc_dataPreviewDescription'.tr,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 数据表格
          _buildDataTable(context),

          const SizedBox(height: 16),

          // 复制全部按钮
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _copyAllRecords(context),
              icon: const Icon(Icons.copy_all),
              label: Text('nfc_copyAllRecords'.tr),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建数据表格
  Widget _buildDataTable(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // 表头
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'nfc_fieldType'.tr,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Text(
                    'nfc_fieldData'.tr,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 48), // 操作列宽度
              ],
            ),
          ),

          // 表格内容
          ...records.asMap().entries.map((entry) {
            final index = entry.key;
            final record = entry.value;
            final isLast = index == records.length - 1;

            return _buildDataRow(
              context,
              type: record['type'] ?? '',
              data: record['data'] ?? '',
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }

  /// 构建数据行
  Widget _buildDataRow(
    BuildContext context, {
    required String type,
    required String data,
    required bool isLast,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 类型列
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getTypeColor(type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                type,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: _getTypeColor(type),
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 数据列
          Expanded(
            flex: 5,
            child: SelectableText(
              data,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ),

          // 复制按钮
          IconButton(
            onPressed: () => _copyToClipboard(context, data),
            icon: const Icon(Icons.content_copy, size: 18),
            tooltip: 'nfc_copyData'.tr,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
          ),
        ],
      ),
    );
  }

  /// 获取类型对应的颜色
  Color _getTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'URI':
        return Colors.blue;
      case 'AAR':
        return Colors.green;
      case 'TEXT':
        return Colors.orange;
      case 'MIME':
        return Colors.purple;
      case 'EXTERNAL':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  /// 复制单条数据到剪贴板
  void _copyToClipboard(BuildContext context, String data) {
    Clipboard.setData(ClipboardData(text: data));
    Toast.success('nfc_copiedToClipboard'.tr);
  }

  /// 复制所有记录到剪贴板
  void _copyAllRecords(BuildContext context) {
    final buffer = StringBuffer();

    for (var i = 0; i < records.length; i++) {
      final record = records[i];
      buffer.writeln('Record ${i + 1}:');
      buffer.writeln('  Type: ${record['type']}');
      buffer.writeln('  Data: ${record['data']}');
      if (i < records.length - 1) {
        buffer.writeln();
      }
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    Toast.success('nfc_allRecordsCopied'.tr);
  }
}
