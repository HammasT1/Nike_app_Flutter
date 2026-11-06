# Nike Shop (Flutter)

A Nike-style shoe shopping app built with Flutter. Browse a shoe carousel, pick a
size and colorway, save favorites, check out, and track your orders. Cart,
favorites and orders are saved on the device and survive an app restart.

## Features

- **Shop carousel** with animated shoe cards, a fly-to-cart animation and a cart badge.
- **Search, category filters and sorting**
  - Search by name, description or category.
  - Filter by Running, Lifestyle, Basketball or Football.
  - Sort by price (low/high) or name. Search, category and sort combine.
  - An empty state with a "Clear filters" button appears when nothing matches.
- **Size and color selection**
  - Pick a US size (6-12). Out-of-stock sizes are greyed out and can't be selected.
  - Pick a colorway. The detail page background is tinted to match.
  - A size is required before adding to cart or using Buy Now.
  - The same shoe in a different size or colorway is a separate cart line.
  - On the shop screen and Favorites tab, "Add To Cart" opens a size/color sheet.
- **Favorites**: heart button on cards and the detail page, plus a Favorites tab.
- **Cart**: quantity controls, per-line size/color, live total, shared everywhere through Riverpod.
- **Checkout, order confirmation and history**
  - Checkout with multiple payment methods, then an animated confirmation screen.
  - Checking out from the cart places one order and empties the cart.
  - "Buy Now" orders a single shoe and leaves the cart untouched.
  - An Orders tab lists past orders (newest first) with a Placed → Shipped → Delivered tracker.
- **Persistence**: cart, favorites and orders are stored with `shared_preferences`.
  Corrupt or outdated saved data is ignored instead of crashing the app.

> **Demo behavior to know about**
> - There is no backend. Order status is simulated from the order's age:
>   *Shipped* after 1 minute and *Delivered* after 3 minutes
>   (see `Order.kShippedAfter` / `Order.kDeliveredAfter`).
> - Payment is not processed; the payment method is just recorded on the order.
> - All colorways of a shoe share one product image. Choosing a colorway changes
>   the swatch, the page tint and the cart/order text, not the photo.

## Project structure

```
lib/
  main.dart                  # loads SharedPreferences, starts the ProviderScope
  app.dart                   # MaterialApp
  features/shop/
    data/                    # shoes_data.dart  (static catalog)
    domain/models/           # Shoe, CartItem, Order
    application/             # Riverpod providers (state + persistence)
      cart_provider.dart
      wishlist_provider.dart
      orders_provider.dart
      shop_filter_provider.dart   # search / category / sort
      home_tab_provider.dart
      preferences_provider.dart
    presentation/
      screens/               # home_shell, shop, shoe_detail, cart, checkout,
                             # order_confirmation, favorites, orders
      widgets/               # animated_shoe_card, wishlist_button,
                             # variant_selectors, quick_add_sheet
test/
  cart_and_orders_test.dart  # unit tests: cart, wishlist, orders, filtering
  widget_test.dart           # widget tests: search, add to cart, checkout flow, layout
```

## State management

State lives in [Riverpod](https://riverpod.dev) `NotifierProvider`s. Screens read
and update the cart, favorites, orders and filters through providers instead of
passing lists and callbacks between screens. Each provider that needs persistence
reads its saved value in `build()` and writes back on every change.

## Getting started

Requires Flutter (Dart SDK `^3.9.2`).

```bash
flutter pub get
flutter run
```

Run the checks:

```bash
flutter analyze
flutter test
```

## Adding a shoe

Add an entry to `kShoes` in `lib/features/shop/data/shoes_data.dart` with a
category, colorways, and (optionally) a set of out-of-stock sizes. Put the image
in `assets/`. Saved carts/orders that reference a shoe id that no longer exists
are dropped when loaded.

## Dependencies

- `flutter_riverpod`: state management
- `shared_preferences`: local persistence
