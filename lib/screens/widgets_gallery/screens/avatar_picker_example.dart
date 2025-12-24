import 'package:flutter/material.dart';
import 'package:Memento/widgets/picker/avatar_picker.dart';

/// 头像选择器示例
class AvatarPickerExample extends StatefulWidget {
  const AvatarPickerExample({super.key});

  @override
  State<AvatarPickerExample> createState() => _AvatarPickerExampleState();
}

class _AvatarPickerExampleState extends State<AvatarPickerExample> {
  String? selectedAvatar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('头像选择器'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AvatarPicker',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text('这是一个头像选择器组件，支持预设头像和自定义图片。'),
            const SizedBox(height: 32),
            Center(
              child: AvatarPicker(
                username: '用户',
                currentAvatarPath: selectedAvatar,
                size: 100,
                onAvatarChanged: (path) {
                  setState(() {
                    selectedAvatar = path;
                  });
                },
              ),
            ),
            const SizedBox(height: 32),
            if (selectedAvatar != null)
              Center(
                child: Text(
                  '已选择: $selectedAvatar',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
