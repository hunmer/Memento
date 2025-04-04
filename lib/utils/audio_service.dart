import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  
  factory AudioService() => _instance;
  
  AudioService._internal() {
    // 设置不占用系统音频通道（仅在移动端生效）
    _audioPlayer.setReleaseMode(ReleaseMode.release);
  }
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  /// 通用音频播放函数
  /// [audioPath] 音频资源路径，如 'audio/checkin.mp3'
  Future<void> play(String audioPath) async {
    try {
      await _audioPlayer.play(AssetSource(audioPath));
    } catch (e) {
      debugPrint('播放音频失败: $e，路径: $audioPath');
    }
  }
  
  /// 播放打卡音效（便捷方法）
  Future<void> playCheckInSound() async {
    await play('audio/checkin.mp3');
  }
  
  /// 播放消息发送音效（便捷方法）
  Future<void> playMessageSentSound() async {
    await play('audio/msg_sended.mp3');
  }
  
  /// 释放资源
  void dispose() {
    _audioPlayer.dispose();
  }
}