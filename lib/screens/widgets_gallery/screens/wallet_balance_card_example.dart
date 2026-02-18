import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
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
                    width: 150,
                    height: 150,
                    child: WalletBalanceCardWidget(
                      avatarUrl:
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuCorzZ2lvIHyztIbYBlGGPG0PwT1syY9Soyd_SPcRYzDb4VyFCrhPfnZz1VK3o3xbOVdG7dXqRfK-_V2FTsL21c-XQ0RCtLVFDN5VCjpsNN1hyUD4vvliRNgvBARHVAwqsJTIx623UvD_KJwgHS_z_aFAcyP-VMDBzg48_9h6uHrojg7p-gD4689QcfoyKLuyXOt-oHxPOf1wz_jE5NkcQBvgtGCDK5LL5RGlbeFcS5sQ1KojUjoD4AqMbObiQFzKuESwGMtRm3ZQz2',
                      availableBalance: 8317.45,
                      totalBalance: 12682.50,
                      changePercent: 12,
                      income: 24000,
                      expenses: 1720,
                      size: const SmallSize(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: WalletBalanceCardWidget(
                      avatarUrl:
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuCorzZ2lvIHyztIbYBlGGPG0PwT1syY9Soyd_SPcRYzDb4VyFCrhPfnZz1VK3o3xbOVdG7dXqRfK-_V2FTsL21c-XQ0RCtLVFDN5VCjpsNN1hyUD4vvliRNgvBARHVAwqsJTIx623UvD_KJwgHS_z_aFAcyP-VMDBzg48_9h6uHrojg7p-gD4689QcfoyKLuyXOt-oHxPOf1wz_jE5NkcQBvgtGCDK5LL5RGlbeFcS5sQ1KojUjoD4AqMbObiQFzKuESwGMtRm3ZQz2',
                      availableBalance: 8317.45,
                      totalBalance: 12682.50,
                      changePercent: 12,
                      income: 24000,
                      expenses: 1720,
                      size: const MediumSize(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: WalletBalanceCardWidget(
                      avatarUrl:
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuCorzZ2lvIHyztIbYBlGGPG0PwT1syY9Soyd_SPcRYzDb4VyFCrhPfnZz1VK3o3xbOVdG7dXqRfK-_V2FTsL21c-XQ0RCtLVFDN5VCjpsNN1hyUD4vvliRNgvBARHVAwqsJTIx623UvD_KJwgHS_z_aFAcyP-VMDBzg48_9h6uHrojg7p-gD4689QcfoyKLuyXOt-oHxPOf1wz_jE5NkcQBvgtGCDK5LL5RGlbeFcS5sQ1KojUjoD4AqMbObiQFzKuESwGMtRm3ZQz2',
                      availableBalance: 8317.45,
                      totalBalance: 12682.50,
                      changePercent: 12,
                      income: 24000,
                      expenses: 1720,
                      size: const LargeSize(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 280,
                  child: WalletBalanceCardWidget(
                    avatarUrl:
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuCorzZ2lvIHyztIbYBlGGPG0PwT1syY9Soyd_SPcRYzDb4VyFCrhPfnZz1VK3o3xbOVdG7dXqRfK-_V2FTsL21c-XQ0RCtLVFDN5VCjpsNN1hyUD4vvliRNgvBARHVAwqsJTIx623UvD_KJwgHS_z_aFAcyP-VMDBzg48_9h6uHrojg7p-gD4689QcfoyKLuyXOt-oHxPOf1wz_jE5NkcQBvgtGCDK5LL5RGlbeFcS5sQ1KojUjoD4AqMbObiQFzKuESwGMtRm3ZQz2',
                    availableBalance: 8317.45,
                    totalBalance: 12682.50,
                    changePercent: 12,
                    income: 24000,
                    expenses: 1720,
                    size: const WideSize(),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 350,
                  child: WalletBalanceCardWidget(
                    avatarUrl:
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuCorzZ2lvIHyztIbYBlGGPG0PwT1syY9Soyd_SPcRYzDb4VyFCrhPfnZz1VK3o3xbOVdG7dXqRfK-_V2FTsL21c-XQ0RCtLVFDN5VCjpsNN1hyUD4vvliRNgvBARHVAwqsJTIx623UvD_KJwgHS_z_aFAcyP-VMDBzg48_9h6uHrojg7p-gD4689QcfoyKLuyXOt-oHxPOf1wz_jE5NkcQBvgtGCDK5LL5RGlbeFcS5sQ1KojUjoD4AqMbObiQFzKuESwGMtRm3ZQz2',
                    availableBalance: 8317.45,
                    totalBalance: 12682.50,
                    changePercent: 12,
                    income: 24000,
                    expenses: 1720,
                    size: const Wide2Size(),
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
