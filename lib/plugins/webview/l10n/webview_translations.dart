import 'package:get/get.dart';
import 'webview_translations_zh.dart';
import 'webview_translations_en.dart';
import 'webview_translations_jp.dart';

/// WebView插件GetX翻译类
class WebViewTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': webviewTranslationsZh,
        'en_US': webviewTranslationsEn,
        'ja_JP': webviewTranslationsJp,
      };
}
