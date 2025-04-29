import 'dart:io';
import 'package:Memento/plugins/chat/chat_plugin.dart';
import 'package:Memento/plugins/chat/screens/profile_edit_dialog.dart';
import 'package:Memento/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
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

              }
            },
          ),
        ],
      ),
      body: Center(
        child: ListenableBuilder(
          listenable: ChatPlugin.instance,
          builder: (context, _) {
            // 获取最新的用户信息
            final currentUser = ChatPlugin.instance.userService.currentUser;
            return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (currentUser.iconPath != null)
              FutureBuilder<String>(
                future: ImageUtils.getAbsolutePath(currentUser.iconPath!),
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
                      currentUser.username[0].toUpperCase(),
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
                  currentUser.username[0].toUpperCase(),
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
