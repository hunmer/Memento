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
    var body: some Widget {
        MyAppWidget()
        MyAppWidgetControl()
        MyAppWidgetLiveActivity()
    }
}
