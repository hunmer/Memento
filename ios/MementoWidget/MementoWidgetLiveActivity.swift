//
//  MementoWidgetLiveActivity.swift
//  MementoWidget
//
//  Created by Memento on $(DATE).
//

import ActivityKit
import WidgetKit
import SwiftUI

// ⚠️ 重要：ActivityAttributes 必须命名为 LiveActivitiesAppAttributes
struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
    public typealias LiveDeliveryData = ContentState

    public struct ContentState: Codable, Hashable {
        var title: String
        var subtitle: String
        var progress: Double
        var status: String
    }

    var id = UUID()
    var title: String
    var subtitle: String
    var icon: String
}

// 扩展以处理带前缀的键名
extension LiveActivitiesAppAttributes {
    func prefixedKey(_ key: String) -> String {
        return "\(id)_\(key)"
    }
}

struct MementoWidgetLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
            // 锁屏和动态岛视图
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.attributes.title)
                        .font(.headline)
                        .fontWeight(.bold)

                    Text(context.attributes.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    ProgressView(value: context.state.progress)
                        .progressViewStyle(LinearProgressViewStyle())

                    Text(context.state.status)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: context.attributes.icon)
                    .font(.title2)
            }
            .padding()
            .activitySystemActionForegroundColor(.accentColor)
            .activityBackgroundTint(Color.cyan.opacity(0.2))

        } dynamicIsland: { context in
            DynamicIsland {
                // 展开的动态岛布局
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.attributes.icon)
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }

                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.attributes.title)
                            .font(.headline)
                            .fontWeight(.bold)

                        Text(context.attributes.subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        ProgressView(value: context.state.progress)
                            .progressViewStyle(LinearProgressViewStyle())
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack {
                        Text(context.state.status)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            } compactLeading: {
                // 紧凑型左侧
                Image(systemName: context.attributes.icon)
            } compactTrailing: {
                // 紧凑型右侧
                Text("\(Int(context.state.progress * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
            } minimal: {
                // 最小化视图
                Image(systemName: context.attributes.icon)
            }
        }
    }
}
