import 'package:flutter/material.dart';

/// 颜色扩展方法
extension ColorExtension on Color {
  /// 将颜色转换为十六进制字符串
  String toHex() {
    return '#${(value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
  }
}

/// 十六进制颜色工具类
class HexColor {
  /// 从十六进制字符串创建颜色
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

/// 颜色生成工具类
class ColorGenerator {
  /// 根据字符串生成颜色（相同的文本总是生成相同的颜色）
  ///
  /// 使用 HSL 颜色空间确保生成的颜色有较好的视觉区分度和可读性：
  /// - 色相 (Hue): 0-360°，根据字符串哈希值生成
  /// - 饱和度 (Saturation): 0.6-0.8，保证颜色鲜艳
  /// - 亮度 (Lightness): 0.45-0.75，保证颜色清晰可读
  static Color fromString(String str) {
    final hash = str.hashCode.abs();
    final hue = (hash % 360).toDouble();
    final saturation = 0.6 + ((hash % 20) / 100.0);
    final lightness = 0.45 + ((hash % 30) / 100.0);
    return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
  }

  /// 根据字符串生成浅色背景色（用于卡片等背景）
  ///
  /// 使用较低的饱和度和较高的亮度，适合作为背景色
  static Color lightFromString(String str) {
    final hash = str.hashCode.abs();
    final hue = (hash % 360).toDouble();
    final saturation = 0.15 + ((hash % 10) / 100.0);
    final lightness = 0.85 + ((hash % 10) / 100.0);
    return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
  }

  /// 根据字符串生成深色背景色（适合暗色模式）
  ///
  /// 使用较低的饱和度和较低的亮度，适合作为暗色背景
  static Color darkFromString(String str) {
    final hash = str.hashCode.abs();
    final hue = (hash % 360).toDouble();
    final saturation = 0.15 + ((hash % 10) / 100.0);
    final lightness = 0.15 + ((hash % 10) / 100.0);
    return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
  }
}