package github.hunmer.memento.widget.providers

import github.hunmer.memento.widget.BasePluginWidgetProvider

/**
 * 签到小组件 - 1x1 尺寸
 */
class CheckinWidgetProvider : BasePluginWidgetProvider() {
    override val pluginId: String = "checkin"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_1X1
}

/**
 * 签到小组件 - 2x1 尺寸
 */
class CheckinWidget2x1Provider : BasePluginWidgetProvider() {
    override val pluginId: String = "checkin"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_2X1
}
