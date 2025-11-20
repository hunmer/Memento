package github.hunmer.memento.widget.providers

import github.hunmer.memento.widget.BasePluginWidgetProvider

/**
 * 习惯小组件 - 1x1 尺寸
 */
class HabitsWidgetProvider : BasePluginWidgetProvider() {
    override val pluginId: String = "habits"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_1X1
}

/**
 * 习惯小组件 - 2x1 尺寸
 */
class HabitsWidget2x1Provider : BasePluginWidgetProvider() {
    override val pluginId: String = "habits"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_2X1
}
