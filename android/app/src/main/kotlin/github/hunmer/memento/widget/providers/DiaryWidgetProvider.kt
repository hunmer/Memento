package github.hunmer.memento.widget.providers

import github.hunmer.memento.widget.BasePluginWidgetProvider

/**
 * 日记小组件 - 1x1 尺寸
 */
class DiaryWidgetProvider : BasePluginWidgetProvider() {
    override val pluginId: String = "diary"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_1X1
}

/**
 * 日记小组件 - 2x1 尺寸
 */
class DiaryWidget2x1Provider : BasePluginWidgetProvider() {
    override val pluginId: String = "diary"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_2X1
}
