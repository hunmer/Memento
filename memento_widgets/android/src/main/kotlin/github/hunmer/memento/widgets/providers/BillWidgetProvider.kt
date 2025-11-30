package github.hunmer.memento.widgets.providers

import github.hunmer.memento.widgets.BasePluginWidgetProvider

/**
 * 账单小组件 - 1x1 尺寸
 */
class BillWidgetProvider : BasePluginWidgetProvider() {
    override val pluginId: String = "bill"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_1X1
}

/**
 * 账单小组件 - 2x2 尺寸
 */
class BillWidget2x1Provider : BasePluginWidgetProvider() {
    override val pluginId: String = "bill"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_2X2
}
