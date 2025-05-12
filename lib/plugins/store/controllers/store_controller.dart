
import '../models/product.dart';
import '../models/user_item.dart';
import '../models/points_log.dart';

class StoreController {
  List<Product> _products = [];
  List<UserItem> _userItems = [];
  List<PointsLog> _pointsLogs = [];
  int _userPoints = 0;

  // 获取商品列表
  List<Product> get products => _products;

  // 获取用户物品
  List<UserItem> get userItems => _userItems;

  // 获取积分记录
  List<PointsLog> get pointsLogs => _pointsLogs;

  // 获取用户积分
  int get userPoints => _userPoints;

  // 添加商品
  void addProduct(Product product) {
    _products.add(product);
  }

  // 兑换商品
  bool exchangeProduct(Product product) {
    // 校验积分和库存
    if (_userPoints < product.price) return false;
    if (product.stock <= 0) return false;
    if (DateTime.now().isBefore(product.exchangeStart) || 
        DateTime.now().isAfter(product.exchangeEnd)) {
      return false;
    }

    // 执行兑换
    _userPoints -= product.price;
    final index = _products.indexOf(product);
    _products[index] = Product(
      id: product.id,
      name: product.name,
      description: product.description,
      image: product.image,
      stock: product.stock - 1,
      price: product.price,
      exchangeStart: product.exchangeStart,
      exchangeEnd: product.exchangeEnd,
      useDuration: product.useDuration,
    );

    // 添加用户物品
    _userItems.add(UserItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      productId: product.id,
      remaining: 1,
      expireDate: DateTime.now().add(Duration(days: product.useDuration)),
    ));

    // 添加积分记录
    _pointsLogs.add(PointsLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: '消耗',
      value: product.price,
      reason: '兑换商品: ${product.name}',
      timestamp: DateTime.now(),
    ));

    return true;
  }

  // 使用物品
  bool useItem(UserItem item) {
    if (DateTime.now().isAfter(item.expireDate)) return false;
    
    item.use();
    if (item.remaining <= 0) {
      _userItems.remove(item);
    }
    return true;
  }

  // 添加积分
  void addPoints(int value, String reason) {
    _userPoints += value;
    _pointsLogs.add(PointsLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: '获得',
      value: value,
      reason: reason,
      timestamp: DateTime.now(),
    ));
  }

  // 排序商品
  void sortProducts(String field, {bool ascending = true}) {
    _products.sort((a, b) {
      int compareResult;
      switch (field) {
        case 'stock':
          compareResult = a.stock.compareTo(b.stock);
          break;
        case 'price':
          compareResult = a.price.compareTo(b.price);
          break;
        case 'exchangeEnd':
          compareResult = a.exchangeEnd.compareTo(b.exchangeEnd);
          break;
        default:
          compareResult = 0;
      }
      return ascending ? compareResult : -compareResult;
    });
  }

  // 排序用户物品
  void sortUserItems(String field, {bool ascending = true}) {
    _userItems.sort((a, b) {
      int compareResult;
      switch (field) {
        case 'remaining':
          compareResult = a.remaining.compareTo(b.remaining);
          break;
        case 'expireDate':
          compareResult = a.expireDate.compareTo(b.expireDate);
          break;
        default:
          compareResult = 0;
      }
      return ascending ? compareResult : -compareResult;
    });
  }
}
