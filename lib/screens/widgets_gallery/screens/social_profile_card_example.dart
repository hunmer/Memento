import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
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
                    width: 280,
                    height: 180,
                    child: ProfileCardWidget(
                      size: const SmallSize(),
                      imageUrl:
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuAQa5mwNY07R4lgli2Pgrxz3J9D6F6Plz6c9LGFNt4BYe9qp7wGfu6OnEFI-UAnneZ-qsWObIYUU_LVIN9_RypXCavX3hG7YUVTVgYgYhQiHXBBfy_W5EtO3oCjLBQ2eNlXRXxiKMEcC_tGq7UHLix8Zm7_Zawt0dvlp6ouuGhSkraBr9hjl6hKfAC5CL8rTgObw-xh-DnmtLVs5Msvp8N6dZgasjTEMmwR8or2JI6MCsXD0i43ZVNUATo21RHx95nyAFAf5zJuuDyg',
                      name: 'Sophie',
                      isVerified: true,
                      bio: 'Product Designer.',
                      followersCount: 312,
                      followingCount: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 320,
                    height: 220,
                    child: ProfileCardWidget(
                      size: const MediumSize(),
                      imageUrl:
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuAQa5mwNY07R4lgli2Pgrxz3J9D6F6Plz6c9LGFNt4BYe9qp7wGfu6OnEFI-UAnneZ-qsWObIYUU_LVIN9_RypXCavX3hG7YUVTVgYgYhQiHXBBfy_W5EtO3oCjLBQ2eNlXRXxiKMEcC_tGq7UHLix8Zm7_Zawt0dvlp6ouuGhSkraBr9hjl6hKfAC5CL8rTgObw-xh-DnmtLVs5Msvp8N6dZgasjTEMmwR8or2JI6MCsXD0i43ZVNUATo21RHx95nyAFAf5zJuuDyg',
                      name: 'Sophie Bennett',
                      isVerified: true,
                      bio: 'Product Designer focused on simplicity.',
                      followersCount: 312,
                      followingCount: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 380,
                    height: 280,
                    child: ProfileCardWidget(
                      size: const LargeSize(),
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
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 280,
                  child: ProfileCardWidget(
                    size: const WideSize(),
                    imageUrl:
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuAQa5mwNY07R4lgli2Pgrxz3J9D6F6Plz6c9LGFNt4BYe9qp7wGfu6OnEFI-UAnneZ-qsWObIYUU_LVIN9_RypXCavX3hG7YUVTVgYgYhQiHXBBfy_W5EtO3oCjLBQ2eNlXRXxiKMEcC_tGq7UHLix8Zm7_Zawt0dvlp6ouuGhSkraBr9hjl6hKfAC5CL8rTgObw-xh-DnmtLVs5Msvp8N6dZgasjTEMmwR8or2JI6MCsXD0i43ZVNUATo21RHx95nyAFAf5zJuuDyg',
                    name: 'Sophie Bennett - Product Designer',
                    isVerified: true,
                    bio: 'Product Designer who focuses on simplicity & usability. Creating beautiful user experiences.',
                    followersCount: 312,
                    followingCount: 48,
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 350,
                  child: ProfileCardWidget(
                    size: const Wide2Size(),
                    imageUrl:
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuAQa5mwNY07R4lgli2Pgrxz3J9D6F6Plz6c9LGFNt4BYe9qp7wGfu6OnEFI-UAnneZ-qsWObIYUU_LVIN9_RypXCavX3hG7YUVTVgYgYhQiHXBBfy_W5EtO3oCjLBQ2eNlXRXxiKMEcC_tGq7UHLix8Zm7_Zawt0dvlp6ouuGhSkraBr9hjl6hKfAC5CL8rTgObw-xh-DnmtLVs5Msvp8N6dZgasjTEMmwR8or2JI6MCsXD0i43ZVNUATo21RHx95nyAFAf5zJuuDyg',
                    name: 'Sophie Bennett - Senior Product Designer',
                    isVerified: true,
                    bio: 'Product Designer who focuses on simplicity & usability. Creating beautiful user experiences that delight users worldwide.',
                    followersCount: 312,
                    followingCount: 48,
                  ),
                ),
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
