import Flutter
import UIKit
import Foundation

public class MementoIntentPlugin: NSObject, FlutterPlugin {

    private static let deepLinkEventChannelName = "memento_intent/deep_link/events"
    private static let sharedTextEventChannelName = "memento_intent/shared_text/events"
    private static let sharedFilesEventChannelName = "memento_intent/shared_files/events"
    private static let intentDataEventChannelName = "memento_intent/intent_data/events"

    private var methodChannel: FlutterMethodChannel?
    private var deepLinkEventSink: FlutterEventSink?
    private var sharedTextEventSink: FlutterEventSink?
    private var sharedFilesEventSink: FlutterEventSink?
    private var intentDataEventSink: FlutterEventSink?

    private var dynamicSchemes: [String] = []

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = MementoIntentPlugin()

        instance.methodChannel = FlutterMethodChannel(
            name: "memento_intent",
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(instance, channel: instance.methodChannel!)

        // Register event channels
        registrar.register(
            FlutterEventChannel(
                name: deepLinkEventChannelName,
                binaryMessenger: registrar.messenger()
            ),
            instance: instance
        )

        registrar.register(
            FlutterEventChannel(
                name: sharedTextEventChannelName,
                binaryMessenger: registrar.messenger()
            ),
            instance: instance
        )

        registrar.register(
            FlutterEventChannel(
                name: sharedFilesEventChannelName,
                binaryMessenger: registrar.messenger()
            ),
            instance: instance
        )

        registrar.register(
            FlutterEventChannel(
                name: intentDataEventChannelName,
                binaryMessenger: registrar.messenger()
            ),
            instance: instance
        )
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)

        case "registerDynamicScheme":
            guard let args = call.arguments as? [String: Any],
                  let scheme = args["scheme"] as? String else {
                result(FlutterError(
                    code: "INVALID_SCHEME",
                    message: "Scheme cannot be empty",
                    details: nil
                ))
                return
            }

            let host = args["host"] as? String
            let pathPrefix = args["pathPrefix"] as? String

            let success = registerDynamicSchemeInternal(scheme: scheme, host: host, pathPrefix: pathPrefix)
            result(success)

        case "unregisterDynamicScheme":
            let success = unregisterDynamicSchemeInternal()
            result(success)

        case "getDynamicSchemes":
            result(dynamicSchemes)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func registerDynamicSchemeInternal(scheme: String, host: String?, pathPrefix: String?) -> Bool {
        // Store the scheme
        if !dynamicSchemes.contains(scheme) {
            dynamicSchemes.append(scheme)
        }

        // Save to UserDefaults
        UserDefaults.standard.set(dynamicSchemes, forKey: "memento_intent_dynamic_schemes")

        // Note: iOS doesn't support dynamic URL scheme registration at runtime
        // The scheme needs to be configured in Info.plist beforehand
        // This implementation stores the scheme for reference and validation

        return true
    }

    private func unregisterDynamicSchemeInternal() -> Bool {
        dynamicSchemes.removeAll()
        UserDefaults.standard.removeObject(forKey: "memento_intent_dynamic_schemes")
        return true
    }

    // Handle URL opening
    public func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        guard let scheme = url.scheme?.lowercased() else { return false }

        // Check if the scheme is in our dynamic schemes
        if dynamicSchemes.contains(scheme.lowercased()) {
            // Send deep link event
            DispatchQueue.main.async { [weak self] in
                self?.deepLinkEventSink?(url.absoluteString)
                self?.intentDataEventSink?([
                    "action": "OPEN_URL",
                    "data": url.absoluteString,
                    "type": "url",
                    "extras": [:]
                ])
            }
            return true
        }

        return false
    }

    // Handle sharing
    public func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return application(application, open: url, options: [:])
    }

    // MARK: - FlutterStreamHandler

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        guard let channelName = arguments as? String else {
            return FlutterError(code: "INVALID_ARGUMENT", message: "Expected String channel name", details: nil)
        }

        switch channelName {
        case "deep_link":
            deepLinkEventSink = events
        case "shared_text":
            sharedTextEventSink = events
        case "shared_files":
            sharedFilesEventSink = events
        case "intent_data":
            intentDataEventSink = events
        default:
            return FlutterError(code: "UNKNOWN_CHANNEL", message: "Unknown channel: \(channelName)", details: nil)
        }

        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        guard let channelName = arguments as? String else {
            return FlutterError(code: "INVALID_ARGUMENT", message: "Expected String channel name", details: nil)
        }

        switch channelName {
        case "deep_link":
            deepLinkEventSink = nil
        case "shared_text":
            sharedTextEventSink = nil
        case "shared_files":
            sharedFilesEventSink = nil
        case "intent_data":
            intentDataEventSink = nil
        default:
            return FlutterError(code: "UNKNOWN_CHANNEL", message: "Unknown channel: \(channelName)", details: nil)
        }

        return nil
    }
}

// MARK: - AppDelegate Extension
extension MementoIntentPlugin {
    // This would typically be in your AppDelegate, but for the plugin example
    // We provide a helper to handle URL opening
    static func handleOpenURL(_ url: URL) {
        // This would be called from the AppDelegate
        // For example purposes, showing how it would work
    }
}
