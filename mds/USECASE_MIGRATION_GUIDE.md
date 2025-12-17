# 插件 UseCase 迁移指南

> **面向 LLM 的技术文档** - 指导将客户端/服务端重复逻辑迁移到共享 UseCase 层

---

## 1. 架构概述

### 1.1 目标架构

```
shared_models/                     # 共享包
├── lib/
│   ├── repositories/
│   │   └── <plugin>/
│   │       └── <plugin>_repository.dart   # Repository 接口 + DTOs
│   ├── usecases/
│   │   └── <plugin>/
│   │       └── <plugin>_usecase.dart      # UseCase 业务逻辑
│   └── shared_models.dart                  # 导出文件

lib/plugins/<plugin>/              # Flutter 客户端
├── repositories/
│   └── client_<plugin>_repository.dart    # 客户端 Repository 实现

server/lib/                        # Dart 服务端
├── repositories/
│   └── server_<plugin>_repository.dart    # 服务端 Repository 实现
└── routes/plugin_routes/
    └── <plugin>_routes.dart               # HTTP 路由（使用 UseCase）
```

### 1.2 核心原则

| 原则 | 说明 |
|------|------|
| **单一数据源** | DTO 定义在 `shared_models` 中，客户端/服务端统一使用 |
| **接口隔离** | Repository 接口抽象数据访问，UseCase 封装业务逻辑 |
| **依赖倒置** | UseCase 依赖 Repository 接口，不依赖具体实现 |
| **参数标准化** | 所有 UseCase 方法接收 `Map<String, dynamic>` 参数 |

---

## 2. 迁移步骤

### 步骤 1: 分析现有代码

**检查服务端路由文件** (`server/lib/routes/plugin_routes/<plugin>_routes.dart`)：

```dart
// 识别以下模式：
// 1. API 端点列表
router.get('/items', _getItems);
router.post('/items', _createItem);

// 2. 数据结构（从处理方法中提取）
final item = {
  'id': itemId,
  'name': name,
  'createdAt': now,
  // ... 其他字段
};

// 3. 业务逻辑（验证、转换、查询）
if (name == null || name.isEmpty) {
  return _errorResponse(400, '缺少必需参数: name');
}
```

**生成字段清单**：

```markdown
## <Plugin> 数据模型分析

### 主实体: Item
| 字段 | 类型 | 必需 | 说明 |
|------|------|------|------|
| id | String | ✓ | UUID |
| name | String | ✓ | 名称 |
| createdAt | DateTime | ✓ | 创建时间 |
| updatedAt | DateTime | ✓ | 更新时间 |
| metadata | Map? | - | 扩展数据 |

### API 端点
- GET /items - 获取列表
- POST /items - 创建
- PUT /items/<id> - 更新
- DELETE /items/<id> - 删除
```

---

### 步骤 2: 创建 Repository 接口

**文件**: `shared_models/lib/repositories/<plugin>/<plugin>_repository.dart`

```dart
/// <Plugin> 插件 - Repository 接口定义

import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';

// ============ DTOs ============

/// 主实体 DTO
class ItemDto {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  const ItemDto({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  /// 从 JSON 构造
  factory ItemDto.fromJson(Map<String, dynamic> json) {
    return ItemDto(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// 复制并修改
  ItemDto copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return ItemDto(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

// ============ Query Objects ============

/// 查询参数对象
class ItemQuery {
  final String? field;
  final String? value;
  final bool fuzzy;
  final bool findAll;
  final PaginationParams? pagination;

  const ItemQuery({
    this.field,
    this.value,
    this.fuzzy = false,
    this.findAll = true,
    this.pagination,
  });
}

// ============ Repository Interface ============

/// <Plugin> Repository 接口
abstract class I<Plugin>Repository {
  /// 获取所有项目
  Future<Result<List<ItemDto>>> getItems({PaginationParams? pagination});

  /// 根据 ID 获取
  Future<Result<ItemDto?>> getItemById(String id);

  /// 创建
  Future<Result<ItemDto>> createItem(ItemDto item);

  /// 更新
  Future<Result<ItemDto>> updateItem(String id, ItemDto item);

  /// 删除
  Future<Result<bool>> deleteItem(String id);

  /// 搜索
  Future<Result<List<ItemDto>>> searchItems(ItemQuery query);
}
```

