/// 管理器导出文件
///
/// 统一导出所有管理器，方便其他模块引用
library managers;

// 共享上下文
export 'shared/manager_context.dart';

// 管理器
export 'agent_manager.dart';
export 'foreground_service_manager.dart';
export 'tool_executor.dart';
export 'template_executor.dart';
export 'message_sender.dart';
export 'ai_request_handler.dart';
export 'agent_chain_executor.dart';
