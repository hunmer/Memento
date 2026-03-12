# add-watchos-plugin-support

## 触发条件
用户要求为 Flutter 插件添加 watchOS 支持，在 Apple Watch 上显示插件数据。

## 架构概述

```
watchOS SwiftUI View
       ↓ WCSession.sendMessage(["request": "getXXX"])
iOS Runner WCSessionManager
       ↓ methodChannel.invokeMethod("getWatchXXX")
Flutter WatchConnectivityService
       ↓ 调用目标插件的方法
Flutter Plugin (如 DiaryPlugin)
       ↓ 返回数据
watchOS 显示数据
```

## 实施步骤

### 1. Flutter 端 - WatchConnectivityService

**文件**: `lib/plugins/agent_chat/services/watch_connectivity_service.dart`

在 `_setupMethodHandler` 的 switch 中添加 case：
```dart
case 'getWatchPluginData':
  return await _getWatchPluginData(call.arguments);
```

添加处理方法：
```dart
Future<List<Map<String, dynamic>>> _getWatchPluginData(dynamic arguments) async {
  final plugin = Plugin.instance;
  final data = plugin.getDataSync();  // 使用同步方法

  return data.map((item) => {
    'id': item.id,
    'title': item.title,
    // 转换为 watchOS 需要的格式
  }).toList();
}
```

### 2. iOS Runner - WCSessionManager

**文件**: `ios/Runner/WCSessionManager.swift`

添加请求枚举：
```swift
enum WatchRequest: String {
    case getPluginData
}
```

在 `didReceiveMessage:replyHandler:` 的 switch 中添加：
```swift
case .getPluginData:
    handleGetPluginData(replyHandler: replyHandler)
```

添加处理方法：
```swift
private func handleGetPluginData(replyHandler: @escaping ([String: Any]) -> Void) {
    methodChannel?.invokeMethod("getWatchPluginData", arguments: nil) { result in
        if let flutterError = result as? FlutterError {
            replyHandler(["success": false, "error": flutterError.message ?? "未知错误"])
            return
        }
        guard let data = result as? [[String: Any]] else {
            replyHandler(["success": false, "error": "无效的数据格式"])
            return
        }
        replyHandler(["success": true, "data": data])
    }
}
```

### 3. watchOS - WCSessionManager

**文件**: `ios/memento Watch App/WCSessionManager.swift`

添加数据模型：
```swift
struct PluginData: Codable, Identifiable {
    let id: String
    let title: String
    // 其他字段...
}
```

在 `WatchRequest` 枚举中添加：
```swift
case getPluginData
```

添加请求方法：
```swift
func getPluginData() async throws -> [PluginData] {
    let request: [String: Any] = ["request": WatchRequest.getPluginData.rawValue]

    return try await withCheckedThrowingContinuation { continuation in
        WCSession.default.sendMessage(request, replyHandler: { response in
            if let success = response["success"] as? Bool, success,
               let dataArray = response["data"] as? [[String: Any]] {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: dataArray)
                    let items = try JSONDecoder().decode([PluginData].self, from: jsonData)
                    continuation.resume(returning: items)
                } catch {
                    continuation.resume(throwing: error)
                }
            } else if let errorMessage = response["error"] as? String {
                continuation.resume(throwing: NSError(domain: "WCSession", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: errorMessage]))
            }
        }, errorHandler: { error in
            continuation.resume(throwing: error)
        })
    }
}
```

### 4. watchOS - SwiftUI 视图

**新建文件**: `ios/memento Watch App/PluginListView.swift`

```swift
import SwiftUI
import Combine

struct PluginData: Codable, Identifiable {
    let id: String
    let title: String
}

struct PluginListView: View {
    @StateObject private var viewModel = PluginListViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("加载中...")
            } else if let error = viewModel.error {
                VStack {
                    Text(error)
                    Button("重试") { Task { await viewModel.loadData() } }
                }
            } else if viewModel.items.isEmpty {
                Text("暂无数据")
            } else {
                List(viewModel.items) { item in
                    Text(item.title)
                }
            }
        }
        .navigationTitle("插件名")
        .task { await viewModel.loadData() }
    }
}

@MainActor
class PluginListViewModel: ObservableObject {
    @Published var items: [PluginData] = []
    @Published var isLoading = false
    @Published var error: String?

    func loadData() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        do {
            items = try await WCSessionManager.shared.getPluginData()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
```

### 5. watchOS - 添加卡片入口

**文件**: `ios/memento Watch App/ContentView.swift`

```swift
// 1. 添加枚举值
enum CardDestination: String {
    case plugin = "插件名"
}

// 2. 添加卡片数据
private let demoCards = [
    DemoCard(title: "插件名", subtitle: "描述", icon: "star.fill", color: .purple, destination: .plugin),
    // ...
]

// 3. 添加导航
@ViewBuilder
private func destinationView(for card: DemoCard) -> some View {
    switch card.destination {
    case .plugin:
        PluginListView()
    // ...
    }
}
```

## 关键约定

| 层级 | 请求格式 | 响应格式 |
|------|---------|---------|
| watchOS → iOS | `["request": "getXXX"]` | - |
| iOS → Flutter | `invokeMethod("getWatchXXX")` | `[[String: Any]]` 或 `[String: Any]` |
| 统一响应 | - | `["success": Bool, "data": Any?, "error": String?]` |

## 注意事项

1. **使用同步方法**：Flutter 端优先使用 `xxxSync()` 方法获取数据，避免异步问题
2. **数据精简**：watchOS 屏幕小，只传输必要字段，长文本做截断
3. **错误处理**：每层都要有错误处理，返回用户友好的错误信息
4. **重新编译**：修改后需同时重新编译 Flutter 应用和 watchOS 应用
