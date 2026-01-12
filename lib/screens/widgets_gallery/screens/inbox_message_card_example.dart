import 'package:flutter/material.dart';
import 'package:Memento/widgets/common/inbox_message_card.dart';

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
        child: const Center(
          child: InboxMessageCardWidget(
            messages: [
              InboxMessage(
                name: 'Salomé Fernán',
                avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDsw9ChELA7dqeHbfejN8dkMjALY2S1ThiqSCNRUZsLq4olaN6-hNy-3ayi6K4P-58F7il7GtpFP2a3NEtddjYC7RXwUaNcT7jUPvhNHsDw1ZSS5CLG0Y_jbU1MDknvD0PC2os31vl-BPPd7lZ7hM-4u9UevWJ_Lpr0wO8cADU05p-7yFxldQTHxI1hifja00V10wki7zPPzoPZb2fThBrLaolBcsxXWmLLTKKBUPQLTJthX6NfSiWRhyaV4of4OxEmltvGsuBzzw',
                preview: 'How to write advertising article',
                timeAgo: '7 mins ago',
              ),
              InboxMessage(
                name: 'Thanawan Chadee',
                avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDgq5z45_Cg4VhucQoqYGbnnnWGIFykRGb6DPyERRy5bNlYDz_rkyrjtirFhKkgHDXdVXQaMWObeqlm_XioaOJKwDh7mdOXp9UXuLU2bJYke-zLsBqaM5S0kAN8odZ1ojbRq3qRGx5ymmmcflxhwH-6CzL7O8JFfFw1AGYAXNJvHBS9Yvx8P7E758IfBlwIhfp4SpPNUr2iX6ZGBduJ7rmMxEfcn66g6eb3ws4ku0O-otr6Q8jaG2VqeXLSXIpDJPzn90Ycyci8mQ',
                preview: 'Addiction when gambling becomes',
                timeAgo: '10 mins ago',
              ),
              InboxMessage(
                name: 'Diego Morata',
                avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDaBru40HzWPZQazW01u0WkfKyUUs35h33Pfyxxy1gqOIG_TfQoNxMGogpJMtDkiJCPKXB7AehTpjit7GxToJ0bJgL-kWSh9ARe8FYsfWW1jK0sKa3echRSU4koNMhJ_1RXHPkcH8JFbcllw0vF7dOKy_ROFaARuZmy4kOt3Xf-buwnLo6l6nrXhC3ULp1za05sU8rA58bpaFKhX2TqOu5bf16SUZ_ESL0pdGBgPVtpXWAv6RP5-i5sMS6EOlnLBHimsEY79g5hiQ',
                preview: 'Baby monitor technology',
                timeAgo: '20 mins ago',
              ),
              InboxMessage(
                name: 'Neville Griffin',
                avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBUqxBeN7cxqIwcJb4LqqvBXGrQVfeHVLHyg7hVqINu-wj6H5tU9DmCeSNd54MxDNwPAOamdWW5N2X9PDVhG5wW65aL3B8PF5wjYkEYGuN34Yh53bm3OhdrwvaFcRK_286t6oSU0WjXe8QsBpBRhl_ESbXyu1jEBqr9TUF__pvfk43riThGAy7eBv6HdJPq4ZtyMsHl6mU1119WKB6bsQKYcfugjqs7Qnzwi6gyJoOiHVLCzX_Skgn8kmqKShwzTN-mF6-kI6er9w',
                preview: 'Protective preventative maintenance',
                timeAgo: '30 mins ago',
              ),
              InboxMessage(
                name: 'Izabella Tabakova',
                avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuB2X8X-E5vDfF4d7kbU0_r_3_quLc92NGoC8gsY26g3lEuiaTw1Ol7-8RTtKZ2RVurnF4faslqwgchUXkbEo_7QVzW8pQjoPUk66ZFr7pCuy5kdy4T91WfvgyadQs0ayrSUNRkdntQRDdM9V-2hyfcdmbEjc80f9Bocvu2mMHHshxwMxWf6_J2sySNt22MyzwKDPkTU1nYQ9aZYBbLE7DI9EdgUBBl7I8LTsFKq52vzhIgk_kjBNd2T9vNEtuhe9tpphSL1KNle5A',
                preview: 'Finally a top secret way for marketing',
                timeAgo: '1 hr ago',
              ),
            ],
            totalCount: 16,
            remainingCount: 11,
          ),
        ),
      ),
    );
  }
}
