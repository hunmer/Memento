/// 语音识别状态枚举
enum SpeechRecognitionState {
  /// 空闲状态
  idle,

  /// 正在连接
  connecting,

  /// 正在录音
  recording,

  /// 正在处理
  processing,

  /// 错误状态
  error,
}

/// 语音识别状态扩展
extension SpeechRecognitionStateExtension on SpeechRecognitionState {
  /// 获取状态的中文描述
  String get description {
    switch (this) {
      case SpeechRecognitionState.idle:
        return '空闲';
      case SpeechRecognitionState.connecting:
        return '正在连接...';
      case SpeechRecognitionState.recording:
        return '正在录音...';
      case SpeechRecognitionState.processing:
        return '正在处理...';
      case SpeechRecognitionState.error:
        return '错误';
    }
  }

  /// 是否可以开始录音
  bool get canStartRecording {
    return this == SpeechRecognitionState.idle;
  }

  /// 是否可以停止录音
  bool get canStopRecording {
    return this == SpeechRecognitionState.recording;
  }
}
