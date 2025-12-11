import 'package:get/get.dart';

// 应用层
import 'app_translations_zh.dart';
import 'app_translations_en.dart';

// 核心层
import '../core/l10n/core_translations_zh.dart';
import '../core/l10n/core_translations_en.dart';

// 插件层 (21个)
import '../plugins/activity/l10n/activity_translations_zh.dart';
import '../plugins/activity/l10n/activity_translations_en.dart';
import '../plugins/bill/l10n/bill_translations_zh.dart';
import '../plugins/bill/l10n/bill_translations_en.dart';
import '../plugins/calendar/l10n/calendar_translations_zh.dart';
import '../plugins/calendar/l10n/calendar_translations_en.dart';
import '../plugins/calendar_album/l10n/calendar_album_translations_zh.dart';
import '../plugins/calendar_album/l10n/calendar_album_translations_en.dart';
import '../plugins/chat/l10n/chat_translations_zh.dart';
import '../plugins/chat/l10n/chat_translations_en.dart';
import '../plugins/checkin/l10n/checkin_translations_zh.dart';
import '../plugins/checkin/l10n/checkin_translations_en.dart';
import '../plugins/contact/l10n/contact_translations_zh.dart';
import '../plugins/contact/l10n/contact_translations_en.dart';
import '../plugins/database/l10n/database_translations_zh.dart';
import '../plugins/database/l10n/database_translations_en.dart';
import '../plugins/day/l10n/day_translations_zh.dart';
import '../plugins/day/l10n/day_translations_en.dart';
import '../plugins/diary/l10n/diary_translations_zh.dart';
import '../plugins/diary/l10n/diary_translations_en.dart';
import '../plugins/goods/l10n/goods_translations_zh.dart';
import '../plugins/goods/l10n/goods_translations_en.dart';
import '../plugins/habits/l10n/habits_translations_zh.dart';
import '../plugins/habits/l10n/habits_translations_en.dart';
import '../plugins/nodes/l10n/nodes_translations_zh.dart';
import '../plugins/nodes/l10n/nodes_translations_en.dart';
import '../plugins/notes/l10n/notes_translations_zh.dart';
import '../plugins/notes/l10n/notes_translations_en.dart';
import '../plugins/openai/l10n/openai_translations_zh.dart';
import '../plugins/openai/l10n/openai_translations_en.dart';
import '../plugins/scripts_center/l10n/scripts_center_translations_zh.dart';
import '../plugins/scripts_center/l10n/scripts_center_translations_en.dart';
import '../plugins/store/l10n/store_translations_zh.dart';
import '../plugins/store/l10n/store_translations_en.dart';
import '../plugins/timer/l10n/timer_translations_zh.dart';
import '../plugins/timer/l10n/timer_translations_en.dart';
import '../plugins/todo/l10n/todo_translations_zh.dart';
import '../plugins/todo/l10n/todo_translations_en.dart';
import '../plugins/tracker/l10n/tracker_translations_zh.dart';
import '../plugins/tracker/l10n/tracker_translations_en.dart';
import '../plugins/tts/l10n/tts_translations_zh.dart';
import '../plugins/tts/l10n/tts_translations_en.dart';
import '../plugins/nfc/l10n/nfc_translations_zh.dart';
import '../plugins/nfc/l10n/nfc_translations_en.dart';
import '../plugins/webview/l10n/webview_translations_zh.dart';
import '../plugins/webview/l10n/webview_translations_en.dart';

// 屏幕层 (5个)
import '../screens/settings_screen/l10n/settings_screen_translations_zh.dart';
import '../screens/settings_screen/l10n/settings_screen_translations_en.dart';
import '../screens/settings_screen/widgets/l10n/webdav_translations_zh.dart';
import '../screens/settings_screen/widgets/l10n/webdav_translations_en.dart';
import '../screens/settings_screen/screens/data_management_translations_zh.dart';
import '../screens/settings_screen/screens/data_management_translations_en.dart';
import '../plugins/agent_chat/l10n/agent_chat_translations_zh.dart';
import '../plugins/agent_chat/l10n/agent_chat_translations_en.dart';
import '../core/floating_ball/l10n/floating_ball_translations_zh.dart';
import '../core/floating_ball/l10n/floating_ball_translations_en.dart';
import '../screens/l10n/screens_translations_zh.dart';
import '../screens/l10n/screens_translations_en.dart';

