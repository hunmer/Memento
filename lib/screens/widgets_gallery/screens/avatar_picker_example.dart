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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('头像选择器'),
      ),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('小尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: AvatarPicker(
                      username: '用户',
                      currentAvatarPath: selectedAvatar,
                      size: 50,
                      onAvatarChanged: (path) {
                        setState(() {
                          selectedAvatar = path;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 150,
                    height: 150,
                    child: AvatarPicker(
                      username: '用户',
                      currentAvatarPath: selectedAvatar,
                      size: 80,
                      onAvatarChanged: (path) {
                        setState(() {
                          selectedAvatar = path;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: AvatarPicker(
                      username: '用户',
                      currentAvatarPath: selectedAvatar,
                      size: 120,
                      onAvatarChanged: (path) {
                        setState(() {
                          selectedAvatar = path;
                        });
                      },
                    ),
                  ),
                ),
                if (selectedAvatar != null) ...[
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      '已选择: $selectedAvatar',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
      ),
    );
  }
}
