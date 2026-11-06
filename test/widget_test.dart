import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nike_flutter/app.dart';
import 'package:nike_flutter/features/shop/application/cart_provider.dart';
import 'package:nike_flutter/features/shop/application/orders_provider.dart';
import 'package:nike_flutter/features/shop/application/preferences_provider.dart';
import 'package:nike_flutter/features/shop/application/wishlist_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The shop has looping animations, so `pumpAndSettle` would never finish.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 25; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  Size size = const Size(412, 892),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(sp)],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const NikeApp()),
  );
  await settle(tester);
  return container;
}

void main() {
  testWidgets('shop renders with search, categories and nav', (tester) async {
    await pumpApp(tester);

    expect(find.text('Nike Shop'), findsOneWidget);
    expect(find.text('Search shoes'), findsOneWidget);
    expect(find.text('Running'), findsOneWidget);
    expect(find.text('Air Jordan 1'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
  });

  testWidgets('searching filters the carousel and shows the empty state', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.enterText(find.byType(TextField), 'cortez');
    await settle(tester);
    expect(find.text('Nike Cortez'), findsOneWidget);
    expect(find.text('Air Jordan 1'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzzz');
    await settle(tester);
    expect(find.text('No shoes found'), findsOneWidget);

    await tester.tap(find.text('Clear filters'));
    await settle(tester);
    expect(find.text('Air Jordan 1'), findsOneWidget);
  });

  testWidgets('category chip filters shoes', (tester) async {
    await pumpApp(tester);

    await tester.scrollUntilVisible(
      find.text('Football'),
      100,
      scrollable: find
          .ancestor(of: find.text('Running'), matching: find.byType(Scrollable))
          .first,
    );
    await tester.ensureVisible(find.text('Football'));
    await tester.pump();
    await tester.tap(find.text('Football'));
    await settle(tester);
    expect(find.text('Nike Phantom'), findsOneWidget);
    expect(find.text('Air Jordan 1'), findsNothing);
  });

  testWidgets('quick add requires a size, then updates cart badge', (
    tester,
  ) async {
    final container = await pumpApp(tester);

    await tester.tap(find.text('Add To Cart'));
    await settle(tester);

    // Button is disabled until a size is picked.
    expect(find.text('Select a size'), findsOneWidget);
    await tester.tap(find.text('8'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Add To Cart').last);
    await settle(tester);
    await tester.pump(const Duration(seconds: 2));

    final cart = container.read(cartProvider);
    expect(cart, hasLength(1));
    expect(cart.single.size, 8);
    expect(find.text('1'), findsWidgets); // badge
  });

  testWidgets('detail page: size is required, favorite toggles', (
    tester,
  ) async {
    final container = await pumpApp(tester);

    await tester.tap(find.text('Tap to open').first);
    await settle(tester);

    await tester.tap(find.text('Add To Cart'));
    await settle(tester);
    expect(find.text('Please select a size'), findsOneWidget);
    expect(container.read(cartProvider), isEmpty);

    await tester.tap(find.byIcon(Icons.favorite_border).last);
    await settle(tester);
    expect(container.read(wishlistProvider), {'1'});
  });

  testWidgets('full flow: cart checkout creates an order and empties cart', (
    tester,
  ) async {
    final container = await pumpApp(
      tester,
      prefs: {
        'cart_v1':
            '[{"shoeId":"1","size":9,"colorway":"Chicago Red","quantity":2}]',
      },
    );
    expect(container.read(cartProvider), hasLength(1));

    await tester.tap(find.byIcon(Icons.shopping_bag_outlined));
    await settle(tester);
    expect(find.textContaining('Size 9'), findsOneWidget);

    await tester.tap(find.text('Checkout'));
    await settle(tester);
    await tester.tap(find.text('Checkout Now'));
    await tester.pump(const Duration(milliseconds: 400));
    // The button turns into a "Processing" state before the order is placed.
    expect(find.text('Processing...'), findsOneWidget);
    expect(container.read(ordersProvider), isEmpty);
    await settle(tester);

    expect(find.text('Order Placed!'), findsOneWidget);
    expect(find.text('Print / Save Receipt (PDF)'), findsOneWidget);
    expect(container.read(cartProvider), isEmpty);
    expect(container.read(ordersProvider), hasLength(1));

    await tester.tap(find.text('View My Orders'));
    await settle(tester);
    expect(find.text('My Orders'), findsOneWidget);
    expect(find.text('Placed'), findsOneWidget);
    expect(find.text('Receipt'), findsOneWidget);
    expect(find.textContaining('Size 9'), findsOneWidget);
  });

  testWidgets('favorites tab lists saved shoes', (tester) async {
    await pumpApp(
      tester,
      prefs: {
        'wishlist_v1': ['3'],
      },
    );

    await tester.tap(find.text('Favorites').last);
    await settle(tester);
    expect(find.text('Nike Air Max'), findsOneWidget);
  });

  testWidgets('empty favorites and orders show placeholders', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Favorites').last);
    await settle(tester);
    expect(find.text('No favorites yet'), findsOneWidget);

    await tester.tap(find.text('Orders').last);
    await settle(tester);
    expect(find.text('No orders yet'), findsOneWidget);
  });

  testWidgets('small phone: shop and detail lay out without overflow', (
    tester,
  ) async {
    await pumpApp(tester, size: const Size(360, 640));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Tap to open').first);
    await settle(tester);
    expect(find.text('Size (US)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving checkout while processing does not place the order', (
    tester,
  ) async {
    final container = await pumpApp(
      tester,
      prefs: {
        'cart_v1':
            '[{"shoeId":"1","size":9,"colorway":"Chicago Red","quantity":1}]',
      },
    );
    await tester.tap(find.byIcon(Icons.shopping_bag_outlined));
    await settle(tester);
    await tester.tap(find.text('Checkout'));
    await settle(tester);
    await tester.tap(find.text('Checkout Now'));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.pageBack();
    await settle(tester);

    expect(container.read(ordersProvider), isEmpty);
    expect(container.read(cartProvider), hasLength(1));
  });

  testWidgets(
    'small phone: checkout and confirmation lay out without overflow',
    (tester) async {
      await pumpApp(
        tester,
        size: const Size(360, 640),
        prefs: {
          'cart_v1':
              '[{"shoeId":"1","size":9,"colorway":"Chicago Red","quantity":1},'
              '{"shoeId":"3","size":8,"colorway":"Volt","quantity":2},'
              '{"shoeId":"6","size":10,"colorway":"Blackout","quantity":1}]',
        },
      );
      await tester.tap(find.byIcon(Icons.shopping_bag_outlined));
      await settle(tester);
      await tester.tap(find.text('Checkout'));
      await settle(tester);
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(find.text('Checkout Now'), 200);
      await tester.tap(find.text('Checkout Now'));
      await settle(tester);
      await settle(tester);
      expect(find.text('Order Placed!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
