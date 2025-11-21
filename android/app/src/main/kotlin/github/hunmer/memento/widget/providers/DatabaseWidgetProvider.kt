package github.hunmer.memento.widget.providers

import github.hunmer.memento.widget.BasePluginWidgetProvider

/**
 * 数据库小组件 - 1x1 尺寸
 */
class DatabaseWidgetProvider : BasePluginWidgetProvider() {
    override val pluginId: String = "database"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_1X1
}

/**
 * 数据库小组件 - 2x2 尺寸
 */
class DatabaseWidget2x1Provider : BasePluginWidgetProvider() {
    override val pluginId: String = "database"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_2X2
}
