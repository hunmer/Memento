package github.hunmer.memento.widget.providers

import github.hunmer.memento.widget.BasePluginWidgetProvider

/**
 * 节点小组件 - 1x1 尺寸
 */
class NodesWidgetProvider : BasePluginWidgetProvider() {
    override val pluginId: String = "nodes"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_1X1
}

/**
 * 节点小组件 - 2x1 尺寸
 */
class NodesWidget2x1Provider : BasePluginWidgetProvider() {
    override val pluginId: String = "nodes"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_2X1
}
