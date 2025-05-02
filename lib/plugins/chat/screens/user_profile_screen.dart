import 'dart:io';
import 'package:Memento/plugins/chat/chat_plugin.dart';
import 'package:Memento/plugins/chat/screens/profile_edit_dialog.dart';
import 'package:Memento/utils/image_utils.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';

class UserProfileScreen extends StatefulWidget {
  final User user;

  const UserProfileScreen({super.key, required this.user});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user.username),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await showDialog<bool>(
                context: context,
                builder:
                    (context) => ProfileEditDialog(
                      user: widget.user,
                      chatPlugin: ChatPlugin.instance,
                    ),
              );
              if (result == true && mounted) {
                // 强制更新UI
                setState(() {});
                // 通知插件监听器更新
                ChatPlugin.instance.notifyListeners();
              }
            },
          ),
        ],
      ),
      body: Center(
        child: ListenableBuilder(
          listenable: ChatPlugin.instance,
          builder: (context, _) {
            // 使用传递过来的用户信息
            final user = widget.user;
            return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (user.iconPath != null)
              FutureBuilder<String>(
                future: ImageUtils.getAbsolutePath(user.iconPath!),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return CircleAvatar(
                      backgroundImage: FileImage(File(snapshot.data!)),
                      radius: 60,
                    );
                  }
                  // 显示默认头像
                  return CircleAvatar(
                    radius: 60,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      user.username[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 48,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  );
                },
              )
            else
              CircleAvatar(
                radius: 60,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  user.username[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 48,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              widget.user.username,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text(
              'ID: ${widget.user.id}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        );
        }
      ),
    )
    );
  }
}
