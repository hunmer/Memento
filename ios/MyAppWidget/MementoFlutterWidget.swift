//
//  MementoFlutterWidget.swift
//  MyAppWidget
//
//  iOS 桌面小组件 - 显示 Flutter 渲染的小组件内容
//  支持三种尺寸：small (1x1), wide (4x1), large (2x2)
//

import WidgetKit
import SwiftUI
import UIKit

// MARK: - Timeline Entry

/// 小组件时间线条目
struct MementoWidgetEntry: TimelineEntry {
    let date: Date
    let imageData: Data?
    let widgetKind: String
    let isConfigured: Bool
}

// MARK: - Timeline Provider

/// iOS 16 兼容的 Timeline Provider
struct MementoWidgetProvider: TimelineProvider {
    typealias Entry = MementoWidgetEntry

    let widgetKind: String

    func placeholder(in context: Context) -> MementoWidgetEntry {
        MementoWidgetEntry(
            date: Date(),
            imageData: nil,
            widgetKind: widgetKind,
            isConfigured: false
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MementoWidgetEntry) -> Void) {
        let entry = loadEntry(widgetKind: widgetKind)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MementoWidgetEntry>) -> Void) {
        let entry = loadEntry(widgetKind: widgetKind)

        // 每小时更新一次
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

        completion(timeline)
    }

    /// 从 App Group 加载小组件数据
    private func loadEntry(widgetKind: String) -> MementoWidgetEntry {
        let defaults = UserDefaults(suiteName: "group.github.hunmer.memento")

        // 加载配置
        let configKey = "ios_widget_config_memento_widget_\(widgetKind)"
        let configJson = defaults?.string(forKey: configKey)

        // 检查是否已配置
        let isConfigured = configJson != nil && !configJson!.isEmpty

        // 加载图片
        let imageKey = "ios_widget_image_\(widgetKind)"
        let imageData = defaults?.data(forKey: imageKey)

        return MementoWidgetEntry(
            date: Date(),
            imageData: imageData,
            widgetKind: widgetKind,
            isConfigured: isConfigured
        )
    }
}

// MARK: - Widget View

/// 小组件视图
struct MementoWidgetEntryView: View {
    var entry: MementoWidgetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if entry.isConfigured, let imageData = entry.imageData, let uiImage = UIImage(data: imageData) {
            // 已配置状态 - 显示渲染的图片
            GeometryReader { geometry in
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            }
            .widgetURL(URL(string: "memento://ios_widget_config_\(entry.widgetKind)"))
        } else {
            // 未配置状态 - 显示配置提示
            unconfiguredView
                .widgetURL(URL(string: "memento://ios_widget_config_\(entry.widgetKind)"))
        }
        .containerBackground(Color(UIColor.systemBackground), for: .widget)
    }

    /// 未配置状态的视图
    @ViewBuilder
    private var unconfiguredView: some View {
        VStack(spacing: 12) {
            Image(systemName: "plus.square")
                .font(.system(size: 40))
                .foregroundColor(.accentColor)

            Text("点击配置")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Memento")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Widget Definitions

/// 小组件 - Small 尺寸 (1x1)
struct MementoFlutterSmallWidget: Widget {
    let kind: String = "memento_widget_small"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MementoWidgetProvider(widgetKind: "small")) { entry in
            MementoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Memento 小组件")
        .description("在桌面上显示 Memento 小组件内容")
        .supportedFamilies([.systemSmall])
    }
}

/// 小组件 - Wide 尺寸 (4x1, systemMedium)
struct MementoFlutterWideWidget: Widget {
    let kind: String = "memento_widget_wide"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MementoWidgetProvider(widgetKind: "wide")) { entry in
            MementoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Memento 宽组件")
        .description("在桌面上显示 Memento 宽组件内容")
        .supportedFamilies([.systemMedium])
    }
}

/// 小组件 - Large 尺寸 (2x2, systemLarge)
struct MementoFlutterLargeWidget: Widget {
    let kind: String = "memento_widget_large"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MementoWidgetProvider(widgetKind: "large")) { entry in
            MementoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Memento 大组件")
        .description("在桌面上显示 Memento 大组件内容")
        .supportedFamilies([.systemLarge])
    }
}
