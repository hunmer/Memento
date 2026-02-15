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
                    child: MessageListCardWidget(
                      featuredMessage: const FeaturedMessageData(
                        sender: '系统通知',
                        title: '欢迎使用 Memento',
                        summary: '感谢您选择 Memento...',
                        avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBlEyajraqqpBf6RXGVdQEIw0jU4213ckBc7GGF5w7hnca11ioavmtKJO0OGFvL7UBT36uLFu4zaCo5I5Xo2lXKzdeySWvJn6n5zIwC2_3zXbNpeMGdEOBMgDFxUOH1yZdNAOtQQ02iPWyx54bnubRtma_qgdLm9hsKMr4ENTI97B0anJfyuNH8t3-ETJwFu_-NeosA0PoxRgKPHsfDfM6PixiIX1HAhq5BgXH6H6Oyz_AYaahDm8LmS-J1uU0G6m5s5sVIUjvczZL5',
                      ),
                      messages: const [
                        MessageData(
                          title: '欢迎使用日记功能',
                          sender: '小助手',
                          channel: '系统消息',
                          avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAoqy2X2o2QPOHJjtGGh-7Gnau_JxA0ibdAumLO2ZRMhMXSPuZMlBKbUHmu6JZEL9MC60T-MMGHvo6C-MCnYgpEecrCflMRZL2tahKsYwm7bUN6syhwlc7Ghoi7reXNWbkR4NPDf6lKFZwMlr158O5ffv-UW3ZDnPhxCDZWFhC7p2ElVFozisz-AaHQIFiWsFjNzAyMxvcoTPge_MtvnAQtIslYbZm0DTb9BE_X7uueMTqquuO1-4k9Dttn0DB9GEdaOOCxPaG1-Sga',
                        ),
                      ],
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
                    child: MessageListCardWidget(
                      featuredMessage: const FeaturedMessageData(
                        sender: '系统通知',
                        title: '欢迎使用 Memento',
                        summary: '感谢您选择 Memento 作为您的个人数据管理助手。',
                        avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBlEyajraqqpBf6RXGVdQEIw0jU4213ckBc7GGF5w7hnca11ioavmtKJO0OGFvL7UBT36uLFu4zaCo5I5Xo2lXKzdeySWvJn6n5zIwC2_3zXbNpeMGdEOBMgDFxUOH1yZdNAOtQQ02iPWyx54bnubRtma_qgdLm9hsKMr4ENTI97B0anJfyuNH8t3-ETJwFu_-NeosA0PoxRgKPHsfDfM6PixiIX1HAhq5BgXH6H6Oyz_AYaahDm8LmS-J1uU0G6m5s5sVIUjvczZL5',
                      ),
                      messages: const [
                        MessageData(
                          title: '欢迎使用日记功能',
                          sender: '小助手',
                          channel: '系统消息',
                          avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAoqy2X2o2QPOHJjtGGh-7Gnau_JxA0ibdAumLO2ZRMhMXSPuZMlBKbUHmu6JZEL9MC60T-MMGHvo6C-MCnYgpEecrCflMRZL2tahKsYwm7bUN6syhwlc7Ghoi7reXNWbkR4NPDf6lKFZwMlr158O5ffv-UW3ZDnPhxCDZWFhC7p2ElVFozisz-AaHQIFiWsFjNzAyMxvcoTPge_MtvnAQtIslYbZm0DTb9BE_X7uueMTqquuO1-4k9Dttn0DB9GEdaOOCxPaG1-Sga',
                        ),
                        MessageData(
                          title: '今日习惯打卡提醒',
                          sender: '习惯追踪',
                          channel: '提醒',
                          avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCAbVBNndlUlI8SEj6g-OATjFQJc6uUguM4zWh5lfIh9EpnqBp-kMFehrtoTWP4O_0B-cPoNsrWDlU543GIJfIyDJCejedKXeEjXjUGYRaOd6obWhRVDxY1zLrbDBegV-Q_1WhQ4OoG3FDIiYNuTUoBXvWNIwYFaxPK8jpHaa_Hhi-1eV_WvaEEdXswt8EGrQfG7WLQTFbTLNcXRScTs1Cta3maih7a7oN4E1qQgeLSRIj97bEuGYKR9Tt-gQDae5YLCMeTiFTxE8Pm',
                        ),
                      ],
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
                    child: MessageListCardWidget(
                      featuredMessage: const FeaturedMessageData(
                        sender: '系统通知',
                        title: '欢迎使用 Memento',
                        summary: '感谢您选择 Memento 作为您的个人数据管理助手。在这里您可以管理您的个人数据。',
                        avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBlEyajraqqpBf6RXGVdQEIw0jU4213ckBc7GGF5w7hnca11ioavmtKJO0OGFvL7UBT36uLFu4zaCo5I5Xo2lXKzdeySWvJn6n5zIwC2_3zXbNpeMGdEOBMgDFxUOH1yZdNAOtQQ02iPWyx54bnubRtma_qgdLm9hsKMr4ENTI97B0anJfyuNH8t3-ETJwFu_-NeosA0PoxRgKPHsfDfM6PixiIX1HAhq5BgXH6H6Oyz_AYaahDm8LmS-J1uU0G6m5s5sVIUjvczZL5',
                      ),
                      messages: const [
                        MessageData(
                          title: '欢迎使用日记功能',
                          sender: '小助手',
                          channel: '系统消息',
                          avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAoqy2X2o2QPOHJjtGGh-7Gnau_JxA0ibdAumLO2ZRMhMXSPuZMlBKbUHmu6JZEL9MC60T-MMGHvo6C-MCnYgpEecrCflMRZL2tahKsYwm7bUN6syhwlc7Ghoi7reXNWbkR4NPDf6lKFZwMlr158O5ffv-UW3ZDnPhxCDZWFhC7p2ElVFozisz-AaHQIFiWsFjNzAyMxvcoTPge_MtvnAQtIslYbZm0DTb9BE_X7uueMTqquuO1-4k9Dttn0DB9GEdaOOCxPaG1-Sga',
                        ),
                        MessageData(
                          title: '今日习惯打卡提醒',
                          sender: '习惯追踪',
                          channel: '提醒',
                          avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCAbVBNndlUlI8SEj6g-OATjFQJc6uUguM4zWh5lfIh9EpnqBp-kMFehrtoTWP4O_0B-cPoNsrWDlU543GIJfIyDJCejedKXeEjXjUGYRaOd6obWhRVDxY1zLrbDBegV-Q_1WhQ4OoG3FDIiYNuTUoBXvWNIwYFaxPK8jpHaa_Hhi-1eV_WvaEEdXswt8EGrQfG7WLQTFbTLNcXRScTs1Cta3maih7a7oN4E1qQgeLSRIj97bEuGYKR9Tt-gQDae5YLCMeTiFTxE8Pm',
                        ),
                        MessageData(
                          title: '数据同步已完成',
                          sender: '同步服务',
                          channel: '系统',
                          avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAhXFkk8fq1S8NOBOoQ_-5sJs4_znnwqyM_QYe2foVzXW94CklEC_77lkGz0KatVEH0RbcHBJRiUjK_P-d15WBtjBrLh2DeJTHyng8lIAdUr2EgVhhy7YvtUVyNqkOiJvUm3XCvz6kBoBh3j7O7x-z8rzxlBf7kIC_AHAFRWTjMdDD8A-3WLnsW_mscu0O5yfaUHBiEWTKwrwTj0tMh9bEEdlAlxzdzfBcIGtkFGGQz-TNILtEMo4YaBRkRrvJAFq-f3-IT6b-bX4TB',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 300,
                  child: MessageListCardWidget(
                    featuredMessage: const FeaturedMessageData(
                      sender: '系统通知',
                      title: '欢迎使用 Memento',
                      summary: '感谢您选择 Memento 作为您的个人数据管理助手。在这里您可以管理您的个人数据、追踪习惯、管理任务等。',
                      avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBlEyajraqqpBf6RXGVdQEIw0jU4213ckBc7GGF5w7hnca11ioavmtKJO0OGFvL7UBT36uLFu4zaCo5I5Xo2lXKzdeySWvJn6n5zIwC2_3zXbNpeMGdEOBMgDFxUOH1yZdNAOtQQ02iPWyx54bnubRtma_qgdLm9hsKMr4ENTI97B0anJfyuNH8t3-ETJwFu_-NeosA0PoxRgKPHsfDfM6PixiIX1HAhq5BgXH6H6Oyz_AYaahDm8LmS-J1uU0G6m5s5sVIUjvczZL5',
                    ),
                    messages: const [
                      MessageData(
                        title: '欢迎使用日记功能',
                        sender: '小助手',
                        channel: '系统消息',
                        avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAoqy2X2o2QPOHJjtGGh-7Gnau_JxA0ibdAumLO2ZRMhMXSPuZMlBKbUHmu6JZEL9MC60T-MMGHvo6C-MCnYgpEecrCflMRZL2tahKsYwm7bUN6syhwlc7Ghoi7reXNWbkR4NPDf6lKFZwMlr158O5ffv-UW3ZDnPhxCDZWFhC7p2ElVFozisz-AaHQIFiWsFjNzAyMxvcoTPge_MtvnAQtIslYbZm0DTb9BE_X7uueMTqquuO1-4k9Dttn0DB9GEdaOOCxPaG1-Sga',
                      ),
                      MessageData(
                        title: '今日习惯打卡提醒',
                        sender: '习惯追踪',
                        channel: '提醒',
                        avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCAbVBNndlUlI8SEj6g-OATjFQJc6uUguM4zWh5lfIh9EpnqBp-kMFehrtoTWP4O_0B-cPoNsrWDlU543GIJfIyDJCejedKXeEjXjUGYRaOd6obWhRVDxY1zLrbDBegV-Q_1WhQ4OoG3FDIiYNuTUoBXvWNIwYFaxPK8jpHaa_Hhi-1eV_WvaEEdXswt8EGrQfG7WLQTFbTLNcXRScTs1Cta3maih7a7oN4E1qQgeLSRIj97bEuGYKR9Tt-gQDae5YLCMeTiFTxE8Pm',
                      ),
                      MessageData(
                        title: '数据同步已完成',
                        sender: '同步服务',
                        channel: '系统',
                        avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAhXFkk8fq1S8NOBOoQ_-5sJs4_znnwqyM_QYe2foVzXW94CklEC_77lkGz0KatVEH0RbcHBJRiUjK_P-d15WBtjBrLh2DeJTHyng8lIAdUr2EgVhhy7YvtUVyNqkOiJvUm3XCvz6kBoBh3j7O7x-z8rzxlBf7kIC_AHAFRWTjMdDD8A-3WLnsW_mscu0O5yfaUHBiEWTKwrwTj0tMh9bEEdlAlxzdzfBcIGtkFGGQz-TNILtEMo4YaBRkRrvJAFq-f3-IT6b-bX4TB',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 400,
                  child: MessageListCardWidget(
                    featuredMessage: const FeaturedMessageData(
                      sender: '系统通知',
                      title: '欢迎使用 Memento',
                      summary: '感谢您选择 Memento 作为您的个人数据管理助手。Memento 是一个强大的个人数据管理与分析平台，利用 AI 驱动数据价值，支持终身使用的个人数据管理。',
                      avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBlEyajraqqpBf6RXGVdQEIw0jU4213ckBc7GGF5w7hnca11ioavmtKJO0OGFvL7UBT36uLFu4zaCo5I5Xo2lXKzdeySWvJn6n5zIwC2_3zXbNpeMGdEOBMgDFxUOH1yZdNAOtQQ02iPWyx54bnubRtma_qgdLm9hsKMr4ENTI97B0anJfyuNH8t3-ETJwFu_-NeosA0PoxRgKPHsfDfM6PixiIX1HAhq5BgXH6H6Oyz_AYaahDm8LmS-J1uU0G6m5s5sVIUjvczZL5',
                    ),
                    messages: const [
                      MessageData(
                        title: '欢迎使用日记功能',
                        sender: '小助手',
                        channel: '系统消息',
                        avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAoqy2X2o2QPOHJjtGGh-7Gnau_JxA0ibdAumLO2ZRMhMXSPuZMlBKbUHmu6JZEL9MC60T-MMGHvo6C-MCnYgpEecrCflMRZL2tahKsYwm7bUN6syhwlc7Ghoi7reXNWbkR4NPDf6lKFZwMlr158O5ffv-UW3ZDnPhxCDZWFhC7p2ElVFozisz-AaHQIFiWsFjNzAyMxvcoTPge_MtvnAQtIslYbZm0DTb9BE_X7uueMTqquuO1-4k9Dttn0DB9GEdaOOCxPaG1-Sga',
                      ),
                      MessageData(
                        title: '今日习惯打卡提醒',
                        sender: '习惯追踪',
                        channel: '提醒',
                        avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCAbVBNndlUlI8SEj6g-OATjFQJc6uUguM4zWh5lfIh9EpnqBp-kMFehrtoTWP4O_0B-cPoNsrWDlU543GIJfIyDJCejedKXeEjXjUGYRaOd6obWhRVDxY1zLrbDBegV-Q_1WhQ4OoG3FDIiYNuTUoBXvWNIwYFaxPK8jpHaa_Hhi-1eV_WvaEEdXswt8EGrQfG7WLQTFbTLNcXRScTs1Cta3maih7a7oN4E1qQgeLSRIj97bEuGYKR9Tt-gQDae5YLCMeTiFTxE8Pm',
                      ),
                      MessageData(
                        title: '数据同步已完成',
                        sender: '同步服务',
                        channel: '系统',
                        avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAhXFkk8fq1S8NOBOoQ_-5sJs4_znnwqyM_QYe2foVzXW94CklEC_77lkGz0KatVEH0RbcHBJRiUjK_P-d15WBtjBrLh2DeJTHyng8lIAdUr2EgVhhy7YvtUVyNqkOiJvUm3XCvz6kBoBh3j7O7x-z8rzxlBf7kIC_AHAFRWTjMdDD8A-3WLnsW_mscu0O5yfaUHBiEWTKwrwTj0tMh9bEEdlAlxzdzfBcIGtkFGGQz-TNILtEMo4YaBRkRrvJAFq-f3-IT6b-bX4TB',
                      ),
                    ],
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
