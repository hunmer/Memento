将 lib/core/app_widgets/floating_ball_service.dart:44~130 和 lib/core/floating_ball/floating_ball_manager.dart:54~133 合并到一个【动作管理器】

将floating_ball_manager的动作列表和floating_ball_service的方法注册到动作管理器，然后修改 lib/core/floating_ball/settings_screen.dart:138~157 的下拉选择动作改成使用 动作管理器 提供的【选择动作】对话框界面，展示已添加的列表和添加按钮，点击添加按钮展示对话框

注册动作示例:

```json
{
	"title": "打开插件",
	"action": "openPlugin",
	"form": {
		"pluginName": ["chat", "todo"],
	},
	// 验证器
}
```

然后在【选择动作】里使用添加按钮展示的对话框内的select选择打开插件，会在select下方展示 插件名称 的select,点击确定之后会返回 {”action”: “openPlugin”, “data”: {”pluginName”: “XXX”}}

添加的数据示例: 

```json
{
	"title": "自定义动作1",
	"actions": [
			{"action": "action1", "data": {...}},
			{"action": "action2", "data": {...}},
		]
}

```

然后修改应用内悬浮球的手势动作和overlay悬浮球的按钮动作，改成【添加的数据示例】那样的格式，可以支持运行多个actions