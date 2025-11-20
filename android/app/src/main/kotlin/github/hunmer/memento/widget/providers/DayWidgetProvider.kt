package github.hunmer.memento.widget.providers

import github.hunmer.memento.widget.BasePluginWidgetProvider

/**
 * 纪念日小组件 - 1x1 尺寸
 */
class DayWidgetProvider : BasePluginWidgetProvider() {
    override val pluginId: String = "day"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_1X1
}

/**
 * 纪念日小组件 - 2x1 尺寸
 */
class DayWidget2x1Provider : BasePluginWidgetProvider() {
    override val pluginId: String = "day"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_2X1
}
