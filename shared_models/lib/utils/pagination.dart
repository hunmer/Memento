/// 分页工具类 - 客户端和服务端共享
///
/// 此文件提供统一的分页逻辑，确保两端行为一致
library;

/// 分页响应结构
class PaginatedResult<T> {
  final List<T> data;
  final int total;
  final int offset;
  final int count;
  final bool hasMore;

  const PaginatedResult({
    required this.data,
    required this.total,
    required this.offset,
    required this.count,
    required this.hasMore,
  });

  Map<String, dynamic> toJson(Object? Function(T) toJsonT) {
    return {
      'data': data.map(toJsonT).toList(),
      'total': total,
      'offset': offset,
      'count': count,
      'hasMore': hasMore,
    };
  }

  /// 从 Map 直接创建（当 data 已经是 Map 列表时）
  Map<String, dynamic> toJsonMap() {
    return {
      'data': data,
      'total': total,
      'offset': offset,
      'count': count,
      'hasMore': hasMore,
    };
  }

  factory PaginatedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) {
    return PaginatedResult(
      data: (json['data'] as List).map(fromJsonT).toList(),
      total: json['total'] as int,
      offset: json['offset'] as int,
      count: json['count'] as int,
      hasMore: json['hasMore'] as bool,
    );
  }
}

/// 分页请求参数
class PaginationParams {
  final int offset;
  final int count;

  const PaginationParams({
    this.offset = 0,
    this.count = 100,
  });

  factory PaginationParams.fromMap(Map<String, dynamic> params) {
    return PaginationParams(
      offset: params['offset'] as int? ?? 0,
      count: params['count'] as int? ?? 100,
    );
  }

  /// 从查询参数创建（用于服务端）
  factory PaginationParams.fromQueryParams(Map<String, String> params) {
    return PaginationParams(
      offset: int.tryParse(params['offset'] ?? '') ?? 0,
      count: int.tryParse(params['count'] ?? '') ?? 100,
    );
  }

  bool get hasPagination => offset > 0 || count != 100;
}

/// 分页工具函数
class PaginationUtils {
  /// 对列表进行分页处理
  ///
  /// [list] 原始列表
  /// [offset] 起始偏移量
  /// [count] 每页数量
  static PaginatedResult<T> paginate<T>(
    List<T> list, {
    int offset = 0,
    int count = 100,
  }) {
    final total = list.length;
    final start = offset.clamp(0, total);
    final end = (start + count).clamp(start, total);
    final data = list.sublist(start, end);

    return PaginatedResult(
      data: data,
      total: total,
      offset: start,
      count: data.length,
      hasMore: end < total,
    );
  }

  /// 使用参数对象进行分页
  static PaginatedResult<T> paginateWithParams<T>(
    List<T> list,
    PaginationParams? params,
  ) {
    if (params == null) {
      return PaginatedResult(
        data: list,
        total: list.length,
        offset: 0,
        count: list.length,
        hasMore: false,
      );
    }
    return paginate(list, offset: params.offset, count: params.count);
  }

  /// 将分页结果转换为 Map（向后兼容旧格式）
  static Map<String, dynamic> toMap<T>(
    List<T> list, {
    int offset = 0,
    int count = 100,
    Object? Function(T)? toJson,
  }) {
    final result = paginate(list, offset: offset, count: count);
    final data =
        toJson != null ? result.data.map(toJson).toList() : result.data;

    return {
      'data': data,
      'total': result.total,
      'offset': result.offset,
      'count': result.count,
      'hasMore': result.hasMore,
    };
  }
}
