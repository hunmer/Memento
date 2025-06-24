import 'chat_localizations.dart';

/// 中文本地化实现
class ChatLocalizationsZh extends ChatLocalizations {
  ChatLocalizationsZh() : super('zh');

  @override
  String get pluginName => '频道聊天';

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
  String get channelsTab => '频道';

  @override
  String get timelineTab => '时间线';

  @override
  String get timelineComingSoon => '时间线功能 - 即将推出';

  @override
  String get editProfile => '编辑个人资料';

  @override
  String get today => '今天';

  @override
  String get yesterday => '昨天';

  // Advanced filter related implementations
  @override
  String get advancedFilter => '高级筛选';

  @override
  String get searchIn => '搜索范围：';

  @override
  String get channelNames => '频道名称';

  @override
  String get usernames => '用户名';

  @override
  String get messageContent => '消息内容';

  @override
  String get dateRange => '日期范围：';

  @override
  String get startDate => '开始日期';

  @override
  String get endDate => '结束日期';

  @override
  String get clearDates => '清除日期';

  @override
  String get selectChannels => '选择频道：';

  @override
  String get selectUsers => '选择用户：';

  @override
  String get noChannelsAvailable => '没有可用的频道';

  @override
  String get noUsersAvailable => '没有可用的用户';

  @override
  String get cancel => '取消';

  @override
  String get reset => '重置';

  @override
  String get apply => '应用';

  @override
  String get setBackground => '设置背景';

  // UI服务新增的本地化键值
  @override
  String get channelCount => '频道数量';

  @override
  String get totalMessages => '总消息数量';

  @override
  String get todayMessages => '今日新增消息';

  @override
  String get profileTitle => '个人资料';

  @override
  String get chatSettings => '聊天设置';

  @override
  String get showAvatarInChat => '在聊天中显示头像';

  @override
  String get playSoundOnSend => '发送消息播放提示音';

  @override
  String get showAvatarInTimeline => '在时间线中显示头像';

  // 消息输入动作
  @override
  String get advancedEditor => '高级编辑';

  @override
  String get photo => '图片';

  @override
  String get takePhoto => '拍照';

  @override
  String get recordVideo => '录像';

  @override
  String get video => '视频';

  @override
  String get pluginAnalysis => '插件分析';

  @override
  String get file => '文件';

  @override
  String get audioRecording => '录音';

  @override
  String get smartAgent => '智能体';
}
