import 'chat_localizations.dart';

/// 中文本地化实现
class ChatLocalizationsZh extends ChatLocalizations {
  ChatLocalizationsZh() : super('zh');

  @override
  String get chatPluginName => '聊天';

  @override
  String get chatPluginDescription => '基础聊天功能插件';

  @override
  String get showAvatarInChannelList => '在聊天列表显示头像';

  @override
  String get channelList => '频道列表';

  @override
  String get newChannel => '新建频道';

  @override
  String get deleteChannel => '删除频道';

  @override
  String get deleteMessages => '删除消息';

  @override
  String get draft => '草稿';

  @override
  String get chatRoom => '聊天室';

  @override
  String get enterMessage => '输入消息...';

  @override
  String get justNow => '刚刚';

  @override
  String minutesAgo(int minutes) => '$minutes分钟前';

  @override
  String hoursAgo(int hours) => '$hours小时前';

  @override
  String daysAgo(int days) => '$days天前';

  @override
  String userInitial(String username) => '$username的首字母';

  @override
  String get edit => '编辑';

  @override
  String get copy => '复制';

  @override
  String get delete => '删除';

  @override
  String get pin => '置顶';

  @override
  String get clear => '清空';

  @override
  String get info => '信息';

  @override
  String get multiSelectMode => '多选模式';

  @override
  String get clearMessages => '清空消息';

  @override
  String get channelInfo => '频道信息';

  @override
  String get selectedMessages => '已选择 {count} 条消息';

  @override
  String get edited => '已编辑';

  @override
  String get today => '今天';

  @override
  String get yesterday => '昨天';
}