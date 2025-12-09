import 'package:Memento/core/event/event_manager.dart';
import 'package:get/get.dart';
import 'package:Memento/plugins/chat/models/user.dart';

/// 用户相关事件的常量定义
class UserEventNames {
  /// 用户头像更新事件
  static const String userAvatarUpdated = 'user_avatar_updated';
}

/// 用户头像更新事件参数
class UserAvatarUpdatedEventArgs extends EventArgs {
  /// 被更新的用户
  final User user;

  UserAvatarUpdatedEventArgs(this.user) 
      : super(UserEventNames.userAvatarUpdated);
}