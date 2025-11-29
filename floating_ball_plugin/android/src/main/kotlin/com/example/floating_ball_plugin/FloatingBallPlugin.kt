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
  private lateinit var eventChannel: EventChannel
  private lateinit var context: Context
  private var eventSink: EventChannel.EventSink? = null

  override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    context = binding.applicationContext
    channel = MethodChannel(binding.binaryMessenger, "floating_ball_plugin")
    channel.setMethodCallHandler(this)

    eventChannel = EventChannel(binding.binaryMessenger, "floating_ball_plugin/events")
    eventChannel.setStreamHandler(
      object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
          eventSink = events
          FloatingBallService.setEventSink(events)
        }

        override fun onCancel(arguments: Any?) {
          eventSink = null
          FloatingBallService.setEventSink(null)
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
    eventChannel.setStreamHandler(null)
  }
}
