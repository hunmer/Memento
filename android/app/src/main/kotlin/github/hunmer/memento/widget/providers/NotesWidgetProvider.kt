package github.hunmer.memento.widget.providers

import github.hunmer.memento.widget.BasePluginWidgetProvider

/**
 * 笔记小组件 - 1x1 尺寸
 */
class NotesWidgetProvider : BasePluginWidgetProvider() {
    override val pluginId: String = "notes"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_1X1
}

/**
 * 笔记小组件 - 2x1 尺寸
 */
class NotesWidget2x1Provider : BasePluginWidgetProvider() {
    override val pluginId: String = "notes"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_2X1
}
