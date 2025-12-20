import 'package:flutter/material.dart';
import 'package:Memento/plugins/nfc/widgets/nfc_data_preview_dialog.dart';

/// NFC 卡片处理器基类
abstract class BaseCardHandler {
  /// 卡片名称
  String get name;

  /// 卡片描述
  String get description;

  /// 卡片图标
  IconData get icon;

  /// 卡片颜色
  Color get color;

  /// 执行写入操作
  Future<void> executeWrite(BuildContext context);

  /// 构建卡片 UI
  Widget buildCard(BuildContext context, bool isEnabled, bool isWriting);

  /// 获取用于预览的NFC记录数据
  ///
  /// 返回一个包含NFC记录的Future，如果数据无法获取则返回null
  /// 每条记录包含 'type' 和 'data' 字段
  Future<List<Map<String, String>>?> getRecordsForPreview(BuildContext context);

  /// 显示数据预览对话框
  ///
  /// 即使NFC功能不可用，也可以查看和复制数据
  Future<void> showDataPreview(BuildContext context) async {
    final records = await getRecordsForPreview(context);

    if (records == null || records.isEmpty) {
      return;
    }

    if (context.mounted) {
      await NfcDataPreviewDialog.show(
        context: context,
        title: name,
        records: records,
      );
    }
  }
}
