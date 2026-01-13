import 'package:flutter/material.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/social_profile_card.dart';

/// 社交资料卡片示例
class SocialProfileCardExample extends StatelessWidget {
  const SocialProfileCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('社交资料卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFF6B7280),
        child: const Center(
          child: SocialProfileCardWidget(
            avatarUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuDQBpvx8sVdqYMemqByF96wLVYDtKW2gysxp-DEVKMyV3MGBTO-SsYubZDkdx5YssNyEMNJt6kvNtVYwQcVPx5B_mWC8_-MjNgJneO5473aTTjd1qXZfgDNP6VeWyC_C84X-Bp7lNiLH1tILc1wpNs41UWjaBbQDyDvaPqVEPVQelJXoG5ULoGdueUtFJNSli1Ld1TpetG4-BdTLbjtKH0Zfusp7suNwuqNbbeI2QIExxTTHzhIq474K8TdUTKrDO3Pe01o91TWNw',
            name: 'Sammy Lawson',
            handle: '@CoRay',
            followers: 3600,
            posts: 248,
            tag: '#technology',
            content: "It's incredible to see art, creativity and technology come together celebration",
            comments: 3600,
            shares: 12000,
          ),
        ),
      ),
    );
  }
}