// 组件层 (7个)
import '../widgets/l10n/widget_translations_zh.dart' as widget_zh;
import '../widgets/l10n/widget_translations_en.dart' as widget_en;
import '../widgets/file_preview/l10n/file_preview_translations_zh.dart';
import '../widgets/file_preview/l10n/file_preview_translations_en.dart';
import '../widgets/l10n/image_picker_translations_zh.dart';
import '../widgets/l10n/image_picker_translations_en.dart';
import '../widgets/l10n/group_selector_translations_zh.dart';
import '../widgets/l10n/group_selector_translations_en.dart';
import '../widgets/l10n/location_picker_translations_zh.dart';
import '../widgets/l10n/location_picker_translations_en.dart';

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

    // === 应用层 ===
    zhDict.addAll(appTranslationsZh);
    enDict.addAll(appTranslationsEn);

    // === 核心层 ===
    zhDict.addAll(coreTranslationsZh);
    enDict.addAll(coreTranslationsEn);

    // === 插件层 (21个) ===
    zhDict.addAll(ActivityTranslationsZh.translations);
    enDict.addAll(ActivityTranslationsEn.translations);

    zhDict.addAll(BillTranslationsZh.translations);
    enDict.addAll(BillTranslationsEn.translations);

    zhDict.addAll(calendarTranslationsZh);
    enDict.addAll(calendarTranslationsEn);

    zhDict.addAll(CalendarAlbumTranslationsZh.translations);
    enDict.addAll(CalendarAlbumTranslationsEn.translations);

    zhDict.addAll(ChatTranslationsZh.keys);
    enDict.addAll(ChatTranslationsEn.keys);

    zhDict.addAll(CheckinTranslationsZh.translations);
    enDict.addAll(CheckinTranslationsEn.translations);

    zhDict.addAll(contactTranslationsZh);
    enDict.addAll(contactTranslationsEn);

    zhDict.addAll(DatabaseTranslationsZh.translations);
    enDict.addAll(DatabaseTranslationsEn.translations);

    zhDict.addAll(dayTranslationsZh);
    enDict.addAll(dayTranslationsEn);

    zhDict.addAll(DiaryTranslationsZh.translations);
    enDict.addAll(DiaryTranslationsEn.translations);

    zhDict.addAll(goodsTranslationsZh);
    enDict.addAll(goodsTranslationsEn);

    zhDict.addAll(HabitsTranslationsZh.translations);
    enDict.addAll(HabitsTranslationsEn.translations);

    zhDict.addAll(nodesTranslationsZh);
    enDict.addAll(nodesTranslationsEn);

    zhDict.addAll(notesTranslationsZh);
    enDict.addAll(notesTranslationsEn);

    zhDict.addAll(openaiTranslationsZh);
    enDict.addAll(openaiTranslationsEn);

    zhDict.addAll(scriptsCenterTranslationsZh);
    enDict.addAll(scriptsCenterTranslationsEn);

    zhDict.addAll(storeTranslationsZh);
    enDict.addAll(storeTranslationsEn);

    zhDict.addAll(TimerTranslationsZh.keys);
    enDict.addAll(TimerTranslationsEn.keys);

    zhDict.addAll(todoTranslationsZh);
    enDict.addAll(todoTranslationsEn);

    zhDict.addAll(TrackerTranslationsZh.keys);
    enDict.addAll(TrackerTranslationsEn.keys);

    zhDict.addAll(ttsTranslationsZh);
    enDict.addAll(ttsTranslationsEn);

    zhDict.addAll(webviewTranslationsZh);
    enDict.addAll(webviewTranslationsEn);

    // === 屏幕层 (6个) ===
    zhDict.addAll(settingsScreenTranslationsZh);
    enDict.addAll(settingsScreenTranslationsEn);

    zhDict.addAll(webdavTranslationsZh);
    enDict.addAll(webdavTranslationsEn);

    zhDict.addAll(dataManagementTranslationsZh);
    enDict.addAll(dataManagementTranslationsEn);

    zhDict.addAll(agentChatTranslationsZh);
    enDict.addAll(agentChatTranslationsEn);

    zhDict.addAll(floatingBallTranslationsZh);
    enDict.addAll(floatingBallTranslationsEn);

    zhDict.addAll(screensTranslationsZh);
    enDict.addAll(screensTranslationsEn);

    // === 组件层 (7个) ===
    zhDict.addAll(widget_zh.zhCN);
    enDict.addAll(widget_en.enUS);

    zhDict.addAll(filePreviewTranslationsZh);
    enDict.addAll(filePreviewTranslationsEn);

    zhDict.addAll(imagePickerTranslationsZh);
    enDict.addAll(imagePickerTranslationsEn);

    zhDict.addAll(groupSelectorTranslationsZh);
    enDict.addAll(groupSelectorTranslationsEn);

    zhDict.addAll(locationPickerTranslationsZh);
    enDict.addAll(locationPickerTranslationsEn);

    zhDict.addAll(nfcTranslationsZh);
    enDict.addAll(nfcTranslationsEn);

    return {'zh_CN': zhDict, 'en_US': enDict};
  }
}
