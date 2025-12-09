import 'package:get/get.dart';
import 'floating_ball_translations_zh.dart';
import 'floating_ball_translations_en.dart';

/// 悬浮球GetX翻译类
class FloatingBallTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': floatingBallTranslationsZh,
        'en_US': floatingBallTranslationsEn,
      };
}
