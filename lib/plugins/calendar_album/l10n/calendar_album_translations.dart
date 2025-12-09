import 'package:get/get.dart';
import 'calendar_album_translations_zh.dart';
import 'calendar_album_translations_en.dart';

/// 日历相册插件国际化 - GetX Translations
class CalendarAlbumTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': CalendarAlbumTranslationsZh.translations,
        'en_US': CalendarAlbumTranslationsEn.translations,
      };
}
