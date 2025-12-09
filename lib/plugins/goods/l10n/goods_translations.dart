import 'package:get/get.dart';
import 'goods_translations_zh.dart';
import 'goods_translations_en.dart';

/// 物品管理插件的 GetX Translations 类
class GoodsTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': goodsTranslationsZh,
        'en_US': goodsTranslationsEn,
      };
}
