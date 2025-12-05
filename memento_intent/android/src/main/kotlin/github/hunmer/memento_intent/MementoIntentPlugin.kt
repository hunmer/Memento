package github.hunmer.memento_intent

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.Uri
import android.os.PatternMatcher
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.ConcurrentHashMap

/** MementoIntentPlugin */
class MementoIntentPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware,
    EventChannel.StreamHandler {

    private lateinit var channel: MethodChannel
    private lateinit var deepLinkEventChannel: EventChannel
    private lateinit var sharedTextEventChannel: EventChannel
    private lateinit var sharedFilesEventChannel: EventChannel
    private lateinit var intentDataEventChannel: EventChannel

    private var context: Context? = null
    private var activityBinding: ActivityPluginBinding? = null

    // Event sinks for sending events to Flutter
    private var deepLinkEventSink: EventChannel.EventSink? = null
    private var sharedTextEventSink: EventChannel.EventSink? = null
    private var sharedFilesEventSink: EventChannel.EventSink? = null
    private var intentDataEventSink: EventChannel.EventSink? = null

    // Dynamic schemes storage
    private val dynamicSchemes = ConcurrentHashMap<String, DynamicSchemeConfig>()

    private data class DynamicSchemeConfig(
        val scheme: String,
        val host: String? = null,
        val pathPrefix: String? = null
    )

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext

        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "memento_intent")
        channel.setMethodCallHandler(this)

        deepLinkEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "memento_intent/deep_link/events")
        sharedTextEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "memento_intent/shared_text/events")
        sharedFilesEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "memento_intent/shared_files/events")
        intentDataEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "memento_intent/intent_data/events")

        deepLinkEventChannel.setStreamHandler(this)
        sharedTextEventChannel.setStreamHandler(this)
        sharedFilesEventChannel.setStreamHandler(this)
        intentDataEventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        deepLinkEventChannel.setStreamHandler(null)
        sharedTextEventChannel.setStreamHandler(null)
        sharedFilesEventChannel.setStreamHandler(null)
        intentDataEventChannel.setStreamHandler(null)
        context = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        handleIntent(binding.activity.intent)
        binding.addOnNewIntentListener { intent ->
            handleIntent(intent)
            true
        }
    }

    override fun onDetachedFromActivity() {
        activityBinding = null
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
        handleIntent(binding.activity.intent)
        binding.addOnNewIntentListener { intent ->
            handleIntent(intent)
            true
        }
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return

        when (intent.action) {
            Intent.ACTION_SEND -> {
                if (intent.type?.startsWith("text/") == true) {
                    val sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
                    if (!sharedText.isNullOrEmpty()) {
                        sharedTextEventSink?.success(sharedText)
                    }
                } else if (intent.type?.startsWith("image/") == true ||
                    intent.type?.startsWith("video/") == true) {
                    val uri = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
                    uri?.let {
                        sharedFilesEventSink?.success(
                            listOf(
                                mapOf(
                                    "path" to it.toString(),
                                    "type" to if (intent.type?.startsWith("image/") == true) "image" else "video"
                                )
                            )
                        )
                    }
                }
            }
            Intent.ACTION_VIEW -> {
                intent.data?.let { uri ->
                    deepLinkEventSink?.success(uri.toString())
                }
            }
        }

        // Send intent data
        intentDataEventSink?.success(
            mapOf(
                "action" to intent.action,
                "data" to intent.dataString,
                "type" to intent.type,
                "extras" to intent.extras?.keySet()?.associate { it to intent.extras?.get(it) }
            )
        )
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "registerDynamicScheme" -> {
                val scheme = call.argument<String>("scheme")
                val host = call.argument<String>("host")
                val pathPrefix = call.argument<String>("pathPrefix")

                if (scheme.isNullOrEmpty()) {
                    result.error("INVALID_SCHEME", "Scheme cannot be empty", null)
                    return
                }

                val success = registerDynamicSchemeInternal(scheme, host, pathPrefix)
                result.success(success)
            }
            "unregisterDynamicScheme" -> {
                val success = unregisterDynamicSchemeInternal()
                result.success(success)
            }
            "getDynamicSchemes" -> {
                val schemes = dynamicSchemes.values.map { it.scheme }
                result.success(schemes)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun registerDynamicSchemeInternal(
        scheme: String,
        host: String?,
        pathPrefix: String?
    ): Boolean {
        val context = this.context ?: return false

        try {
            // Store the scheme configuration
            dynamicSchemes[scheme] = DynamicSchemeConfig(scheme, host, pathPrefix)

            // Create intent filter (simplified to ensure compatibility)
            val intentFilter = IntentFilter(Intent.ACTION_VIEW).apply {
                addCategory(Intent.CATEGORY_DEFAULT)
                addCategory(Intent.CATEGORY_BROWSABLE)
                addDataScheme(scheme)
                // Note: Dynamic intent filter registration has limitations on Android
                // We'll rely on the dynamic component enabling instead
            }

            // Enable the dynamic activity
            val componentName = ComponentName(context, "${context.packageName}.DynamicDeepLinkActivity")
            context.packageManager.setComponentEnabledSetting(
                componentName,
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                PackageManager.DONT_KILL_APP
            )

            return true
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }

    private fun unregisterDynamicSchemeInternal(): Boolean {
        val context = this.context ?: return false

        try {
            // Disable all dynamic schemes
            dynamicSchemes.clear()

            // Disable the dynamic activity
            val componentName = ComponentName(context, "${context.packageName}.DynamicDeepLinkActivity")
            context.packageManager.setComponentEnabledSetting(
                componentName,
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                PackageManager.DONT_KILL_APP
            )

            return true
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        when (arguments) {
            is String -> {
                when (arguments) {
                    "deep_link" -> deepLinkEventSink = events
                    "shared_text" -> sharedTextEventSink = events
                    "shared_files" -> sharedFilesEventSink = events
                    "intent_data" -> intentDataEventSink = events
                }
            }
        }
    }

    override fun onCancel(arguments: Any?) {
        when (arguments) {
            is String -> {
                when (arguments) {
                    "deep_link" -> deepLinkEventSink = null
                    "shared_text" -> sharedTextEventSink = null
                    "shared_files" -> sharedFilesEventSink = null
                    "intent_data" -> intentDataEventSink = null
                }
            }
        }
    }
}
