import 'package:flutter/material.dart';

/// NFC 记录类型
enum NfcRecordType {
  uri('URI', '链接/URI', Icons.link),
  text('TEXT', '纯文本', Icons.text_fields),
  mime('MIME', 'MIME类型', Icons.data_object),
  aar('AAR', '应用记录', Icons.android),
  external_('EXTERNAL', '外部类型', Icons.extension);

  final String value;
  final String label;
  final IconData icon;
  const NfcRecordType(this.value, this.label, this.icon);
}
