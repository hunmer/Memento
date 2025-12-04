import Flutter
import UIKit
import CoreNFC

public class MementoNfcPlugin: NSObject, FlutterPlugin, NFCNDEFReaderSessionDelegate {
  private var readerSession: NFCNDEFReaderSession?
  private var flutterResult: FlutterResult?
  private var pendingMessage: NFCNDEFMessage?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "memento_nfc", binaryMessenger: registrar.messenger())
    let instance = MementoNfcPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    flutterResult = result

    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "isNfcSupported":
      result(NFCNDEFReaderSession.readingAvailable)
    case "isNfcEnabled":
      result(NFCNDEFReaderSession.readingAvailable)
    case "readNfc":
      readNfc()
    case "writeNfc":
      if let args = call.arguments as? [String: Any],
         let data = args["data"] as? String {
        writeNfc(data: data)
      } else {
        result(["success": false, "error": "Invalid arguments"])
      }
    case "writeNdefUrl":
      if let args = call.arguments as? [String: Any],
         let url = args["url"] as? String {
        writeNdefUrl(url: url)
      } else {
        result(["success": false, "error": "Invalid arguments"])
      }
    case "writeNdefText":
      if let args = call.arguments as? [String: Any],
         let text = args["text"] as? String {
        writeNdefText(text: text)
      } else {
        result(["success": false, "error": "Invalid arguments"])
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func readNfc() {
    guard NFCNDEFReaderSession.readingAvailable else {
      flutterResult?(["success": false, "error": "NFC not supported on this device"])
      return
    }

    readerSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
    readerSession?.alertMessage = "将iPhone靠近要读取的NFC标签"
    readerSession?.begin()
  }

  private func writeNfc(data: String) {
    // iOS NFC写入需要iOS 13+，但Flutter插件编译时可能有兼容性问题
    // 暂时返回错误，建议使用第三方应用
    flutterResult?(["success": false, "error": "iOS NFC写入功能需要iOS 13+，建议使用NFC Tools等第三方应用"])
  }

  private func writeNdefUrl(url: String) {
    // iOS NFC写入需要iOS 13+，但Flutter插件编译时可能有兼容性问题
    // 暂时返回错误，建议使用第三方应用
    flutterResult?(["success": false, "error": "iOS NFC写入功能需要iOS 13+，建议使用NFC Tools等第三方应用"])
  }

  private func writeNdefText(text: String) {
    // iOS NFC写入需要iOS 13+，但Flutter插件编译时可能有兼容性问题
    // 暂时返回错误，建议使用第三方应用
    flutterResult?(["success": false, "error": "iOS NFC写入功能需要iOS 13+，建议使用NFC Tools等第三方应用"])
  }

  // MARK: - NFCNDEFReaderSessionDelegate

  public func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
    // 简化错误处理，直接返回错误信息
    flutterResult?(["success": false, "error": error.localizedDescription])
  }

  public func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
    // This is a read operation (when invalidateAfterFirstRead is true)
    var detectedData: [String] = []

    for message in messages {
      for record in message.records {
        if let payloadString = String(data: record.payload, encoding: .utf8) {
          detectedData.append(payloadString)
        }
      }
    }

    if detectedData.isEmpty {
      flutterResult?(["success": false, "error": "No NDEF data found"])
    } else {
      flutterResult?(["success": true, "data": detectedData.joined(separator: "\n")])
    }
  }
}
