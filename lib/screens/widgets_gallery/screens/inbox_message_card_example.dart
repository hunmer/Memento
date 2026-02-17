import 'package:flutter/material.dart';
import 'package:Memento/widgets/common/inbox_message_card.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 收件箱消息卡片示例
class InboxMessageCardExample extends StatelessWidget {
  const InboxMessageCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('收件箱消息卡片')),
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
                    height: 180,
                    child: InboxMessageCardWidget(
                      size: const SmallSize(),
                      messages: const [
                        InboxMessage(
                          name: 'Salomé Fernán',
                          avatarUrl:
                              'https://lh3.googleusercontent.com/aida-public/AB6AXuDsw9ChELA7dqeHbfejN8dkMjALY2S1ThiqSCNRUZsLq4olaN6-hNy-3ayi6K4P-58F7il7GtpFP2a3NEtddjYC7RXwUaNcT7jUPvhNHsDw1ZSS5CLG0Y_jbU1MDknvD0PC2os31vl-BPPd7lZ7hM-4u9UevWJ_Lpr0wO8cADU05p-7yFxldQTHxI1hifja00V10wki7zPPzoPZb2fThBrLaolBcsxXWmLLTKKBUPQLTJthX6NfSiWRhyaV4of4OxEmltvGsuBzzw',
                          preview: 'How to write advertising...',
                          timeAgo: '7 mins ago',
                        ),
                      ],
                      totalCount: 16,
                      remainingCount: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 250,
                    child: InboxMessageCardWidget(
                      size: const MediumSize(),
                      messages: const [
                        InboxMessage(
                          name: 'Salomé Fernán',
                          avatarUrl:
                              'https://lh3.googleusercontent.com/aida-public/AB6AXuDsw9ChELA7dqeHbfejN8dkMjALY2S1ThiqSCNRUZsLq4olaN6-hNy-3ayi6K4P-58F7il7GtpFP2a3NEtddjYC7RXwUaNcT7jUPvhNHsDw1ZSS5CLG0Y_jbU1MDknvD0PC2os31vl-BPPd7lZ7hM-4u9UevWJ_Lpr0wO8cADU05p-7yFxldQTHxI1hifja00V10wki7zPPzoPZb2fThBrLaolBcsxXWmLLTKKBUPQLTJthX6NfSiWRhyaV4of4OxEmltvGsuBzzw',
                          preview: 'How to write advertising article',
                          timeAgo: '7 mins ago',
                        ),
                        InboxMessage(
                          name: 'Thanawan Chadee',
                          avatarUrl:
                              'https://lh3.googleusercontent.com/aida-public/AB6AXuDgq5z45_Cg4VhucQoqYGbnnnWGIFykRGb6DPyERRy5bNlYDz_rkyrjtirFhKkgHDXdVXQaMWObeqlm_XioaOJKwDh7mdOXp9UXuLU2bJYke-zLsBqaM5S0kAN8odZ1ojbRq3qRGx5ymmmcflxhwH-6CzL7O8JFfFw1AGYAXNJvHBS9Yvx8P7E758IfBlwIhfp4SpPNUr2iX6ZGBduJ7rmMxEfcn66g6eb3ws4ku0O-otr6Q8jaG2VqeXLSXIpDJPzn90Ycyci8mQ',
                          preview: 'Addiction when gambling...',
                          timeAgo: '10 mins ago',
                        ),
                      ],
                      totalCount: 16,
                      remainingCount: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 350,
                    height: 350,
                    child: InboxMessageCardWidget(
                      size: const LargeSize(),
                      messages: const [
                        InboxMessage(
                          name: 'Salomé Fernán',
                          avatarUrl:
                              'https://lh3.googleusercontent.com/aida-public/AB6AXuDsw9ChELA7dqeHbfejN8dkMjALY2S1ThiqSCNRUZsLq4olaN6-hNy-3ayi6K4P-58F7il7GtpFP2a3NEtddjYC7RXwUaNcT7jUPvhNHsDw1ZSS5CLG0Y_jbU1MDknvD0PC2os31vl-BPPd7lZ7hM-4u9UevWJ_Lpr0wO8cADU05p-7yFxldQTHxI1hifja00V10wki7zPPzoPZb2fThBrLaolBcsxXWmLLTKKBUPQLTJthX6NfSiWRhyaV4of4OxEmltvGsuBzzw',
                          preview: 'How to write advertising article',
                          timeAgo: '7 mins ago',
                        ),
                        InboxMessage(
                          name: 'Thanawan Chadee',
                          avatarUrl:
                              'https://lh3.googleusercontent.com/aida-public/AB6AXuDgq5z45_Cg4VhucQoqYGbnnnWGIFykRGb6DPyERRy5bNlYDz_rkyrjtirFhKkgHDXdVXQaMWObeqlm_XioaOJKwDh7mdOXp9UXuLU2bJYke-zLsBqaM5S0kAN8odZ1ojbRq3qRGx5ymmmcflxhwH-6CzL7O8JFfFw1AGYAXNJvHBS9Yvx8P7E758IfBlwIhfp4SpPNUr2iX6ZGBduJ7rmMxEfcn66g6eb3ws4ku0O-otr6Q8jaG2VqeXLSXIpDJPzn90Ycyci8mQ',
                          preview: 'Addiction when gambling becomes',
                          timeAgo: '10 mins ago',
                        ),
                        InboxMessage(
                          name: 'Diego Morata',
                          avatarUrl:
                              'https://lh3.googleusercontent.com/aida-public/AB6AXuDaBru40HzWPZQazW01u0WkfKyUUs35h33Pfyxxy1gqOIG_TfQoNxMGogpJMtDkiJCPKXB7AehTpjit7GxToJ0bJgL-kWSh9ARe8FYsfWW1jK0sKa3echRSU4koNMhJ_1RXHPkcH8JFbcllw0vF7dOKy_ROFaARuZmy4kOt3Xf-buwnLo6l6nrXhC3ULp1za05sU8rA58bpaFKhX2TqOu5bf16SUZ_ESL0pdGBgPVtpXWAv6RP5-i5sMS6EOlnLBHimsEY79g5hiQ',
                          preview: 'Baby monitor technology',
                          timeAgo: '20 mins ago',
                        ),
                      ],
                      totalCount: 16,
                      remainingCount: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 280,
                  child: InboxMessageCardWidget(
                    size: const WideSize(),
                    messages: const [
                      InboxMessage(
                        name: 'Salomé Fernán',
                        avatarUrl:
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuDsw9ChELA7dqeHbfejN8dkMjALY2S1ThiqSCNRUZsLq4olaN6-hNy-3ayi6K4P-58F7il7GtpFP2a3NEtddjYC7RXwUaNcT7jUPvhNHsDw1ZSS5CLG0Y_jbU1MDknvD0PC2os31vl-BPPd7lZ7hM-4u9UevWJ_Lpr0wO8cADU05p-7yFxldQTHxI1hifja00V10wki7zPPzoPZb2fThBrLaolBcsxXWmLLTKKBUPQLTJthX6NfSiWRhyaV4of4OxEmltvGsuBzzw',
                        preview:
                            'How to write advertising article for your business',
                        timeAgo: '7 mins ago',
                      ),
                      InboxMessage(
                        name: 'Thanawan Chadee',
                        avatarUrl:
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuDgq5z45_Cg4VhucQoqYGbnnnWGIFykRGb6DPyERRy5bNlYDz_rkyrjtirFhKkgHDXdVXQaMWObeqlm_XioaOJKwDh7mdOXp9UXuLU2bJYke-zLsBqaM5S0kAN8odZ1ojbRq3qRGx5ymmmcflxhwH-6CzL7O8JFfFw1AGYAXNJvHBS9Yvx8P7E758IfBlwIhfp4SpPNUr2iX6ZGBduJ7rmMxEfcn66g6eb3ws4ku0O-otr6Q8jaG2VqeXLSXIpDJPzn90Ycyci8mQ',
                        preview: 'Addiction when gambling becomes a problem',
                        timeAgo: '10 mins ago',
                      ),
                      InboxMessage(
                        name: 'Diego Morata',
                        avatarUrl:
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuDaBru40HzWPZQazW01u0WkfKyUUs35h33Pfyxxy1gqOIG_TfQoNxMGogpJMtDkiJCPKXB7AehTpjit7GxToJ0bJgL-kWSh9ARe8FYsfWW1jK0sKa3echRSU4koNMhJ_1RXHPkcH8JFbcllw0vF7dOKy_ROFaARuZmy4kOt3Xf-buwnLo6l6nrXhC3ULp1za05sU8rA58bpaFKhX2TqOu5bf16SUZ_ESL0pdGBgPVtpXWAv6RP5-i5sMS6EOlnLBHimsEY79g5hiQ',
                        preview: 'Baby monitor technology and safety features',
                        timeAgo: '20 mins ago',
                      ),
                    ],
                    totalCount: 16,
                    remainingCount: 11,
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 380,
                  child: InboxMessageCardWidget(
                    size: const Wide2Size(),
                    messages: const [
                      InboxMessage(
                        name: 'Salomé Fernán',
                        avatarUrl:
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuDsw9ChELA7dqeHbfejN8dkMjALY2S1ThiqSCNRUZsLq4olaN6-hNy-3ayi6K4P-58F7il7GtpFP2a3NEtddjYC7RXwUaNcT7jUPvhNHsDw1ZSS5CLG0Y_jbU1MDknvD0PC2os31vl-BPPd7lZ7hM-4u9UevWJ_Lpr0wO8cADU05p-7yFxldQTHxI1hifja00V10wki7zPPzoPZb2fThBrLaolBcsxXWmLLTKKBUPQLTJthX6NfSiWRhyaV4of4OxEmltvGsuBzzw',
                        preview:
                            'How to write advertising article for your business and marketing campaigns effectively',
                        timeAgo: '7 mins ago',
                      ),
                      InboxMessage(
                        name: 'Thanawan Chadee',
                        avatarUrl:
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuDgq5z45_Cg4VhucQoqYGbnnnWGIFykRGb6DPyERRy5bNlYDz_rkyrjtirFhKkgHDXdVXQaMWObeqlm_XioaOJKwDh7mdOXp9UXuLU2bJYke-zLsBqaM5S0kAN8odZ1ojbRq3qRGx5ymmmcflxhwH-6CzL7O8JFfFw1AGYAXNJvHBS9Yvx8P7E758IfBlwIhfp4SpPNUr2iX6ZGBduJ7rmMxEfcn66g6eb3ws4ku0O-otr6Q8jaG2VqeXLSXIpDJPzn90Ycyci8mQ',
                        preview:
                            'Addiction when gambling becomes a serious problem that affects your daily life',
                        timeAgo: '10 mins ago',
                      ),
                      InboxMessage(
                        name: 'Diego Morata',
                        avatarUrl:
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuDaBru40HzWPZQazW01u0WkfKyUUs35h33Pfyxxy1gqOIG_TfQoNxMGogpJMtDkiJCPKXB7AehTpjit7GxToJ0bJgL-kWSh9ARe8FYsfWW1jK0sKa3echRSU4koNMhJ_1RXHPkcH8JFbcllw0vF7dOKy_ROFaARuZmy4kOt3Xf-buwnLo6l6nrXhC3ULp1za05sU8rA58bpaFKhX2TqOu5bf16SUZ_ESL0pdGBgPVtpXWAv6RP5-i5sMS6EOlnLBHimsEY79g5hiQ',
                        preview:
                            'Baby monitor technology and safety features for modern parenting',
                        timeAgo: '20 mins ago',
                      ),
                    ],
                    totalCount: 16,
                    remainingCount: 11,
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
