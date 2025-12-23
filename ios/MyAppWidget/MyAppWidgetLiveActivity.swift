//
//  MyAppWidgetLiveActivity.swift
//  MyAppWidget
//
//  Created by liao on 2025/12/23.
//

import ActivityKit
import WidgetKit
import SwiftUI

// Create shared default with custom group
let sharedDefault = UserDefaults(suiteName: "group.github.hunmer.memento")!

struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
    public typealias LiveDeliveryData = ContentState // don't forget to add this line, otherwise, live activity will not display it.

    public struct ContentState: Codable, Hashable { }

    // Fixed non-changing properties about your activity go here!
    var id = UUID()
}

@available(iOSApplicationExtension 16.1, *)
struct MyAppWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
            // 从 UserDefaults 读取数据
            let title = sharedDefault.string(forKey: context.attributes.prefixedKey("title")) ?? "未知任务"
            let subtitle = sharedDefault.string(forKey: context.attributes.prefixedKey("subtitle")) ?? ""
            let progress = sharedDefault.double(forKey: context.attributes.prefixedKey("progress"))
            let status = sharedDefault.string(forKey: context.attributes.prefixedKey("status")) ?? ""

            // Lock screen/banner UI goes here
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(status)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    ProgressView(value: progress)
                        .tint(.blue)
                }
            }
            .padding()
            .activityBackgroundTint(Color.cyan.opacity(0.2))
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            // 从 UserDefaults 读取数据
            let title = sharedDefault.string(forKey: context.attributes.prefixedKey("title")) ?? "未知任务"
            let progress = sharedDefault.double(forKey: context.attributes.prefixedKey("progress"))

            return DynamicIsland {
                // Expanded UI goes here
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "app.badge")
                        .foregroundColor(.blue)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 4) {
                        Text(title)
                            .font(.caption)
                        ProgressView(value: progress)
                            .tint(.blue)
                    }
                }
            } compactLeading: {
                Image(systemName: "app.badge")
            } compactTrailing: {
                let progress = sharedDefault.double(forKey: context.attributes.prefixedKey("progress"))
                Text("\(Int(progress * 100))%")
                    .font(.caption2)
            } minimal: {
                Image(systemName: "app.badge")
            }
            .widgetURL(URL(string: "memento://live-activity"))
            .keylineTint(Color.blue)
        }
    }
}

// Extension to handle prefixed keys
extension LiveActivitiesAppAttributes {
    func prefixedKey(_ key: String) -> String {
        return "\(id)_\(key)"
    }
}

extension LiveActivitiesAppAttributes {
    fileprivate static var preview: LiveActivitiesAppAttributes {
        LiveActivitiesAppAttributes()
    }
}

extension LiveActivitiesAppAttributes.ContentState {
    fileprivate static var inProgress: LiveActivitiesAppAttributes.ContentState {
        LiveActivitiesAppAttributes.ContentState()
     }

     fileprivate static var completed: LiveActivitiesAppAttributes.ContentState {
         LiveActivitiesAppAttributes.ContentState()
     }
}

@available(iOS 17.0, *)
#Preview("Notification", as: .content, using: LiveActivitiesAppAttributes.preview) {
   MyAppWidgetLiveActivity()
} contentStates: {
    LiveActivitiesAppAttributes.ContentState.inProgress
    LiveActivitiesAppAttributes.ContentState.completed
}
