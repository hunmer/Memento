import 'package:get/get.dart';

// 应用层
import 'app_translations_zh.dart';
import 'app_translations_en.dart';
import 'app_translations_jp.dart';

// 核心层
import '../core/l10n/core_translations_zh.dart';
import '../core/l10n/core_translations_en.dart';
import '../core/l10n/core_translations_jp.dart';

// 插件层 (21个)
import '../plugins/activity/l10n/activity_translations_zh.dart';
import '../plugins/activity/l10n/activity_translations_en.dart';
import '../plugins/activity/l10n/activity_translations_jp.dart';
import '../plugins/bill/l10n/bill_translations_zh.dart';
import '../plugins/bill/l10n/bill_translations_en.dart';
import '../plugins/bill/l10n/bill_translations_jp.dart';
import '../plugins/calendar/l10n/calendar_translations_zh.dart';
import '../plugins/calendar/l10n/calendar_translations_en.dart';
import '../plugins/calendar/l10n/calendar_translations_jp.dart';
import '../plugins/calendar_album/l10n/calendar_album_translations_zh.dart';
import '../plugins/calendar_album/l10n/calendar_album_translations_en.dart';
import '../plugins/calendar_album/l10n/calendar_album_translations_jp.dart';
import '../plugins/chat/l10n/chat_translations_zh.dart';
import '../plugins/chat/l10n/chat_translations_en.dart';
import '../plugins/chat/l10n/chat_translations_jp.dart';
import '../plugins/checkin/l10n/checkin_translations_zh.dart';
import '../plugins/checkin/l10n/checkin_translations_en.dart';
import '../plugins/checkin/l10n/checkin_translations_jp.dart';
import '../plugins/contact/l10n/contact_translations_zh.dart';
import '../plugins/contact/l10n/contact_translations_en.dart';
import '../plugins/contact/l10n/contact_translations_jp.dart';
import '../plugins/database/l10n/database_translations_zh.dart';
import '../plugins/database/l10n/database_translations_en.dart';
import '../plugins/database/l10n/database_translations_jp.dart';
import '../plugins/day/l10n/day_translations_zh.dart';
import '../plugins/day/l10n/day_translations_en.dart';
import '../plugins/day/l10n/day_translations_jp.dart';
import '../plugins/diary/l10n/diary_translations_zh.dart';
import '../plugins/diary/l10n/diary_translations_en.dart';
import '../plugins/diary/l10n/diary_translations_jp.dart';
import '../plugins/goods/l10n/goods_translations_zh.dart';
import '../plugins/goods/l10n/goods_translations_en.dart';
import '../plugins/goods/l10n/goods_translations_jp.dart';
import '../plugins/habits/l10n/habits_translations_zh.dart';
import '../plugins/habits/l10n/habits_translations_en.dart';
import '../plugins/habits/l10n/habits_translations_jp.dart';
import '../plugins/nodes/l10n/nodes_translations_zh.dart';
import '../plugins/nodes/l10n/nodes_translations_en.dart';
import '../plugins/nodes/l10n/nodes_translations_jp.dart';
import '../plugins/notes/l10n/notes_translations_zh.dart';
import '../plugins/notes/l10n/notes_translations_en.dart';
import '../plugins/notes/l10n/notes_translations_jp.dart';
import '../plugins/openai/l10n/openai_translations_zh.dart';
import '../plugins/openai/l10n/openai_translations_en.dart';
import '../plugins/openai/l10n/openai_translations_jp.dart';
import '../plugins/scripts_center/l10n/scripts_center_translations_zh.dart';
import '../plugins/scripts_center/l10n/scripts_center_translations_en.dart';
import '../plugins/scripts_center/l10n/scripts_center_translations_jp.dart';
import '../plugins/store/l10n/store_translations_zh.dart';
import '../plugins/store/l10n/store_translations_en.dart';
import '../plugins/store/l10n/store_translations_jp.dart';
import '../plugins/timer/l10n/timer_translations_zh.dart';
import '../plugins/timer/l10n/timer_translations_en.dart';
import '../plugins/timer/l10n/timer_translations_jp.dart';
import '../plugins/todo/l10n/todo_translations_zh.dart';
import '../plugins/todo/l10n/todo_translations_en.dart';
import '../plugins/todo/l10n/todo_translations_jp.dart';
import '../plugins/tracker/l10n/tracker_translations_zh.dart';
import '../plugins/tracker/l10n/tracker_translations_en.dart';
import '../plugins/tracker/l10n/tracker_translations_jp.dart';
import '../plugins/tts/l10n/tts_translations_zh.dart';
import '../plugins/tts/l10n/tts_translations_en.dart';
import '../plugins/tts/l10n/tts_translations_jp.dart';
import '../plugins/nfc/l10n/nfc_translations_zh.dart';
import '../plugins/nfc/l10n/nfc_translations_en.dart';
import '../plugins/nfc/l10n/nfc_translations_jp.dart';
import '../plugins/webview/l10n/webview_translations_zh.dart';
import '../plugins/webview/l10n/webview_translations_en.dart';
import '../plugins/webview/l10n/webview_translations_jp.dart';

