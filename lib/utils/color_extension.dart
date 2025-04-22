import 'package:flutter/material.dart';

/// 颜色扩展类，用于处理颜色与十六进制字符串之间的转换
extension ColorExtension on Color {
  /// 将颜色转换为十六进制字符串
  String toHex() {
    return '#${(value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
  }
}

/// 十六进制颜色类，用于从十六进制字符串创建颜色
class HexColor {
  /// 从十六进制字符串创建颜色
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length <= 7) {
      buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
    } else {
      buffer.write(hexString.replaceFirst('#', ''));
    }
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}