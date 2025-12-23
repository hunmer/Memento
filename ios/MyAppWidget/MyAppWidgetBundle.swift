//
//  MyAppWidgetBundle.swift
//  MyAppWidget
//
//  Created by liao on 2025/12/23.
//

import WidgetKit
import SwiftUI

@main
struct MyAppWidgetBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        MyAppWidget()
        if #available(iOS 18.0, *) {
            MyAppWidgetControl()
        }
        MyAppWidgetLiveActivity()
    }
}
