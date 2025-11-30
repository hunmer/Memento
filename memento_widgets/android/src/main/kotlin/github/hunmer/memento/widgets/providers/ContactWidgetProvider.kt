package github.hunmer.memento.widgets.providers

import github.hunmer.memento.widgets.BasePluginWidgetProvider

/**
 * 联系人小组件 - 1x1 尺寸
 */
class ContactWidgetProvider : BasePluginWidgetProvider() {
    override val pluginId: String = "contact"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_1X1
}

/**
 * 联系人小组件 - 2x2 尺寸
 */
class ContactWidget2x1Provider : BasePluginWidgetProvider() {
    override val pluginId: String = "contact"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_2X2
}
