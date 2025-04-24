import 'package:flutter/material.dart';

// 卡片尺寸枚举
enum CardSize { small, wide, tall }

// 卡片尺寸工具类
class CardSizeUtils {
  // 字符串转换为卡片大小枚举
  static CardSize stringToCardSize(String sizeStr) {
    switch (sizeStr.toLowerCase()) {
      case 'wide':
        return CardSize.wide;
      case 'tall':
        return CardSize.tall;
      default:
        return CardSize.small;
    }
  }
  
  // 获取卡片尺寸名称
  static String cardSizeToString(CardSize size) {
    switch (size) {
      case CardSize.wide:
        return 'wide';
      case CardSize.tall:
        return 'tall';
      case CardSize.small:
        return 'small';
    }
  }
}