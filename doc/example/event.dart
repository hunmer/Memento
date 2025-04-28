import 'package:Memento/core/event/event.dart';

void main() {
  // 注册事件处理器
  final subscriptionId = eventManager.subscribe('userLoggedIn', (args) {
    if (args is Value<String>) {
      print('User ${args.value} logged in at ${args.whenOccurred}');
    }
  });

  // 触发事件
  eventManager.broadcast('userLoggedIn', Value('John'));

  // 取消订阅
  eventManager.unsubscribe(subscriptionId);

  // 使用Stream方式订阅
  final stream = eventManager.asStream('dataChanged');
  final subscription = stream.listen((args) {
    print('Data changed: ${args.eventName}');
  });

  // 记得在不需要时取消Stream订阅
  subscription.cancel();
}