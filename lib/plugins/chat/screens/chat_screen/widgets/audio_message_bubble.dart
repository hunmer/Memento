import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/plugins/chat/models/message.dart';
import 'package:Memento/plugins/chat/widgets/audio_player_widget.dart';

class AudioMessageBubble extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;

  const AudioMessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    // 获取音频文件路径
    final audioPath = message.content;
    if (audioPath == null) {
      return Text('chat_audioMessageBubbleErrorText'.tr);
    }

    // 获取音频时长
    final duration = message.audioDuration;

    // 设置颜色
    final primaryColor =
        isCurrentUser ? Theme.of(context).primaryColor : Colors.grey.shade700;
    final backgroundColor =
        isCurrentUser
            ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
            : Colors.grey.shade200;
    final progressColor =
        isCurrentUser ? Theme.of(context).primaryColor : Colors.grey.shade500;

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 音频播放器
          AudioPlayerWidget(
            audioPath: audioPath,
            durationInSeconds: duration,
            isLocalFile: true,
            primaryColor: primaryColor,
            backgroundColor: backgroundColor,
            progressColor: progressColor,
          ),

          // 如果消息被编辑过，显示编辑标记
          if (message.isEdited)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                '已编辑',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
