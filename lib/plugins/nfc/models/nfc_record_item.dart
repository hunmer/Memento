import 'package:flutter/material.dart';
import 'nfc_record_type.dart';

/// NFC 记录数据模型
class NfcRecordItem {
  NfcRecordType type;
  String data;
  final TextEditingController controller;

  NfcRecordItem({
    this.type = NfcRecordType.text,
    this.data = '',
  }) : controller = TextEditingController(text: data);

  void dispose() {
    controller.dispose();
  }

  Map<String, String> toMap() {
    return {
      'type': type.value,
      'data': controller.text,
    };
  }
}
