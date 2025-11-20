package github.hunmer.memento.widget.providers

import github.hunmer.memento.widget.BasePluginWidgetProvider

/**
 * 商店小组件 - 1x1 尺寸
 */
class StoreWidgetProvider : BasePluginWidgetProvider() {
    override val pluginId: String = "store"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_1X1
}

/**
 * 商店小组件 - 2x1 尺寸
 */
class StoreWidget2x1Provider : BasePluginWidgetProvider() {
    override val pluginId: String = "store"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_2X1
}
