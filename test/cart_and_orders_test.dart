import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nike_flutter/features/shop/application/cart_provider.dart';
import 'package:nike_flutter/features/shop/application/orders_provider.dart';
import 'package:nike_flutter/features/shop/application/preferences_provider.dart';
import 'package:nike_flutter/features/shop/application/shop_filter_provider.dart';
import 'package:nike_flutter/features/shop/application/wishlist_provider.dart';
import 'package:nike_flutter/features/shop/data/shoes_data.dart';
import 'package:nike_flutter/features/shop/domain/models/order.dart';
import 'package:nike_flutter/features/shop/domain/models/shoe.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> makeContainer([
  Map<String, Object> initial = const {},
]) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  final shoe = kShoes.first;
  final colorway = shoe.colorways.first.name;

  group('cart', () {
    test('same shoe/size/color merges into one line', () async {
      final c = await makeContainer();
      final cart = c.read(cartProvider.notifier);
      cart.add(shoe, size: 9, colorway: colorway);
      cart.add(shoe, size: 9, colorway: colorway, qty: 2);

      final items = c.read(cartProvider);
      expect(items, hasLength(1));
      expect(items.single.quantity, 3);
    });

    test('different size or color is a separate line', () async {
      final c = await makeContainer();
      final cart = c.read(cartProvider.notifier);
      cart.add(shoe, size: 9, colorway: colorway);
      cart.add(shoe, size: 10, colorway: colorway);
      cart.add(shoe, size: 9, colorway: shoe.colorways.last.name);

      expect(c.read(cartProvider), hasLength(3));
    });

    test('increment, decrement (min 1), remove, total, clear', () async {
      final c = await makeContainer();
      final cart = c.read(cartProvider.notifier);
      cart.add(shoe, size: 9, colorway: colorway);
      final key = c.read(cartProvider).single.key;

      cart.increment(key);
      expect(c.read(cartProvider).single.quantity, 2);
      expect(c.read(cartTotalProvider), closeTo(shoe.price * 2, 0.001));

      cart.decrement(key);
      cart.decrement(key);
      expect(c.read(cartProvider).single.quantity, 1);

      cart.remove(key);
      expect(c.read(cartProvider), isEmpty);

      cart.add(shoe, size: 9, colorway: colorway);
      cart.clear();
      expect(c.read(cartProvider), isEmpty);
    });

    test('cart survives a restart', () async {
      final first = await makeContainer();
      first
          .read(cartProvider.notifier)
          .add(shoe, size: 8, colorway: colorway, qty: 2);
      final saved = (await SharedPreferences.getInstance()).getString(
        'cart_v1',
      )!;

      final second = await makeContainer({'cart_v1': saved});
      final items = second.read(cartProvider);
      expect(items.single.shoe.id, shoe.id);
      expect(items.single.size, 8);
      expect(items.single.quantity, 2);
    });

    test('corrupt or stale stored data is ignored', () async {
      final corrupt = await makeContainer({'cart_v1': '{not json'});
      expect(corrupt.read(cartProvider), isEmpty);

      final stale = await makeContainer({
        'cart_v1': jsonEncode([
          {'shoeId': 'gone', 'size': 9, 'colorway': 'x', 'quantity': 1},
          {'shoeId': shoe.id, 'size': 99, 'colorway': colorway, 'quantity': 1},
          {'shoeId': shoe.id, 'size': 9, 'colorway': colorway, 'quantity': 0},
          {'shoeId': shoe.id, 'size': 9, 'colorway': colorway, 'quantity': 1},
        ]),
      });
      expect(stale.read(cartProvider), hasLength(1));
    });
  });

  group('wishlist', () {
    test('toggle and persist', () async {
      final c = await makeContainer();
      final wishlist = c.read(wishlistProvider.notifier);
      wishlist.toggle('1');
      wishlist.toggle('2');
      wishlist.toggle('1');
      expect(c.read(wishlistProvider), {'2'});

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('wishlist_v1'), ['2']);
    });
  });

  group('orders', () {
    test('place stores newest first and persists', () async {
      final c = await makeContainer();
      final cart = c.read(cartProvider.notifier);
      cart.add(shoe, size: 9, colorway: colorway, qty: 2);
      final items = c.read(cartProvider);

      final orders = c.read(ordersProvider.notifier);
      final first = orders.place(items: items, paymentMethod: 'Apple Pay');
      final second = orders.place(items: items, paymentMethod: 'Easypaisa');

      expect(c.read(ordersProvider).map((o) => o.id), [second.id, first.id]);
      expect(first.total, closeTo(shoe.price * 2, 0.001));
      expect(first.itemCount, 2);

      final saved = (await SharedPreferences.getInstance()).getString(
        'orders_v1',
      )!;
      final restored = await makeContainer({'orders_v1': saved});
      expect(restored.read(ordersProvider), hasLength(2));
      expect(restored.read(ordersProvider).first.paymentMethod, 'Easypaisa');
    });

    test('status advances with the age of the order', () {
      final placed = DateTime(2026, 1, 1, 12);
      final order = Order(
        id: 'X',
        items: const [],
        paymentMethod: 'COD',
        placedAt: placed,
      );

      expect(order.statusAt(placed), OrderStatus.placed);
      expect(
        order.statusAt(placed.add(Order.kShippedAfter)),
        OrderStatus.shipped,
      );
      expect(
        order.statusAt(placed.add(Order.kDeliveredAfter)),
        OrderStatus.delivered,
      );
    });
  });

  group('search, filter and sort', () {
    test('category filter', () {
      final result = applyShoeFilter(
        kShoes,
        const ShoeFilter(category: ShoeCategory.running),
      );
      expect(result, isNotEmpty);
      expect(result.every((s) => s.category == ShoeCategory.running), isTrue);
    });

    test('search is case-insensitive and matches name', () {
      final result = applyShoeFilter(
        kShoes,
        const ShoeFilter(query: ' jORDAN '),
      );
      expect(result.map((s) => s.name), ['Air Jordan 1']);
    });

    test('search + category combine; no match gives empty', () {
      expect(
        applyShoeFilter(
          kShoes,
          const ShoeFilter(query: 'jordan', category: ShoeCategory.running),
        ),
        isEmpty,
      );
    });

    test('price sorting', () {
      final low = applyShoeFilter(
        kShoes,
        const ShoeFilter(sort: ShoeSort.priceLow),
      );
      final high = applyShoeFilter(
        kShoes,
        const ShoeFilter(sort: ShoeSort.priceHigh),
      );
      expect(
        low.first.price,
        kShoes.map((s) => s.price).reduce((a, b) => a < b ? a : b),
      );
      expect(
        high.first.price,
        kShoes.map((s) => s.price).reduce((a, b) => a > b ? a : b),
      );
    });

    test('does not mutate the source list', () {
      final before = kShoes.map((s) => s.id).toList();
      applyShoeFilter(kShoes, const ShoeFilter(sort: ShoeSort.priceHigh));
      expect(kShoes.map((s) => s.id).toList(), before);
    });
  });
}
