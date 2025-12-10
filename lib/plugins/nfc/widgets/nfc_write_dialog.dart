import 'package:flutter/material.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:get/get.dart';
import '../models/nfc_record_item.dart';
import '../models/nfc_record_type.dart';

/// NFC 写入对话框
class NfcWriteDialog extends StatefulWidget {
  final Function(List<Map<String, String>>) onWrite;

  const NfcWriteDialog({super.key, required this.onWrite});

  @override
  State<NfcWriteDialog> createState() => _NfcWriteDialogState();
}

class _NfcWriteDialogState extends State<NfcWriteDialog> {
  final List<NfcRecordItem> _records = [];

  @override
  void initState() {
    super.initState();
    // 默认添加一条空记录
    _addRecord();
  }

  @override
  void dispose() {
    for (var record in _records) {
      record.dispose();
    }
    super.dispose();
  }

  void _addRecord() {
    setState(() {
      _records.add(NfcRecordItem());
    });
  }

  void _removeRecord(int index) {
    if (_records.length > 1) {
      setState(() {
        _records[index].dispose();
        _records.removeAt(index);
      });
    }
  }

  String _getHintText(NfcRecordType type) {
    switch (type) {
      case NfcRecordType.uri:
        return '例如: https://example.com 或 memento://...';
      case NfcRecordType.text:
        return '输入要写入的文本内容';
      case NfcRecordType.mime:
        return '格式: mime类型|内容 (例如: application/json|{"key":"value"})';
      case NfcRecordType.aar:
        return '应用包名 (例如: github.hunmer.memento)';
      case NfcRecordType.external_:
        return '格式: domain:type|内容 (例如: memento:checkin|item_id)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.edit_note),
          const SizedBox(width: 8),
          Text('nfc_writeNFCData'.tr),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 提示信息
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '支持添加多条记录，点击"开始写入"后靠近NFC标签',
                      style: TextStyle(color: Colors.blue[700], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 记录列表
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _records.length,
                itemBuilder: (context, index) {
                  final record = _records[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 记录头部：类型选择 + 删除按钮
                          Row(
                            children: [
                              Text(
                                '记录 ${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              // 类型选择下拉框
                              DropdownButton<NfcRecordType>(
                                value: record.type,
                                isDense: true,
                                underline: const SizedBox(),
                                items: NfcRecordType.values.map((type) {
                                  return DropdownMenuItem(
                                    value: type,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(type.icon, size: 16),
                                        const SizedBox(width: 4),
                                        Text(type.label, style: const TextStyle(fontSize: 13)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      record.type = value;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              // 删除按钮
                              if (_records.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                  color: Colors.red,
                                  onPressed: () => _removeRecord(index),
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // 数据输入框
                          TextField(
                            controller: record.controller,
                            decoration: InputDecoration(
                              hintText: _getHintText(record.type),
                              hintStyle: const TextStyle(fontSize: 12),
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              isDense: true,
                            ),
                            maxLines: 2,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // 添加记录按钮
            TextButton.icon(
              onPressed: _addRecord,
              icon: const Icon(Icons.add),
              label: const Text('添加记录'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('nfc_cancel'.tr),
        ),
        ElevatedButton.icon(
          onPressed: () {
            // 过滤空记录
            final records = _records
                .where((r) => r.controller.text.isNotEmpty)
                .map((r) => r.toMap())
                .toList();
            if (records.isEmpty) {
              Toast.error('请至少输入一条记录');
              return;
            }
            widget.onWrite(records);
          },
          icon: const Icon(Icons.nfc),
          label: Text('nfc_startWriting'.tr),
        ),
      ],
    );
  }
}
