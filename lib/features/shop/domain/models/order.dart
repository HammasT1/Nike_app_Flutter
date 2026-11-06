import 'cart_item.dart';

enum OrderStatus {
  placed('Placed'),
  shipped('Shipped'),
  delivered('Delivered');

  const OrderStatus(this.label);
  final String label;
}

class Order {
  final String id;
  final List<CartItem> items;
  final String paymentMethod;
  final DateTime placedAt;

  const Order({
    required this.id,
    required this.items,
    required this.paymentMethod,
    required this.placedAt,
  });

  double get total => items.fold(0, (sum, e) => sum + e.total);

  int get itemCount => items.fold(0, (sum, e) => sum + e.quantity);

  /// There is no backend, so the status is simulated from the order's age.
  OrderStatus statusAt(DateTime now) {
    final age = now.difference(placedAt);
    if (age < kShippedAfter) return OrderStatus.placed;
    if (age < kDeliveredAfter) return OrderStatus.shipped;
    return OrderStatus.delivered;
  }

  static const kShippedAfter = Duration(minutes: 1);
  static const kDeliveredAfter = Duration(minutes: 3);

  Map<String, dynamic> toJson() => {
    'id': id,
    'items': items.map((e) => e.toJson()).toList(),
    'paymentMethod': paymentMethod,
    'placedAt': placedAt.toIso8601String(),
  };
}
