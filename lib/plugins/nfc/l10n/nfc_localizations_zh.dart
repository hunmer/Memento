import 'package:flutter/material.dart';
import 'nfc_localizations.dart';

/// NFC插件的中文本地化实现
class NfcLocalizationsZh extends NfcLocalizations {
  NfcLocalizationsZh() : super('zh');

  @override
  String get pleaseBringPhoneNearNFC => '请将手机靠近NFC标签';

  @override
  String get writeNFCData => '写入NFC数据';

  @override
  String get cancel => '取消';

  @override
  String get startWriting => '开始写入';

  @override
  String get nfcData => 'NFC数据';

  @override
  String get close => '关闭';

  @override
  String get copyData => '复制数据';

  @override
  String get nfcController => 'NFC控制器';

  @override
  String get enableNFC => '启用NFC';

  // Timer Dialog 相关
  @override
  String get cancelTimer => '取消计时';

  @override
  String get continueTimer => '继续计时';

  @override
  String get confirmCancel => '确定取消';

  @override
  String get completeTimer => '完成计时';

  @override
  String get continueAdjust => '继续调整';

  @override
  String get confirmComplete => '确定完成';

  @override
  String get quickNotes => '快速笔记';

  @override
  String get addQuickNote => '添加一条快速笔记...';

  @override
  String get pause => '暂停';

  @override
  String get start => '开始';

  @override
  String get cancelBtn => '取消';

  @override
  String get complete => '完成';

  @override
  String get pauseTimerConfirm => '确定要取消计时吗？\n'
      '已计时: {time}\n\n'
      '⚠️ 本次计时记录将不会保存';

  @override
  String get completeTimerConfirm => '确定要完成计时并保存记录吗？\n'
      '已计时: {time}\n'
      '{note}\n'
      '✅ 本次计时将保存到历史记录';

  @override
  String get timerNotePrefix => '备注: ';

  @override
  String get timerWarning => '';

  @override
  String get timerSuccess => '';
}