---

### 步骤 3: 创建 UseCase

**文件**: `shared_models/lib/usecases/<plugin>/<plugin>_usecase.dart`

```dart
/// <Plugin> 插件 - UseCase 业务逻辑层

import 'package:uuid/uuid.dart';
import 'package:shared_models/repositories/<plugin>/<plugin>_repository.dart';
import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';
import 'package:shared_models/utils/validation.dart';

/// <Plugin> UseCase - 封装所有业务逻辑
class <Plugin>UseCase {
  final I<Plugin>Repository repository;
  final Uuid _uuid = const Uuid();

  <Plugin>UseCase(this.repository);

  // ============ CRUD 操作 ============

  /// 获取列表
  ///
  /// [params] 可选参数:
  /// - `offset`: 起始偏移量
  /// - `count`: 返回数量
  Future<Result<dynamic>> getItems(Map<String, dynamic> params) async {
    try {
      final pagination = _extractPagination(params);
      final result = await repository.getItems(pagination: pagination);

      return result.map((items) {
        final jsonList = items.map((i) => i.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(
            jsonList,
            offset: pagination.offset,
            count: pagination.count,
          );
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('获取列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 根据 ID 获取
  Future<Result<Map<String, dynamic>?>> getItemById(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.getItemById(id);
      return result.map((item) => item?.toJson());
    } catch (e) {
      return Result.failure('获取失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 创建
  ///
  /// [params] 必需参数:
  /// - `name`: 名称
  Future<Result<Map<String, dynamic>>> createItem(
    Map<String, dynamic> params,
  ) async {
    // 参数验证
    final nameValidation = ParamValidator.requireString(params, 'name');
    if (!nameValidation.isValid) {
      return Result.failure(
        nameValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    try {
      final now = DateTime.now();
      final item = ItemDto(
        id: params['id'] as String? ?? _uuid.v4(),
        name: params['name'] as String,
        createdAt: now,
        updatedAt: now,
        metadata: params['metadata'] as Map<String, dynamic>?,
      );

      final result = await repository.createItem(item);
      return result.map((i) => i.toJson());
    } catch (e) {
      return Result.failure('创建失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 更新
  Future<Result<Map<String, dynamic>>> updateItem(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      // 获取现有数据
      final existingResult = await repository.getItemById(id);
      if (existingResult.isFailure) {
        return Result.failure('项目不存在', code: ErrorCodes.notFound);
      }

      final existing = existingResult.dataOrNull;
      if (existing == null) {
        return Result.failure('项目不存在', code: ErrorCodes.notFound);
      }

      // 合并更新
      final updated = existing.copyWith(
        name: params['name'] as String? ?? existing.name,
        metadata: params['metadata'] as Map<String, dynamic>? ?? existing.metadata,
        updatedAt: DateTime.now(),
      );

      final result = await repository.updateItem(id, updated);
      return result.map((i) => i.toJson());
    } catch (e) {
      return Result.failure('更新失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 删除
  Future<Result<bool>> deleteItem(Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      return repository.deleteItem(id);
    } catch (e) {
      return Result.failure('删除失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 辅助方法 ============

  PaginationParams? _extractPagination(Map<String, dynamic> params) {
    final offset = params['offset'] as int?;
    final count = params['count'] as int?;

    if (offset == null && count == null) return null;

    return PaginationParams(
      offset: offset ?? 0,
      count: count ?? 100,
    );
  }
}
```

---

### 步骤 4: 实现服务端 Repository

**文件**: `server/lib/repositories/server_<plugin>_repository.dart`

