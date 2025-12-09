import 'package:get/get.dart';
import 'webdav_translations_zh.dart';
import 'webdav_translations_en.dart';

/// WebDAV设置GetX翻译类
class WebDAVTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': webdavTranslationsZh,
        'en_US': webdavTranslationsEn,
      };
}
