/// Memento 共享数据模型库
///
/// 此库包含客户端和服务器共用的：
/// - 数据模型
/// - Repository 抽象接口
/// - UseCase 业务逻辑层
/// - 通用工具类
library shared_models;

// ============ 核心工具 ============

// 分页工具
export 'utils/pagination.dart';

// 参数验证
export 'utils/validation.dart';

// 统一结果类型
export 'utils/result.dart';

// MD5 工具
export 'utils/md5_utils.dart';

// ============ Repository 层 ============

// Chat 插件 Repository
export 'repositories/chat/chat_repository.dart';

// ============ UseCase 层 ============

// Chat 插件 UseCase
export 'usecases/chat/chat_usecase.dart';

// ============ 同步相关 ============

export 'sync/sync_request.dart';
export 'sync/sync_response.dart';

// ============ 认证相关 ============

export 'auth/auth_models.dart';

// ============ 数据模型 ============
// 以下由 copy_models.dart 自动更新，当前为占位注释
// 实际模型需要运行 copy_models.dart 后取消注释

// export 'models/account.dart';
// export 'models/bill.dart';
// export 'models/channel.dart';
// export 'models/checkin_item.dart';
// export 'models/contact.dart';
// export 'models/diary_entry.dart';
// export 'models/event.dart';
// export 'models/folder.dart';
// export 'models/goal.dart';
// export 'models/goods_item.dart';
// export 'models/habit.dart';
// export 'models/memorial_day.dart';
// export 'models/message.dart';
// export 'models/note.dart';
// export 'models/record.dart';
// export 'models/task.dart';
// export 'models/user.dart';
