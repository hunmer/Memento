package github.hunmer.memento.widgets.providers

import github.hunmer.memento.widgets.BasePluginWidgetProvider

/**
 * 聊天小组件 - 1x1 尺寸
 */
class ChatWidgetProvider : BasePluginWidgetProvider() {
    override val pluginId: String = "chat"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_1X1
}

/**
 * 聊天小组件 - 2x2 尺寸
 */
class ChatWidget2x1Provider : BasePluginWidgetProvider() {
    override val pluginId: String = "chat"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_2X2
}
