//
//  MyAppWidgetLiveActivity.swift
//  MyAppWidget
//
//  Created by liao on 2025/12/21.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct MyAppWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct MyAppWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MyAppWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension MyAppWidgetAttributes {
    fileprivate static var preview: MyAppWidgetAttributes {
        MyAppWidgetAttributes(name: "World")
    }
}

extension MyAppWidgetAttributes.ContentState {
    fileprivate static var smiley: MyAppWidgetAttributes.ContentState {
        MyAppWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: MyAppWidgetAttributes.ContentState {
         MyAppWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: MyAppWidgetAttributes.preview) {
   MyAppWidgetLiveActivity()
} contentStates: {
    MyAppWidgetAttributes.ContentState.smiley
    MyAppWidgetAttributes.ContentState.starEyes
}
