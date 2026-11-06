import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/cart_item.dart';
import '../domain/models/order.dart';
import 'cart_provider.dart';
import 'preferences_provider.dart';

const _ordersKey = 'orders_v1';

List<Order> decodeOrders(Object? raw) {
  if (raw is! List) return const [];
  final orders = <Order>[];
  for (final entry in raw) {
    if (entry is! Map) continue;
    final id = entry['id'];
    final payment = entry['paymentMethod'];
    final placedAt = DateTime.tryParse('${entry['placedAt']}');
    final items = decodeCartItems(entry['items']);
    if (id is! String ||
        payment is! String ||
        placedAt == null ||
        items.isEmpty) {
      continue;
    }
    orders.add(
      Order(id: id, items: items, paymentMethod: payment, placedAt: placedAt),
    );
  }
  return orders;
}

/// Newest order first.
class OrdersNotifier extends Notifier<List<Order>> {
  @override
  List<Order> build() {
    final stored = ref.read(sharedPreferencesProvider).getString(_ordersKey);
    if (stored == null) return const [];
    try {
      return decodeOrders(jsonDecode(stored));
    } on FormatException {
      return const [];
    }
  }

  Order place({required List<CartItem> items, required String paymentMethod}) {
    final now = DateTime.now();
    final order = Order(
      id: 'NK${now.millisecondsSinceEpoch.toRadixString(36).toUpperCase()}',
      items: List.unmodifiable(items),
      paymentMethod: paymentMethod,
      placedAt: now,
    );
    state = [order, ...state];
    ref
        .read(sharedPreferencesProvider)
        .setString(
          _ordersKey,
          jsonEncode(state.map((e) => e.toJson()).toList()),
        );
    return order;
  }
}

final ordersProvider = NotifierProvider<OrdersNotifier, List<Order>>(
  OrdersNotifier.new,
);