```dart
/// <Plugin> 插件 - 服务端 Repository 实现

import 'package:shared_models/shared_models.dart';
import '../services/plugin_data_service.dart';

class Server<Plugin>Repository implements I<Plugin>Repository {
  final PluginDataService dataService;
  final String userId;

  static const String _pluginId = '<plugin>';

  Server<Plugin>Repository({
    required this.dataService,
    required this.userId,
  });

  // ============ 内部方法 ============

  Future<List<ItemDto>> _readAllItems() async {
    final data = await dataService.readPluginData(
      userId,
      _pluginId,
      'items.json',
    );
    if (data == null) return [];

    final items = data['items'] as List<dynamic>? ?? [];
    return items.map((i) => ItemDto.fromJson(i as Map<String, dynamic>)).toList();
  }

  Future<void> _saveAllItems(List<ItemDto> items) async {
    await dataService.writePluginData(
      userId,
      _pluginId,
      'items.json',
      {'items': items.map((i) => i.toJson()).toList()},
    );
  }

  // ============ Repository 实现 ============

  @override
  Future<Result<List<ItemDto>>> getItems({PaginationParams? pagination}) async {
    try {
      var items = await _readAllItems();

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          items,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(items);
    } catch (e) {
      return Result.failure('获取列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<ItemDto?>> getItemById(String id) async {
    try {
      final items = await _readAllItems();
      final item = items.where((i) => i.id == id).firstOrNull;
      return Result.success(item);
    } catch (e) {
      return Result.failure('获取失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<ItemDto>> createItem(ItemDto item) async {
    try {
      final items = await _readAllItems();
      items.add(item);
      await _saveAllItems(items);
      return Result.success(item);
    } catch (e) {
      return Result.failure('创建失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<ItemDto>> updateItem(String id, ItemDto item) async {
    try {
      final items = await _readAllItems();
      final index = items.indexWhere((i) => i.id == id);

      if (index == -1) {
        return Result.failure('项目不存在', code: ErrorCodes.notFound);
      }

      items[index] = item;
      await _saveAllItems(items);
      return Result.success(item);
    } catch (e) {
      return Result.failure('更新失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteItem(String id) async {
    try {
      final items = await _readAllItems();
      final initialLength = items.length;
      items.removeWhere((i) => i.id == id);

      if (items.length == initialLength) {
        return Result.failure('项目不存在', code: ErrorCodes.notFound);
      }

      await _saveAllItems(items);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<ItemDto>>> searchItems(ItemQuery query) async {
    try {
      var items = await _readAllItems();

      if (query.field != null && query.value != null) {
        items = items.where((item) {
          final json = item.toJson();
          final fieldValue = json[query.field]?.toString() ?? '';
          if (query.fuzzy) {
            return fieldValue.toLowerCase().contains(query.value!.toLowerCase());
          }
          return fieldValue == query.value;
        }).toList();
      }

      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          items,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(items);
    } catch (e) {
      return Result.failure('搜索失败: $e', code: ErrorCodes.serverError);
    }
  }
}
```

---

### 步骤 5: 重构 HTTP 路由

**文件**: `server/lib/routes/plugin_routes/<plugin>_routes.dart`

