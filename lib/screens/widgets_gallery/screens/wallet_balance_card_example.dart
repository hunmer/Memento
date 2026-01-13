import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/wallet_balance_card.dart';

/// 钱包余额概览卡片示例
class WalletBalanceCardExample extends StatelessWidget {
  const WalletBalanceCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('钱包余额概览卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: WalletBalanceCardWidget(
            avatarUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuCorzZ2lvIHyztIbYBlGGPG0PwT1syY9Soyd_SPcRYzDb4VyFCrhPfnZz1VK3o3xbOVdG7dXqRfK-_V2FTsL21c-XQ0RCtLVFDN5VCjpsNN1hyUD4vvliRNgvBARHVAwqsJTIx623UvD_KJwgHS_z_aFAcyP-VMDBzg48_9h6uHrojg7p-gD4689QcfoyKLuyXOt-oHxPOf1wz_jE5NkcQBvgtGCDK5LL5RGlbeFcS5sQ1KojUjoD4AqMbObiQFzKuESwGMtRm3ZQz2',
            availableBalance: 8317.45,
            totalBalance: 12682.50,
            changePercent: 12,
            income: 24000,
            expenses: 1720,
          ),
        ),
      ),
    );
  }
}
