import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/message_list_card.dart';

/// 消息列表卡片示例
class MessageListCardExample extends StatelessWidget {
  const MessageListCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('消息列表卡片')),
      body: Container(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFE5E7EB),
        child: const Center(
          child: MessageListCardWidget(
            featuredMessage: FeaturedMessageData(
              sender: '系统通知',
              title: '欢迎使用 Memento',
              summary:
                  '感谢您选择 Memento 作为您的个人数据管理助手。在这里您可以...',
              avatarUrl:
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuBlEyajraqqpBf6RXGVdQEIw0jU4213ckBc7GGF5w7hnca11ioavmtKJO0OGFvL7UBT36uLFu4zaCo5I5Xo2lXKzdeySWvJn6n5zIwC2_3zXbNpeMGdEOBMgDFxUOH1yZdNAOtQQ02iPWyx54bnubRtma_qgdLm9hsKMr4ENTI97B0anJfyuNH8t3-ETJwFu_-NeosA0PoxRgKPHsfDfM6PixiIX1HAhq5BgXH6H6Oyz_AYaahDm8LmS-J1uU0G6m5s5sVIUjvczZL5',
            ),
            messages: [
              MessageData(
                title: '欢迎使用日记功能',
                sender: '小助手',
                channel: '系统消息',
                avatarUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuAoqy2X2o2QPOHJjtGGh-7Gnau_JxA0ibdAumLO2ZRMhMXSPuZMlBKbUHmu6JZEL9MC60T-MMGHvo6C-MCnYgpEecrCflMRZL2tahKsYwm7bUN6syhwlc7Ghoi7reXNWbkR4NPDf6lKFZwMlr158O5ffv-UW3ZDnPhxCDZWFhC7p2ElVFozisz-AaHQIFiWsFjNzAyMxvcoTPge_MtvnAQtIslYbZm0DTb9BE_X7uueMTqquuO1-4k9Dttn0DB9GEdaOOCxPaG1-Sga',
              ),
              MessageData(
                title: '今日习惯打卡提醒',
                sender: '习惯追踪',
                channel: '提醒',
                avatarUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuCAbVBNndlUlI8SEj6g-OATjFQJc6uUguM4zWh5lfIh9EpnqBp-kMFehrtoTWP4O_0B-cPoNsrWDlU543GIJfIyDJCejedKXeEjXjUGYRaOd6obWhRVDxY1zLrbDBegV-Q_1WhQ4OoG3FDIiYNuTUoBXvWNIwYFaxPK8jpHaa_Hhi-1eV_WvaEEdXswt8EGrQfG7WLQTFbTLNcXRScTs1Cta3maih7a7oN4E1qQgeLSRIj97bEuGYKR9Tt-gQDae5YLCMeTiFTxE8Pm',
              ),
              MessageData(
                title: '数据同步已完成',
                sender: '同步服务',
                channel: '系统',
                avatarUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuAhXFkk8fq1S8NOBOoQ_-5sJs4_znnwqyM_QYe2foVzXW94CklEC_77lkGz0KatVEH0RbcHBJRiUjK_P-d15WBtjBrLh2DeJTHyng8lIAdUr2EgVhhy7YvtUVyNqkOiJvUm3XCvz6kBoBh3j7O7x-z8rzxlBf7kIC_AHAFRWTjMdDD8A-3WLnsW_mscu0O5yfaUHBiEWTKwrwTj0tMh9bEEdlAlxzdzfBcIGtkFGGQz-TNILtEMo4YaBRkRrvJAFq-f3-IT6b-bX4TB',
              ),
              MessageData(
                title: '新功能介绍：智能数据分析',
                sender: '产品团队',
                channel: '更新',
                avatarUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuD6KABFHDvf-OJ91ym-BlBCJyQVOu9huxnIKUqO8Nb83qArhaBdHRLZWt94nmuaqXVP9oIkm7sY6pPYnHfiTXCkR3Knd4HvSuKL4C1yvVVnugUhs-J3hE3SQ4eFYdY9sF2ohcMhKYWCzJXXOVZlzNUhTQ1ic3nxjb9fmcptTNGNt-m_ECB8WyDin6UL1OlyIO9bux7XIaNrdxS_xRMvbWsGG7J3xknpg2ltFkipD7HXbdfqjVQqO_J-gpbDcA1OGSpFkxwDVlukQWq6',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