```dart
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shared_models/shared_models.dart';

import '../../services/plugin_data_service.dart';
import '../../repositories/server_<plugin>_repository.dart';

/// <Plugin> 插件 HTTP 路由
class <Plugin>Routes {
  final PluginDataService _dataService;
  final Map<String, <Plugin>UseCase> _useCaseCache = {};

  <Plugin>Routes(this._dataService);

  <Plugin>UseCase _getUseCase(String userId) {
    return _useCaseCache.putIfAbsent(userId, () {
      final repository = Server<Plugin>Repository(
        dataService: _dataService,
        userId: userId,
      );
      return <Plugin>UseCase(repository);
    });
  }

  Router get router {
    final router = Router();

    router.get('/items', _getItems);
    router.get('/items/<id>', _getItem);
    router.post('/items', _createItem);
    router.put('/items/<id>', _updateItem);
    router.delete('/items/<id>', _deleteItem);

    return router;
  }

  // ============ 辅助方法 ============

  String? _getUserId(Request request) {
    return request.context['userId'] as String?;
  }

  Response _resultToResponse<T>(Result<T> result, {int successStatus = 200}) {
    if (result.isSuccess) {
      return Response(
        successStatus,
        body: jsonEncode({
          'success': true,
          'data': result.dataOrNull,
          'timestamp': DateTime.now().toIso8601String(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } else {
      final failure = result as Failure<T>;
      final statusCode = _errorCodeToStatus(failure.code);
      return Response(
        statusCode,
        body: jsonEncode({
          'success': false,
          'error': failure.message,
          'code': failure.code,
          'timestamp': DateTime.now().toIso8601String(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  int _errorCodeToStatus(String? code) {
    switch (code) {
      case ErrorCodes.notFound:
        return 404;
      case ErrorCodes.invalidParams:
        return 400;
      case ErrorCodes.unauthorized:
        return 401;
      case ErrorCodes.forbidden:
        return 403;
      default:
        return 500;
    }
  }

  Response _errorResponse(int statusCode, String message) {
    return Response(
      statusCode,
      body: jsonEncode({
        'success': false,
        'error': message,
        'timestamp': DateTime.now().toIso8601String(),
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  // ============ 路由处理 ============

  Future<Response> _getItems(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final params = <String, dynamic>{};
    final q = request.url.queryParameters;
    if (q['offset'] != null) params['offset'] = int.tryParse(q['offset']!) ?? 0;
    if (q['count'] != null) params['count'] = int.tryParse(q['count']!) ?? 100;

    final useCase = _getUseCase(userId);
    final result = await useCase.getItems(params);
    return _resultToResponse(result);
  }

  Future<Response> _getItem(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.getItemById({'id': id});
    return _resultToResponse(result);
  }

  Future<Response> _createItem(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;

      final useCase = _getUseCase(userId);
      final result = await useCase.createItem(params);
      return _resultToResponse(result, successStatus: 201);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  Future<Response> _updateItem(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final params = jsonDecode(body) as Map<String, dynamic>;
      params['id'] = id;

      final useCase = _getUseCase(userId);
      final result = await useCase.updateItem(params);
      return _resultToResponse(result);
    } catch (e) {
      return _errorResponse(400, '无效的请求体: $e');
    }
  }

  Future<Response> _deleteItem(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final useCase = _getUseCase(userId);
    final result = await useCase.deleteItem({'id': id});
    return _resultToResponse(result);
  }
}
```

---

### 步骤 6: 更新导出文件

**文件**: `shared_models/lib/shared_models.dart`

```dart
// 添加新的导出
export 'repositories/<plugin>/<plugin>_repository.dart';
export 'usecases/<plugin>/<plugin>_usecase.dart';
```

---

### 步骤 7: 验证

```bash
# 1. 分析 shared_models
dart analyze shared_models/lib/repositories/<plugin>/
dart analyze shared_models/lib/usecases/<plugin>/

# 2. 分析服务端
dart analyze server/lib/repositories/server_<plugin>_repository.dart
dart analyze server/lib/routes/plugin_routes/<plugin>_routes.dart

# 3. 运行测试（如果有）
dart test server/test/routes/<plugin>_routes_test.dart
```

---

## 3. 特殊场景处理

### 3.1 复杂查询

当插件需要复杂查询时（如日期范围、多条件过滤），创建专用 Query 类：

```dart
class ComplexQuery {
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String>? tags;
  final String? status;
  final PaginationParams? pagination;

  const ComplexQuery({
    this.startDate,
    this.endDate,
    this.tags,
    this.status,
    this.pagination,
  });
}
```

### 3.2 关联实体

当插件包含多个关联实体时（如 Bill 插件的 Account + Bill）：

```dart
// 分别定义 DTO
class AccountDto { ... }
class BillDto { ... }

// Repository 包含两组方法
abstract class IBillRepository {
  // 账户操作
  Future<Result<List<AccountDto>>> getAccounts(...);
  Future<Result<AccountDto>> createAccount(...);

  // 账单操作
  Future<Result<List<BillDto>>> getBills(...);
  Future<Result<BillDto>> createBill(...);
}
```

### 3.3 统计功能

为统计功能创建专用 DTO：

