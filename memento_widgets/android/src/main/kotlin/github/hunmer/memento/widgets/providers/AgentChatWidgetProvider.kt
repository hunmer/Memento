package github.hunmer.memento.widgets.providers

import github.hunmer.memento.widgets.BasePluginWidgetProvider

/**
 * AI对话小组件 - 1x1 尺寸
 */
class AgentChatWidgetProvider : BasePluginWidgetProvider() {
    override val pluginId: String = "agent_chat"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_1X1
}

/**
 * AI对话小组件 - 2x2 尺寸
 */
class AgentChatWidget2x1Provider : BasePluginWidgetProvider() {
    override val pluginId: String = "agent_chat"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_2X2
}
