//
//  AppIntent.swift
//  MyAppWidget
//
//  Created by liao on 2025/12/23.
//

import WidgetKit
import AppIntents

// 仅在 iOS 17+ 支持 WidgetConfigurationIntent
@available(iOSApplicationExtension 17.0, macOSApplicationExtension 14.0, *)
struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "This is an example widget." }

    // An example configurable parameter.
    @Parameter(title: "Favorite Emoji", default: "😃")
    var favoriteEmoji: String
}
