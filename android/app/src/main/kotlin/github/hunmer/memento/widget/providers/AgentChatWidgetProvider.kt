package github.hunmer.memento.widget.providers

import github.hunmer.memento.widget.BasePluginWidgetProvider

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
