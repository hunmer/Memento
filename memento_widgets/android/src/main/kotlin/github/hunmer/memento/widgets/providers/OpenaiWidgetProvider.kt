package github.hunmer.memento.widgets.providers

import github.hunmer.memento.widgets.BasePluginWidgetProvider

/**
 * OpenAI小组件 - 1x1 尺寸
 */
class OpenaiWidgetProvider : BasePluginWidgetProvider() {
    override val pluginId: String = "openai"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_1X1
}

/**
 * OpenAI小组件 - 2x2 尺寸
 */
class OpenaiWidget2x1Provider : BasePluginWidgetProvider() {
    override val pluginId: String = "openai"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_2X2
}
