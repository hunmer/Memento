import 'dart:io';
import 'package:Memento/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/event/event_manager.dart';
import 'package:Memento/plugins/chat/events/user_events.dart';
import 'package:Memento/plugins/chat/models/user.dart';

class MessageAvatar extends StatefulWidget {
  final User user;
  final VoidCallback? onTap;

  const MessageAvatar({super.key, required this.user, this.onTap});

  @override
  State<MessageAvatar> createState() => _MessageAvatarState();
}

class _MessageAvatarState extends State<MessageAvatar> {
  late User _currentUser;

  User get user => _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    // 订阅用户头像更新事件
    EventManager.instance.subscribe(
      UserEventNames.userAvatarUpdated,
      _handleAvatarUpdate,
    );
  }

  @override
  void didUpdateWidget(MessageAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user != widget.user) {
      _currentUser = widget.user;
    }
  }

  @override
  void dispose() {
    // 取消订阅
    EventManager.instance.unsubscribe(UserEventNames.userAvatarUpdated);
    super.dispose();
  }

  void _handleAvatarUpdate(EventArgs args) {
    if (args is UserAvatarUpdatedEventArgs) {
      // 只有当更新的是当前显示的用户时才刷新
      if (args.user.id == user.id) {
        setState(() {
          _currentUser = args.user; // 更新用户信息，包括新的头像地址
        });
      }
    }
  }

  Widget _buildDefaultAvatar(BuildContext context) {
    return Center(
      child: Text(
        user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
          child:
              user.iconPath != null && user.iconPath != ''
                  ? FutureBuilder<String>(
                    future: ImageUtils.getAbsolutePath(user.iconPath!),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        return ClipOval(
                          child: Image.file(
                            File(snapshot.data!),
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        );
                      }
                      return _buildDefaultAvatar(context);
                    },
                  )
                  : _buildDefaultAvatar(context),
        ),
      ),
    );
  }
}