```dart
class StatsDto {
  final int total;
  final int active;
  final int archived;
  final Map<String, int> byCategory;

  Map<String, dynamic> toJson() => {
    'total': total,
    'active': active,
    'archived': archived,
    'byCategory': byCategory,
  };
}

// Repository 方法
Future<Result<StatsDto>> getStats({DateTime? startDate, DateTime? endDate});
```

### 3.4 客户端模型适配

当客户端已有模型定义不同于 DTO 时，在 ClientRepository 中进行转换：

```dart
class ClientRepository implements IRepository {
  // 客户端模型字段映射
  ItemDto _modelToDto(ClientItem model) {
    return ItemDto(
      id: model.id,
      name: model.title,  // 字段名不同
      createdAt: model.createTime,  // 类型可能不同
      ...
    );
  }

  ClientItem _dtoToModel(ItemDto dto) {
    return ClientItem(
      id: dto.id,
      title: dto.name,
      createTime: dto.createdAt,
      ...
    );
  }
}
```

---

## 4. 检查清单

### 迁移前检查

- [ ] 已分析现有服务端路由的所有 API 端点
- [ ] 已识别所有数据字段和类型
- [ ] 已确认 `shared_models` 包的 `pubspec.yaml` 包含必要依赖（uuid）
- [ ] 已确认服务端 `pubspec.yaml` 依赖 `shared_models`

### 创建文件检查

- [ ] `shared_models/lib/repositories/<plugin>/<plugin>_repository.dart`
  - [ ] DTO 类包含 `fromJson`、`toJson`、`copyWith` 方法
  - [ ] Query 类（如需要）
  - [ ] Repository 接口定义所有必要方法
- [ ] `shared_models/lib/usecases/<plugin>/<plugin>_usecase.dart`
  - [ ] 所有方法接收 `Map<String, dynamic>` 参数
  - [ ] 参数验证使用 `ParamValidator`
  - [ ] 错误处理使用 `Result.failure` 和 `ErrorCodes`
- [ ] `server/lib/repositories/server_<plugin>_repository.dart`
  - [ ] 实现 Repository 接口所有方法
  - [ ] 使用 `PluginDataService` 访问数据
- [ ] `server/lib/routes/plugin_routes/<plugin>_routes.dart`（重构）
  - [ ] 使用 UseCase 替代直接数据操作
  - [ ] 保持 API 端点不变

### 迁移后检查

- [ ] `shared_models/lib/shared_models.dart` 已更新导出
- [ ] `dart analyze` 无错误
- [ ] API 行为与迁移前一致（可通过测试验证）

---

## 5. 已迁移插件参考

| 插件 | Repository | UseCase | 服务端实现 | 路由重构 |
|------|------------|---------|-----------|---------|
| Chat | ✅ | ✅ | ✅ | ✅ |
| Notes | ✅ | ✅ | ✅ | ✅ |
| Todo | ✅ | ✅ | ✅ | ✅ |
| Bill | ✅ | ✅ | ✅ | ✅ |
| Activity | ✅ | ✅ | ✅ | ✅ |
| Goods | ✅ | ✅ | ✅ | ✅ |

---

## 6. 常见问题

### Q1: 如何处理可选的 folderId 更新？

当 `null` 是有效值时（如移动到根目录），使用 `containsKey` 检查：

```dart
final updated = existing.copyWith(
  folderId: params.containsKey('folderId')
      ? params['folderId'] as String?
      : existing.folderId,
);
```

### Q2: UseCase 方法应该返回什么类型？

- 列表查询：`Result<dynamic>`（可能返回分页对象或列表）
- 单个查询：`Result<Map<String, dynamic>?>`（可能不存在）
- 创建/更新：`Result<Map<String, dynamic>>`
- 删除：`Result<bool>`

### Q3: 如何处理客户端特有的字段？

在客户端 Repository 实现中处理，DTO 只包含通用字段。客户端特有字段可以放在 `metadata` 中。

---

**文档版本**: 1.0
**最后更新**: 2025-12-11
**适用于**: Memento 项目 shared_models 架构