// 屏幕层 (5个)
import '../screens/settings_screen/l10n/settings_screen_translations_zh.dart';
import '../screens/settings_screen/l10n/settings_screen_translations_en.dart';
import '../screens/settings_screen/l10n/settings_screen_translations_jp.dart';
import '../screens/settings_screen/widgets/l10n/webdav_translations_zh.dart';
import '../screens/settings_screen/widgets/l10n/webdav_translations_en.dart';
import '../screens/settings_screen/screens/data_management_translations_zh.dart';
import '../screens/settings_screen/screens/data_management_translations_en.dart';
import '../plugins/agent_chat/l10n/agent_chat_translations_zh.dart';
import '../plugins/agent_chat/l10n/agent_chat_translations_en.dart';
import '../plugins/agent_chat/l10n/agent_chat_translations_jp.dart';
import '../core/floating_ball/l10n/floating_ball_translations_zh.dart';
import '../core/floating_ball/l10n/floating_ball_translations_en.dart';
import '../core/floating_ball/l10n/floating_ball_translations_jp.dart';
import '../screens/l10n/screens_translations_zh.dart';
import '../screens/l10n/screens_translations_en.dart';
import '../screens/l10n/screens_translations_jp.dart';

// 组件层 (7个)
import '../widgets/l10n/widget_translations_zh.dart' as widget_zh;
import '../widgets/l10n/widget_translations_en.dart' as widget_en;
import '../widgets/l10n/widget_translations_jp.dart' as widget_jp;
import '../widgets/file_preview/l10n/file_preview_translations_zh.dart';
import '../widgets/file_preview/l10n/file_preview_translations_en.dart';
import '../widgets/l10n/image_picker_translations_zh.dart';
import '../widgets/l10n/image_picker_translations_en.dart';
import '../widgets/l10n/image_picker_translations_jp.dart';
import '../widgets/l10n/group_selector_translations_zh.dart';
import '../widgets/l10n/group_selector_translations_en.dart';
import '../widgets/l10n/group_selector_translations_jp.dart';
import '../widgets/l10n/location_picker_translations_zh.dart';
import '../widgets/l10n/location_picker_translations_en.dart';
import '../widgets/l10n/location_picker_translations_jp.dart';

/// 统一的 GetX 翻译聚合类
///
/// 整合了 Memento 应用的所有模块翻译:
/// - 1 个应用层 (app)
/// - 1 个核心层 (core)
/// - 21 个插件
/// - 6 个屏幕
/// - 7 个组件
///
/// 总计: 36 个模块, 2600+ 翻译键
class UnifiedTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys {
    final zhDict = <String, String>{};
    final enDict = <String, String>{};
    final jpDict = <String, String>{};

    // === 应用层 ===
    zhDict.addAll(appTranslationsZh);
    enDict.addAll(appTranslationsEn);
    jpDict.addAll(appTranslationsJp);

    // === 核心层 ===
    zhDict.addAll(coreTranslationsZh);
    enDict.addAll(coreTranslationsEn);
    jpDict.addAll(coreTranslationsJp);

    // === 插件层 (21个) ===
    zhDict.addAll(ActivityTranslationsZh.translations);
    enDict.addAll(ActivityTranslationsEn.translations);
    jpDict.addAll(ActivityTranslationsJp.translations);

    zhDict.addAll(BillTranslationsZh.translations);
    enDict.addAll(BillTranslationsEn.translations);
    jpDict.addAll(BillTranslationsJp.translations);

    zhDict.addAll(calendarTranslationsZh);
    enDict.addAll(calendarTranslationsEn);
    jpDict.addAll(calendarTranslationsJp);

    zhDict.addAll(CalendarAlbumTranslationsZh.translations);
    enDict.addAll(CalendarAlbumTranslationsEn.translations);
    jpDict.addAll(CalendarAlbumTranslationsJp.translations);

    zhDict.addAll(ChatTranslationsZh.keys);
    enDict.addAll(ChatTranslationsEn.keys);
    jpDict.addAll(ChatTranslationsJp.keys);

    zhDict.addAll(CheckinTranslationsZh.translations);
    enDict.addAll(CheckinTranslationsEn.translations);
    jpDict.addAll(CheckinTranslationsJp.translations);

    zhDict.addAll(contactTranslationsZh);
    enDict.addAll(contactTranslationsEn);
    jpDict.addAll(contactTranslationsJp);

