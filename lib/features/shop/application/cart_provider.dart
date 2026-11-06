import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/shoes_data.dart';
import '../domain/models/cart_item.dart';
import '../domain/models/shoe.dart';
import 'preferences_provider.dart';

const _cartKey = 'cart_v1';

/// Decodes a stored cart, silently dropping anything that is no longer valid
/// (unknown shoe, size that no longer exists, bad quantity, corrupt JSON).
List<CartItem> decodeCartItems(Object? raw) {
  if (raw is! List) return const [];
  final items = <CartItem>[];
  for (final entry in raw) {
    if (entry is! Map) continue;
    final shoe = shoeById('${entry['shoeId']}');
    final size = entry['size'];
    final colorway = entry['colorway'];
    final quantity = entry['quantity'];
    if (shoe == null ||
        size is! int ||
        colorway is! String ||
        quantity is! int ||
        quantity < 1 ||
        !shoe.sizes.contains(size) ||
        !shoe.colorways.any((c) => c.name == colorway)) {
      continue;
    }
    items.add(
      CartItem(shoe: shoe, size: size, colorway: colorway, quantity: quantity),
    );
  }
  return items;
}

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() {
    final stored = ref.read(sharedPreferencesProvider).getString(_cartKey);
    if (stored == null) return const [];
    try {
      return decodeCartItems(jsonDecode(stored));
    } on FormatException {
      return const [];
    }
  }

  void _set(List<CartItem> items) {
    state = items;
    ref
        .read(sharedPreferencesProvider)
        .setString(_cartKey, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  void add(
    Shoe shoe, {
    required int size,
    required String colorway,
    int qty = 1,
  }) {
    final line = CartItem(
      shoe: shoe,
      size: size,
      colorway: colorway,
      quantity: qty,
    );
    final index = state.indexWhere((e) => e.key == line.key);
    if (index < 0) {
      _set([...state, line]);
    } else {
      _set([
        for (var i = 0; i < state.length; i++)
          if (i == index)
            state[i].copyWith(quantity: state[i].quantity + qty)
          else
            state[i],
      ]);
    }
  }

  void increment(String key) => _change(key, 1);

  void decrement(String key) => _change(key, -1);

  void _change(String key, int delta) {
    _set([
      for (final item in state)
        if (item.key == key)
          if (item.quantity + delta >= 1)
            item.copyWith(quantity: item.quantity + delta)
          else
            item
        else
          item,
    ]);
  }

  void remove(String key) => _set(state.where((e) => e.key != key).toList());

  void clear() => _set(const []);
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(
  CartNotifier.new,
);

final cartTotalProvider = Provider<double>(
  (ref) => ref.watch(cartProvider).fold(0, (sum, e) => sum + e.total),
);
