import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/profile_card_card.dart';

/// 个人资料卡片示例
class ProfileCardWidgetExample extends StatelessWidget {
  const ProfileCardWidgetExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('个人资料卡片')),
      body: Container(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
        child: const Center(
          child: ProfileCardWidget(
            imageUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuAQa5mwNY07R4lgli2Pgrxz3J9D6F6Plz6c9LGFNt4BYe9qp7wGfu6OnEFI-UAnneZ-qsWObIYUU_LVIN9_RypXCavX3hG7YUVTVgYgYhQiHXBBfy_W5EtO3oCjLBQ2eNlXRXxiKMEcC_tGq7UHLix8Zm7_Zawt0dvlp6ouuGhSkraBr9hjl6hKfAC5CL8rTgObw-xh-DnmtLVs5Msvp8N6dZgasjTEMmwR8or2JI6MCsXD0i43ZVNUATo21RHx95nyAFAf5zJuuDyg',
            name: 'Sophie Bennett',
            isVerified: true,
            bio: 'Product Designer who focuses on simplicity & usability.',
            followersCount: 312,
            followingCount: 48,
          ),
        ),
      ),
    );
  }
}
