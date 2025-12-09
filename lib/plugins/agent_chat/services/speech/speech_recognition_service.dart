import 'dart:async';
import 'package:get/get.dart';
import 'speech_recognition_state.dart';

/// 语音识别服务抽象基类
///
/// 定义语音识别的标准接口，便于未来扩展其他服务商
abstract class SpeechRecognitionService {
  /// 识别结果流
  ///
  /// 实时推送识别的文本结果
  Stream<String> get recognitionStream;

  /// 状态变化流
  ///
  /// 推送服务状态的变化
  Stream<SpeechRecognitionState> get stateStream;

  /// 错误信息流
  ///
  /// 推送错误信息
  Stream<String> get errorStream;

  /// 当前状态
  SpeechRecognitionState get currentState;

  /// 初始化服务
  ///
  /// 在开始录音前调用，准备必要的资源
  Future<void> initialize();

  /// 开始录音
  ///
  /// 开始录音并实时识别
  /// 返回值表示是否成功开始
  Future<bool> startRecording();

  /// 停止录音
  ///
  /// 停止录音并结束识别
  Future<void> stopRecording();

  /// 取消录音
  ///
  /// 取消录音并丢弃结果
  Future<void> cancelRecording();

  /// 释放资源
  ///
  /// 释放所有资源，包括录音器、WebSocket 连接等
  void dispose();
}