    zhDict.addAll(DatabaseTranslationsZh.translations);
    enDict.addAll(DatabaseTranslationsEn.translations);
    jpDict.addAll(DatabaseTranslationsJp.translations);

    zhDict.addAll(dayTranslationsZh);
    enDict.addAll(dayTranslationsEn);
    jpDict.addAll(dayTranslationsJp);

    zhDict.addAll(DiaryTranslationsZh.translations);
    enDict.addAll(DiaryTranslationsEn.translations);
    jpDict.addAll(DiaryTranslationsJp.translations);

    zhDict.addAll(goodsTranslationsZh);
    enDict.addAll(goodsTranslationsEn);
    jpDict.addAll(goodsTranslationsJp);

    zhDict.addAll(HabitsTranslationsZh.translations);
    enDict.addAll(HabitsTranslationsEn.translations);
    jpDict.addAll(HabitsTranslationsJp.translations);

    zhDict.addAll(nodesTranslationsZh);
    enDict.addAll(nodesTranslationsEn);
    jpDict.addAll(nodesTranslationsJp);

    zhDict.addAll(notesTranslationsZh);
    enDict.addAll(notesTranslationsEn);
    jpDict.addAll(notesTranslationsJp);

    zhDict.addAll(openaiTranslationsZh);
    enDict.addAll(openaiTranslationsEn);
    jpDict.addAll(openaiTranslationsJp);

    zhDict.addAll(scriptsCenterTranslationsZh);
    enDict.addAll(scriptsCenterTranslationsEn);
    jpDict.addAll(scriptsCenterTranslationsJp);

    zhDict.addAll(storeTranslationsZh);
    enDict.addAll(storeTranslationsEn);
    jpDict.addAll(storeTranslationsJp);

    zhDict.addAll(TimerTranslationsZh.keys);
    enDict.addAll(TimerTranslationsEn.keys);
    jpDict.addAll(TimerTranslationsJp.keys);

    zhDict.addAll(todoTranslationsZh);
    enDict.addAll(todoTranslationsEn);
    jpDict.addAll(todoTranslationsJp);

    zhDict.addAll(TrackerTranslationsZh.keys);
    enDict.addAll(TrackerTranslationsEn.keys);
    jpDict.addAll(TrackerTranslationsJp.keys);

    zhDict.addAll(ttsTranslationsZh);
    enDict.addAll(ttsTranslationsEn);
    jpDict.addAll(ttsTranslationsJp);

    zhDict.addAll(webviewTranslationsZh);
    enDict.addAll(webviewTranslationsEn);
    jpDict.addAll(webviewTranslationsJp);

    // === 屏幕层 (6个) ===
    zhDict.addAll(settingsScreenTranslationsZh);
    enDict.addAll(settingsScreenTranslationsEn);
    jpDict.addAll(settingsScreenTranslationsJp);

    zhDict.addAll(webdavTranslationsZh);
    enDict.addAll(webdavTranslationsEn);

    zhDict.addAll(dataManagementTranslationsZh);
    enDict.addAll(dataManagementTranslationsEn);

    zhDict.addAll(agentChatTranslationsZh);
    enDict.addAll(agentChatTranslationsEn);
    jpDict.addAll(agentChatTranslationsJp);

    zhDict.addAll(floatingBallTranslationsZh);
    enDict.addAll(floatingBallTranslationsEn);
    jpDict.addAll(floatingBallTranslationsJp);

    zhDict.addAll(screensTranslationsZh);
    enDict.addAll(screensTranslationsEn);
    jpDict.addAll(screensTranslationsJp);

    // === 组件层 (7个) ===
    zhDict.addAll(widget_zh.zhCN);
    enDict.addAll(widget_en.enUS);
    jpDict.addAll(widget_jp.jpJP);

    zhDict.addAll(filePreviewTranslationsZh);
    enDict.addAll(filePreviewTranslationsEn);

    zhDict.addAll(imagePickerTranslationsZh);
    enDict.addAll(imagePickerTranslationsEn);
    jpDict.addAll(imagePickerTranslationsJp);

    zhDict.addAll(groupSelectorTranslationsZh);
    enDict.addAll(groupSelectorTranslationsEn);
    jpDict.addAll(groupSelectorTranslationsJp);

    zhDict.addAll(locationPickerTranslationsZh);
    enDict.addAll(locationPickerTranslationsEn);
    jpDict.addAll(locationPickerTranslationsJp);

    zhDict.addAll(nfcTranslationsZh);
    enDict.addAll(nfcTranslationsEn);
    jpDict.addAll(nfcTranslationsJp);

    return {'zh_CN': zhDict, 'en_US': enDict, 'ja_JP': jpDict};
  }
}
