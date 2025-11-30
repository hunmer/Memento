package github.hunmer.memento.widgets.providers

import github.hunmer.memento.widgets.BasePluginWidgetProvider

/**
 * 习惯小组件 - 1x1 尺寸
 */
class HabitsWidgetProvider : BasePluginWidgetProvider() {
    override val pluginId: String = "habits"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_1X1
}

/**
 * 习惯小组件 - 2x2 尺寸
 */
class HabitsWidget2x1Provider : BasePluginWidgetProvider() {
    override val pluginId: String = "habits"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_2X2
}
