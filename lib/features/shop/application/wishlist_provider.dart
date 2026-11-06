import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'preferences_provider.dart';

const _wishlistKey = 'wishlist_v1';

class WishlistNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() =>
      (ref.read(sharedPreferencesProvider).getStringList(_wishlistKey) ??
              const <String>[])
          .toSet();

  void toggle(String shoeId) {
    final next = {...state};
    if (!next.remove(shoeId)) next.add(shoeId);
    state = next;
    ref
        .read(sharedPreferencesProvider)
        .setStringList(_wishlistKey, next.toList());
  }
}

final wishlistProvider = NotifierProvider<WishlistNotifier, Set<String>>(
  WishlistNotifier.new,
);
