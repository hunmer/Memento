import 'package:flutter/material.dart';

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
}
