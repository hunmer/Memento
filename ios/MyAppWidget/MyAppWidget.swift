//
//  MyAppWidget.swift
//  MyAppWidget
//
//  Created by liao on 2025/12/23.
//

import WidgetKit
import SwiftUI

@available(iOS 17.0, *)
struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, configuration: configuration)
            entries.append(entry)
        }

        return Timeline(entries: entries, policy: .atEnd)
    }

//    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

// iOS 16 兼容的简单 Provider - 不使用配置
@available(iOS 16.0, *)
struct SimpleProvider: TimelineProvider {
    typealias Entry = SimpleEntryV16

    func placeholder(in context: Context) -> SimpleEntryV16 {
        SimpleEntryV16(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntryV16) -> ()) {
        let entry = SimpleEntryV16(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntryV16>) -> ()) {
        var entries: [SimpleEntryV16] = []
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntryV16(date: entryDate)
            entries.append(entry)
        }
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

// iOS 16 版本的 Entry（不包含配置）
struct SimpleEntryV16: TimelineEntry {
    let date: Date
}

// iOS 17+ 版本的 Entry（包含配置）
@available(iOS 17.0, *)
struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
}

// iOS 17+ 视图（带配置）
@available(iOS 17.0, *)
struct MyAppWidgetEntryView : View {
    var entry: SimpleEntry

    var body: some View {
        VStack {
            Text("Time:")
            Text(entry.date, style: .time)

            Text("Favorite Emoji:")
            Text(entry.configuration.favoriteEmoji)
        }
    }
}

// iOS 16 视图（不带配置）
@available(iOS 16.0, *)
struct MyAppWidgetEntryViewV16 : View {
    var entry: SimpleEntryV16

    var body: some View {
        VStack {
            Text("Time:")
            Text(entry.date, style: .time)

            Text("Default Widget")
                .font(.caption)
        }
    }
}

struct MyAppWidget: Widget {
    let kind: String = "MyAppWidget"

    var body: some WidgetConfiguration {
        if #available(iOSApplicationExtension 17.0, *) {
            return AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
                MyAppWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            }
        } else {
            return StaticConfiguration(kind: kind, provider: SimpleProvider()) { entry in
                MyAppWidgetEntryViewV16(entry: entry)
                    .padding()
                    .background()
            }
        }
    }
}

@available(iOS 17.0, *)
extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }

    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "🤩"
        return intent
    }
}

@available(iOS 17.0, *)
#Preview(as: .systemSmall) {
    MyAppWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: .smiley)
    SimpleEntry(date: .now, configuration: .starEyes)
}
