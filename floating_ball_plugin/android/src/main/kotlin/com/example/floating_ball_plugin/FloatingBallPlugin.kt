package com.example.floating_ball_plugin

import android.content.Context
import android.content.Intent
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class FloatingBallPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private lateinit var positionChannel: EventChannel
  private lateinit var buttonChannel: EventChannel
  private lateinit var context: Context
  private var positionSink: EventChannel.EventSink? = null
  private var buttonSink: EventChannel.EventSink? = null

  override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    context = binding.applicationContext
    channel = MethodChannel(binding.binaryMessenger, "floating_ball_plugin")
    channel.setMethodCallHandler(this)

    // 位置事件通道
    positionChannel = EventChannel(binding.binaryMessenger, "floating_ball_plugin/position")
    positionChannel.setStreamHandler(
      object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
          positionSink = events
          FloatingBallService.setPositionSink(events)
        }

        override fun onCancel(arguments: Any?) {
          positionSink = null
          FloatingBallService.setPositionSink(null)
        }
      }
    )

    // 按钮事件通道
    buttonChannel = EventChannel(binding.binaryMessenger, "floating_ball_plugin/button")
    buttonChannel.setStreamHandler(
      object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
          buttonSink = events
          FloatingBallService.setButtonSink(events)
        }

        override fun onCancel(arguments: Any?) {
          buttonSink = null
          FloatingBallService.setButtonSink(null)
        }
      }
    )
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "startFloatingBall" -> {
        val config = call.arguments as? Map<String, Any> ?: emptyMap()
        val intent = Intent(context, FloatingBallService::class.java).apply {
          putExtra("config", HashMap(config))
        }
        context.startService(intent)
        result.success("Floating ball started")
      }
      "stopFloatingBall" -> {
        val intent = Intent(context, FloatingBallService::class.java)
        context.stopService(intent)
        result.success("Floating ball stopped")
      }
      "isRunning" -> {
        val isRunning = FloatingBallService.isRunning
        result.success(isRunning)
      }
      "updateFloatingBallConfig" -> {
        val config = call.arguments as? Map<String, Any> ?: emptyMap()
        FloatingBallService.updateConfig(HashMap(config))
        result.success("Config updated")
      }
      "setFloatingBallImage" -> {
        val imageBytes = call.argument<ByteArray>("imageBytes")
        if (imageBytes != null) {
          FloatingBallService.updateImageFromBytes(imageBytes)
          result.success("Image set")
        } else {
          result.error("INVALID_DATA", "No image bytes", null)
        }
      }
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    positionChannel.setStreamHandler(null)
    buttonChannel.setStreamHandler(null)
  }
}
