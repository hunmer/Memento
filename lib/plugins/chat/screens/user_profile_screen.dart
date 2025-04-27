import 'dart:io';
import 'package:Memento/plugins/chat/chat_plugin.dart';
import 'package:Memento/plugins/chat/screens/profile_edit_dialog.dart';
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
  Future<String> _getAbsolutePath(String relativePath) async {
    // 如果已经是绝对路径，直接返回
    if (path.isAbsolute(relativePath)) {
      return relativePath;
    }

    final appDir = await getApplicationDocumentsDirectory();

    // 规范化路径，确保使用正确的路径分隔符
    String normalizedPath = relativePath.replaceFirst('./', '');
    normalizedPath = normalizedPath.replaceAll('/', path.separator);
    // 检查是否需要添加app_data前缀
    if (!normalizedPath.startsWith('app_data${path.separator}')) {
      return path.join(appDir.path, 'app_data', normalizedPath);
    }
    return path.join(appDir.path, normalizedPath);
  }

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
                setState(() {
                  // 刷新界面以显示更新后的用户信息
                });
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.user.iconPath != null)
              FutureBuilder<String>(
                future: _getAbsolutePath(widget.user.iconPath!),
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
                      widget.user.username[0].toUpperCase(),
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
                  widget.user.username[0].toUpperCase(),
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
        ),
      ),
    );
  }
}
