import 'package:flutter/material.dart';
import '../../main.dart';
import 'card_size.dart';

class CardSizeManager {
  final Map<String, CardSize> cardSizes = {};

  // 获取插件的卡片大小，如果没有设置则返回默认值
  CardSize getCardSize(String pluginId) {
    return cardSizes[pluginId] ?? CardSize.small;
  }

  // 加载插件卡片大小设置
  Future<void> loadCardSizes() async {
    try {
      final cardSizesConfig = await globalConfigManager.getPluginConfig(
        'card_sizes',
      );
      if (cardSizesConfig != null) {
        final sizes = cardSizesConfig['sizes'] as Map<dynamic, dynamic>?;
        if (sizes != null) {
          sizes.forEach((key, value) {
            final pluginId = key.toString();
            final sizeStr = value.toString();
            cardSizes[pluginId] = CardSizeUtils.stringToCardSize(sizeStr);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading card sizes: $e');
    }
  }

  // 保存插件卡片大小设置
  Future<void> saveCardSizes() async {
    try {
      final Map<String, String> sizes = {};
      cardSizes.forEach((key, value) {
        sizes[key] = value.toString().split('.').last;
      });

      await globalConfigManager.savePluginConfig('card_sizes', {
        'sizes': sizes,
      });
    } catch (e) {
      debugPrint('Error saving card sizes: $e');
    }
  }
}