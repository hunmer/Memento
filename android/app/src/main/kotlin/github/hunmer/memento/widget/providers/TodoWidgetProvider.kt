package github.hunmer.memento.widget.providers

import github.hunmer.memento.widget.BasePluginWidgetProvider

/**
 * 待办事项小组件 - 1x1 尺寸
 */
class TodoWidgetProvider : BasePluginWidgetProvider() {
    override val pluginId: String = "todo"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_1X1
}

/**
 * 待办事项小组件 - 2x1 尺寸
 */
class TodoWidget2x1Provider : BasePluginWidgetProvider() {
    override val pluginId: String = "todo"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_2X1
}
