import Flutter
import UIKit
import CoreNFC

public class MementoNfcPlugin: NSObject, FlutterPlugin, NFCNDEFReaderSessionDelegate {
  private var readerSession: NFCNDEFReaderSession?
  private var flutterResult: FlutterResult?

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
    readerSession?.begin()
  }

  private func writeNfc(data: String) {
    guard NFCNDEFReaderSession.readingAvailable else {
      flutterResult?(["success": false, "error": "NFC not supported on this device"])
      return
    }

    let payload = NFCNDEFPayload(
      format: .media,
      type: "text/plain".data(using: .utf8)!,
      identifier: Data(),
      payload: data.data(using: .utf8)!
    )

    let message = NFCNDEFMessage(records: [payload])

    readerSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
    readerSession?.alertMessage = "Hold iPhone near NFC tag to write"
    readerSession?.begin()
  }

  private func writeNdefUrl(url: String) {
    guard NFCNDEFReaderSession.readingAvailable else {
      flutterResult?(["success": false, "error": "NFC not supported on this device"])
      return
    }

    let urlData = url.data(using: .utf8)!
    var payloadBytes = [UInt8](urlData)
    payloadBytes.insert(0x00, at: 0)

    let payload = NFCNDEFPayload(
      format: .wellKnown,
      type: "U".data(using: .utf8)!,
      identifier: Data(),
      payload: Data(payloadBytes)
    )

    let message = NFCNDEFMessage(records: [payload])

    readerSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
    readerSession?.alertMessage = "Hold iPhone near NFC tag to write"
    readerSession?.begin()
  }

  private func writeNdefText(text: String) {
    guard NFCNDEFReaderSession.readingAvailable else {
      flutterResult?(["success": false, "error": "NFC not supported on this device"])
      return
    }

    let lang = "en"
    let textBytes = [UInt8](text.data(using: .utf8)!)
    let langBytes = [UInt8](lang.data(using: .utf8)!)

    var payload = [UInt8]()
    payload.append(UInt8(langBytes.count))
    payload.append(contentsOf: langBytes)
    payload.append(contentsOf: textBytes)

    let payloadData = Data(payload)

    let payload = NFCNDEFPayload(
      format: .wellKnown,
      type: "T".data(using: .utf8)!,
      identifier: Data(),
      payload: payloadData
    )

    let message = NFCNDEFMessage(records: [payload])

    readerSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
    readerSession?.alertMessage = "Hold iPhone near NFC tag to write"
    readerSession?.begin()
  }

  // MARK: - NFCNDEFReaderSessionDelegate

  public func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
    if let nfcError = error as? NFCReaderError {
      if nfcError.code != .readerSessionInvalidationNeededFirstRead {
        flutterResult?(["success": false, "error": error.localizedDescription])
      }
    }
  }

  public func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFMessages messages: [NFCNDEFMessage]) {
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
