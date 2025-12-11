/// Iterable 扩展方法 - 客户端和服务端共享
///
/// 提供常用的 Iterable 操作扩展

/// Iterable 扩展
extension IterableExtensions<E> on Iterable<E> {
  /// 获取第一个元素，如果为空则返回 null
  ///
  /// 等价于: isEmpty ? null : first
  E? get firstOrNull => isEmpty ? null : first;

  /// 获取最后一个元素，如果为空则返回 null
  ///
  /// 等价于: isEmpty ? null : last
  E? get lastOrNull => isEmpty ? null : last;

  /// 查找第一个匹配的元素，如果未找到则返回 null
  ///
  /// [test] 匹配条件函数
  E? firstWhereOrNull(bool Function(E element) test) {
    for (final element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }

  /// 查找最后一个匹配的元素，如果未找到则返回 null
  ///
  /// [test] 匹配条件函数
  E? lastWhereOrNull(bool Function(E element) test) {
    E? result;
    for (final element in this) {
      if (test(element)) {
        result = element;
      }
    }
    return result;
  }

  /// 查找单个匹配的元素，如果未找到或找到多个则返回 null
  ///
  /// [test] 匹配条件函数
  E? singleWhereOrNull(bool Function(E element) test) {
    E? result;
    bool found = false;
    for (final element in this) {
      if (test(element)) {
        if (found) {
          // 找到多个匹配的，返回 null
          return null;
        }
        result = element;
        found = true;
      }
    }
    return result;
  }
}
