/// 全局标志变量
///
/// 用于在应用的不同模块之间共享状态标志
library;

/// 标记应用是否从小组件启动
/// 从小组件启动时，防止错误地自动打开最后使用的插件
bool isLaunchedFromWidget = false;
