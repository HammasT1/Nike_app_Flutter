// Renders the real app headlessly and saves PNG frames/stills used by the
// README (see tool/readme_media/build_media.sh). Not part of the normal test
// suite: run it explicitly.
//
//   MEDIA_OUT=/some/dir flutter test tool/readme_media/capture_test.dart
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nike_flutter/app.dart';
import 'package:nike_flutter/features/shop/application/preferences_provider.dart';
import 'package:nike_flutter/features/shop/data/shoes_data.dart';
import 'package:nike_flutter/features/shop/presentation/widgets/variant_selectors.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _frameStep = Duration(milliseconds: 50); // 20 fps in the GIFs
const _pixelRatio = 1.5;

final _boundaryKey = GlobalKey();
final _frameCounters = <String, int>{};

String get _out => Platform.environment['MEDIA_OUT'] ?? 'build/readme_media';

/// The test binding renders text with a blocky test font by default; load the
/// real Roboto that ships with the Flutter SDK so the output looks like the app.
Future<void> _loadRoboto() async {
  final root = Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.path;
  final dir = '$root/bin/cache/artifacts/material_fonts';
  final loader = FontLoader('Roboto');
  for (final name in [
    'Regular', 'Medium', 'Bold', 'Black', 'Italic', 'Light',
  ]) {
    final bytes = File('$dir/Roboto-$name.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();

  final icons = FontLoader('MaterialIcons')
    ..addFont(
      Future.value(
        ByteData.sublistView(File('$dir/MaterialIcons-Regular.otf').readAsBytesSync()),
      ),
    );
  await icons.load();
}

Future<void> _grab(WidgetTester tester, String path) async {
  await tester.runAsync(() async {
    final boundary =
        _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: _pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(data!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> _still(WidgetTester tester, String name) =>
    _grab(tester, '$_out/stills/$name.png');

/// Advances time in 50 ms steps, saving a frame after each step.
Future<void> _record(WidgetTester tester, String clip, int ms) async {
  final n = (ms / _frameStep.inMilliseconds).round();
  for (var i = 0; i < n; i++) {
    await tester.pump(_frameStep);
    final index = _frameCounters.update(clip, (v) => v + 1, ifAbsent: () => 0);
    await _grab(
      tester,
      '$_out/frames/$clip/${index.toString().padLeft(4, '0')}.png',
    );
  }
}

Future<void> _swipe(WidgetTester tester, String clip, Offset from, double dx) async {
  final gesture = await tester.startGesture(from);
  for (var i = 0; i < 6; i++) {
    await gesture.moveBy(Offset(dx / 6, 0));
    await _record(tester, clip, 50);
  }
  await gesture.up();
  await _record(tester, clip, 900);
}

Future<void> _tapAndRecord(
  WidgetTester tester,
  String clip,
  Finder finder,
  int ms,
) async {
  await tester.tap(finder.first);
  await _record(tester, clip, ms);
}

Future<void> _pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
}) async {
  tester.view.physicalSize = const Size(412, 892);
  tester.view.devicePixelRatio = 1.0;
  // Leave room where a phone's status bar and gesture bar would be.
  tester.view.padding = const FakeViewPadding(top: 30, bottom: 12);
  tester.view.viewPadding = const FakeViewPadding(top: 30, bottom: 12);
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(sp)],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    RepaintBoundary(
      key: _boundaryKey,
      child: UncontrolledProviderScope(
        container: container,
        child: const NikeApp(),
      ),
    ),
  );
  await tester.pump();

  // Decode every product image up front so frames never show empty boxes.
  await tester.runAsync(() async {
    final context = tester.element(find.byType(MaterialApp));
    for (final shoe in kShoes) {
      await precacheImage(AssetImage(shoe.imagePath), context);
    }
  });
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  setUpAll(_loadRoboto);

  testWidgets('shop carousel', (tester) async {
    await _pumpApp(tester);
    await _record(tester, 'carousel', 1200);
    await _still(tester, 'shop');
    await _still(tester, 'shoe_1');

    const from = Offset(300, 400);
    for (var i = 2; i <= 6; i++) {
      await _swipe(tester, 'carousel', from, -300);
      await _record(tester, 'carousel', 300);
      await _still(tester, 'shoe_$i');
    }
    // Back to the first shoe for a seamless loop.
    for (var i = 0; i < 5; i++) {
      await tester.drag(find.byType(PageView), const Offset(320, 0));
      await tester.pump(const Duration(milliseconds: 700));
    }
    await _record(tester, 'carousel', 400);
  });

  testWidgets('detail and add to cart', (tester) async {
    await _pumpApp(tester);
    await _record(tester, 'detail', 400);

    // Tap the card: spin, Hero + route transition.
    await _tapAndRecord(tester, 'detail', find.byKey(const ValueKey('1')), 1700);
    await _record(tester, 'detail', 600);

    // Adding without a size shows the validation message.
    await _tapAndRecord(
      tester,
      'detail',
      find.widgetWithText(FilledButton, 'Add To Cart'),
      900,
    );
    await _still(tester, 'detail_error');

    // Pick a colorway, then a size.
    final swatches = find.descendant(
      of: find.byType(ColorwaySelector),
      matching: find.byType(GestureDetector),
    );
    await tester.tap(swatches.at(1));
    await _record(tester, 'detail', 700);
    await tester.tap(swatches.at(2));
    await _record(tester, 'detail', 700);
    await tester.tap(
      find.descendant(of: find.byType(SizeSelector), matching: find.text('9')),
    );
    await _record(tester, 'detail', 800);
    await _still(tester, 'detail');

    // Add: shoe flies into the cart icon, page closes, badge pops.
    await tester.tap(find.widgetWithText(FilledButton, 'Add To Cart'));
    await _record(tester, 'detail', 2800);
    await _still(tester, 'shop_cart_badge');
    await _record(tester, 'detail', 400);
  });

  testWidgets('search, filter, sort', (tester) async {
    await _pumpApp(tester);
    await _record(tester, 'search', 500);

    for (final text in ['a', 'ai', 'air']) {
      await tester.enterText(find.byType(TextField), text);
      await _record(tester, 'search', 250);
    }
    await _record(tester, 'search', 800);
    await _still(tester, 'search');

    await tester.tap(find.byIcon(Icons.close));
    await _record(tester, 'search', 700);

    await _tapAndRecord(tester, 'search', find.text('Running'), 1100);
    await _still(tester, 'filter_running');

    await _tapAndRecord(tester, 'search', find.byIcon(Icons.swap_vert), 600);
    await _still(tester, 'sort_menu');
    await _tapAndRecord(
      tester,
      'search',
      find.text('Price: High to Low'),
      1400,
    );
    await _tapAndRecord(tester, 'search', find.text('All'), 1200);
  });

  testWidgets('favorites', (tester) async {
    await _pumpApp(tester);
    await _record(tester, 'favorites', 500);

    await _tapAndRecord(tester, 'favorites', find.byIcon(Icons.favorite_border), 900);
    await tester.drag(find.byType(PageView), const Offset(-320, 0));
    await _record(tester, 'favorites', 1000);
    await _tapAndRecord(tester, 'favorites', find.byIcon(Icons.favorite_border), 900);
    await _record(tester, 'favorites', 300);

    await _tapAndRecord(tester, 'favorites', find.text('Favorites').last, 900);
    await _still(tester, 'favorites');
    await _record(tester, 'favorites', 600);
  });

  testWidgets('cart, checkout, confirmation, orders', (tester) async {
    await _pumpApp(
      tester,
      prefs: {
        'cart_v1':
            '[{"shoeId":"1","size":9,"colorway":"Chicago Red","quantity":1},'
            '{"shoeId":"3","size":8,"colorway":"Volt","quantity":2}]',
      },
    );
    await _record(tester, 'checkout', 500);

    await _tapAndRecord(tester, 'checkout', find.byIcon(Icons.shopping_bag_outlined), 900);
    await _still(tester, 'cart');
    await _tapAndRecord(tester, 'checkout', find.byIcon(Icons.add_circle_outline), 500);
    await _record(tester, 'checkout', 400);

    await _tapAndRecord(tester, 'checkout', find.text('Checkout'), 1300);
    await _tapAndRecord(tester, 'checkout', find.text('Apple Pay'), 700);
    await _still(tester, 'checkout');
    await _tapAndRecord(tester, 'checkout', find.text('Checkout Now'), 2400);
    await _still(tester, 'confirmation');
    await _record(tester, 'checkout', 500);

    await _tapAndRecord(tester, 'checkout', find.text('View My Orders'), 1000);
    await _still(tester, 'orders_new');
    await _record(tester, 'checkout', 700);
  });

  testWidgets('orders with every status', (tester) async {
    final now = DateTime.now();
    String order(String id, Duration age, String shoeId, int size, String color) =>
        '{"id":"$id","paymentMethod":"Apple Pay","placedAt":"'
        '${now.subtract(age).toIso8601String()}","items":[{"shoeId":"$shoeId",'
        '"size":$size,"colorway":"$color","quantity":1}]}';

    await _pumpApp(
      tester,
      prefs: {
        'orders_v1':
            '[${order('NK8F2K1', const Duration(seconds: 20), '2', 10, 'Sky Blue')},'
            '${order('NK7B9XQ', const Duration(minutes: 2), '4', 8, 'Violet')},'
            '${order('NK41ZP0', const Duration(minutes: 30), '6', 9, 'Pitch Green')}]',
      },
    );
    await tester.tap(find.text('Orders').last);
    await tester.pump(const Duration(milliseconds: 900));
    await _still(tester, 'orders');
  });
}
