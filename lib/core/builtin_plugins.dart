import 'package:Memento/core/plugin_base.dart';
import 'package:Memento/plugins/activity/activity_plugin.dart';
import 'package:Memento/plugins/agent_chat/agent_chat_plugin.dart';
import 'package:Memento/plugins/bill/bill_plugin.dart';
import 'package:Memento/plugins/calendar/calendar_plugin.dart';
import 'package:Memento/plugins/calendar_album/calendar_album_plugin.dart';
import 'package:Memento/plugins/chat/chat_plugin.dart';
import 'package:Memento/plugins/checkin/checkin_plugin.dart';
import 'package:Memento/plugins/contact/contact_plugin.dart';
import 'package:Memento/plugins/database/database_plugin.dart';
import 'package:Memento/plugins/day/day_plugin.dart';
import 'package:Memento/plugins/diary/diary_plugin.dart';
import 'package:Memento/plugins/goods/goods_plugin.dart';
import 'package:Memento/plugins/habits/habits_plugin.dart';
import 'package:Memento/plugins/nfc/nfc_plugin.dart';
import 'package:Memento/plugins/nodes/nodes_plugin.dart';
import 'package:Memento/plugins/notes/notes_plugin.dart';
import 'package:Memento/plugins/openai/openai_plugin.dart';
import 'package:Memento/plugins/scripts_center/scripts_center_plugin.dart';
import 'package:Memento/plugins/store/store_plugin.dart';
import 'package:Memento/plugins/timer/timer_plugin.dart';
import 'package:Memento/plugins/todo/todo_plugin.dart';
import 'package:Memento/plugins/tracker/tracker_plugin.dart';
import 'package:Memento/plugins/tts/tts_plugin.dart';
import 'package:Memento/plugins/webview/webview_plugin.dart';

typedef PluginBuilder = PluginBase Function();

class BuiltinPlugins {
  static final List<PluginBuilder> _builders = [
    () => ChatPlugin(),
    () => OpenAIPlugin(),
    () => AgentChatPlugin(),
    () => DiaryPlugin(),
    () => ActivityPlugin(),
    () => CheckinPlugin(),
    () => ContactPlugin(),
    () => HabitsPlugin(),
    () => DatabasePlugin(),
    () => TimerPlugin(),
    () => TodoPlugin(),
    () => DayPlugin(),
    () => TrackerPlugin(),
    () => StorePlugin(),
    () => NodesPlugin(),
    () => NotesPlugin(),
    () => GoodsPlugin(),
    () => BillPlugin(),
    () => CalendarPlugin(),
    () => CalendarAlbumPlugin(),
    () => ScriptsCenterPlugin(),
    () => TTSPlugin(),
    () => NfcPlugin(),
    () => WebViewPlugin(),
  ];

  static List<PluginBase> createAll() {
    return _builders.map((builder) => builder()).toList();
  }
}
