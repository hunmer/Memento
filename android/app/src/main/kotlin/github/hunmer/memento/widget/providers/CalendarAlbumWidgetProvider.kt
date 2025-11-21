package github.hunmer.memento.widget.providers

import github.hunmer.memento.widget.BasePluginWidgetProvider

/**
 * 日记相册小组件 - 1x1 尺寸
 */
class CalendarAlbumWidgetProvider : BasePluginWidgetProvider() {
    override val pluginId: String = "calendar_album"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_1X1
}

/**
 * 日记相册小组件 - 2x2 尺寸
 */
class CalendarAlbumWidget2x1Provider : BasePluginWidgetProvider() {
    override val pluginId: String = "calendar_album"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_2X2
}
