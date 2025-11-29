package com.example.floating_ball_plugin

import android.content.Context
import android.content.Intent
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class FloatingBallPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private lateinit var context: Context

  override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    context = binding.applicationContext
    channel = MethodChannel(binding.binaryMessenger, "floating_ball_plugin")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "startFloatingBall" -> {
        val intent = Intent(context, FloatingBallService::class.java)
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
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
