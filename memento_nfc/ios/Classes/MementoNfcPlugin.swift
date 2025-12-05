// MementoNfcPlugin.swift
// 完全适配 Xcode 16 + iOS 18 CoreNFC 新 API（已真机验证）
import Flutter
import UIKit
import CoreNFC

@available(iOS 13.0, *)
public class MementoNfcPlugin: NSObject, FlutterPlugin, NFCNDEFReaderSessionDelegate {
    private var readerSession: NFCNDEFReaderSession?
    private var flutterResult: FlutterResult?
    private var pendingMessage: NFCNDEFMessage?
    private var isWriteMode = false
    
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
            // 检查设备是否支持NFC硬件（iPhone 7+且iOS 13+）
            if #available(iOS 13.0, *) {
                result(NFCNDEFReaderSession.readingAvailable)
            } else {
                result(false)
            }

        case "isNfcEnabled":
            // 检查NFC是否可用（与支持检查相同逻辑）
            if #available(iOS 13.0, *) {
                result(NFCNDEFReaderSession.readingAvailable)
            } else {
                result(false)
            }
            
        case "readNfc":
            isWriteMode = false
            startNfcSession()
            
        case "writeNfc":
            guard let args = call.arguments as? [String: Any],
                  let data = args["data"] as? String,
                  let dataUtf8 = data.data(using: .utf8) else {
                result(["success": false, "error": "参数无效"])
                return
            }
            pendingMessage = NFCNDEFMessage(records: [createGenericRecord(payload: dataUtf8)])
            isWriteMode = true
            startNfcSession()
            
        case "writeNdefUrl":
            guard let args = call.arguments as? [String: Any],
                  let url = args["url"] as? String,
                  let payload = NFCNDEFPayload.wellKnownTypeURIPayload(string: url) else {
                result(["success": false, "error": "URL无效或创建失败"])
                return
            }
            pendingMessage = NFCNDEFMessage(records: [payload])
            isWriteMode = true
            startNfcSession()
            
        case "writeNdefText":
            guard let args = call.arguments as? [String: Any],
                  let text = args["text"] as? String else {
                result(["success": false, "error": "参数无效"])
                return
            }
            // 使用当前语言环境创建，如果失败则回退到 en
            if let payload = NFCNDEFPayload.wellKnownTypeTextPayload(string: text, locale: Locale.current) ??
               NFCNDEFPayload.wellKnownTypeTextPayload(string: text, locale: Locale(identifier: "en")) {
                pendingMessage = NFCNDEFMessage(records: [payload])
                isWriteMode = true
                startNfcSession()
            } else {
                result(["success": false, "error": "创建Text payload失败"])
            }
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func startNfcSession() {
        // 调试日志：检查 NFC 可用性
        print("[NFC Debug] NFC available: \(NFCNDEFReaderSession.readingAvailable)")
        print("[NFC Debug] iOS Version: \(UIDevice.current.systemVersion)")
        print("[NFC Debug] Device Model: \(UIDevice.current.model)")

        guard NFCNDEFReaderSession.readingAvailable else {
            print("[NFC Error] NFC not available")
            flutterResult?(["success": false, "error": "设备不支持NFC或未启用NFC"])
            return
        }

        print("[NFC Info] Starting NFC session in \(isWriteMode ? "write" : "read") mode")
        let invalidateAfterFirstRead = !isWriteMode
        readerSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: invalidateAfterFirstRead)
        readerSession?.alertMessage = isWriteMode ? "请靠近要写入的NFC标签" : "请靠近要读取的NFC标签"
        readerSession?.begin()
    }
    
    private func createGenericRecord(payload: Data) -> NFCNDEFPayload {
        return NFCNDEFPayload(
            format: .unknown,
            type: Data(),
            identifier: Data(),
            payload: payload,
            chunkSize: 0
        )
    }
    
    // MARK: - 写入入口（iOS 13+ 写入模式走这里）
    public func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        guard isWriteMode, let message = pendingMessage, let tag = tags.first else {
            session.invalidate(errorMessage: "未检测到标签")
            return
        }
        
        session.connect(to: tag) { error in
            if let error = error {
                session.invalidate(errorMessage: "连接失败：\(error.localizedDescription)")
                return
            }
            
            // 无需额外 casting，tag 已经是 NFCNDEFTag
            tag.queryNDEFStatus { status, capacity, error in
                if let error = error {
                    session.invalidate(errorMessage: "查询失败：\(error.localizedDescription)")
                    return
                }
                
                guard status == .readWrite, capacity >= message.length else {
                    let msg = status == .readOnly ? "标签已锁定为只读" : (status == .notSupported ? "标签不支持写入" : "标签容量不足")
                    session.invalidate(errorMessage: msg)
                    self.flutterResult?(["success": false, "error": msg])
                    return
                }
                
                tag.writeNDEF(message) { error in
                    if let error = error {
                        session.alertMessage = "写入失败"
                        session.invalidate(errorMessage: error.localizedDescription)
                        self.flutterResult?(["success": false, "error": error.localizedDescription])
                    } else {
                        session.alertMessage = "写入成功！"
                        session.invalidate()
                        self.flutterResult?(["success": true])
                    }
                }
            }
        }
    }
    
    // MARK: - 读取入口（所有 iOS 版本都走这里）
    public func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        guard !isWriteMode else { return }
        
        var results: [String] = []
        
        for message in messages {
            for record in message.records {
                // 1. Text Record（兼容 iOS 13–18）
                let textPayload = record.wellKnownTypeTextPayload()
                if let text = textPayload.0 {
                    results.append(text)
                    continue
                }
                
                // 2. URI Record
                if let uri = record.wellKnownTypeURIPayload()?.absoluteString {
                    results.append(uri)
                    continue
                }
                
                // 3. 普通 UTF-8 字符串
                if let str = String(data: record.payload, encoding: .utf8)?.trimmingCharacters(in: .controlCharacters), !str.isEmpty {
                    results.append(str)
                    continue
                }
                
                // 4. 兜底 Base64
                results.append(record.payload.base64EncodedString())
            }
        }
        
        if results.isEmpty {
            flutterResult?(["success": false, "error": "未读取到有效数据"])
        } else {
            flutterResult?(["success": true, "data": results.joined(separator: "\n")])
        }
        
        session.invalidate()
    }
    
    public func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        // 用户主动取消不返回错误
        if let nfcError = error as? NFCReaderError,
           nfcError.code == .readerSessionInvalidationErrorUserCanceled {
            return
        }
        flutterResult?(["success": false, "error": error.localizedDescription])
    }
}