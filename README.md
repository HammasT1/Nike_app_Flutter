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

## Animations

All animations are built with Flutter's built-in animation widgets and
controllers. No animation packages are used.

| Where | Animation | Details |
|---|---|---|
| Shop carousel | Selected/unselected cards | Side cards scale to 0.94 and fade to 78% opacity (260 ms) |
| Shop carousel | Pulsing glow | Each card's shadow in the shoe's accent color breathes in and out (1.7 s, looping) |
| Shop carousel | Press feedback | Card shrinks to 0.97 while held (140 ms) |
| Shop carousel | Tap spin | The shoe does a full 360° spin with a lift and scale bounce (620 ms) before the detail page opens |
| Shop carousel | Background color | The page background cross-fades to the selected shoe's tint (550 ms) |
| Shop carousel | Page dots | The active dot stretches into a pill (300 ms) |
| Add to cart | Fly-to-cart | The shoe image arcs along a curve into the cart icon, shrinking as it goes, then the badge updates (1.18 s, overlay) |
| Cart badge | Pop | The count bubble scales in each time the count changes (280 ms) |
| Detail page | Route transition | Fade + slide + slight rotation + scale with `easeOutBack` (420 ms) |
| Detail page | Hero | The shoe image flies between the card and the detail page |
| Detail page | Entry | The white panel slides up and fades in (550 ms) |
| Detail page | Floating shoe | The shoe gently bobs up and down (2.4 s, looping) |
| Detail page | Size and color chips | Selection state animates (200 ms) |
| Favorites | Heart pop | The heart bounces with an elastic curve when toggled (380 ms) |
| Cart | Checkout button | Button pulses up before the checkout page opens (180 ms) |
| Checkout | Entry | Page slides and fades in; payment rows stagger in one after another (280 ms + 80 ms per row); the summary scales in |
| Checkout | Payment selection | Selected row's border and fill animate (220 ms); the "Selected:" label cross-fades |
| Order confirmation | Success badge | Black circle pops in with an elastic bounce, then the white checkmark draws itself with a `CustomPainter` (1.4 s total), then the text fades in |
| Orders | Status tracker | Step circles and connecting lines fill in as the status advances (400 ms) |

## Styling and colors

The app is a clean, high-contrast design: black and white UI chrome, with each
shoe supplying its own color. It uses Material 3 (`useMaterial3: true`) with
`ColorScheme.fromSeed(seedColor: Colors.black)`.

### Per-shoe theme colors

Every shoe has an `accent` (prices, glow, shadows, size accents) and a light `bg`
tint (page and card background). They are defined in
`lib/features/shop/data/shoes_data.dart`.

| Shoe | Accent | Background tint |
|---|---|---|
| Air Jordan 1 | `#E53935` red | `#FFEBEE` |
| Nike Air Force | `#1E88E5` blue | `#E3F2FD` |
| Nike Air Max | `#FB8C00` orange | `#FFF3E0` |
| Nike React | `#8E24AA` purple | `#F3E5F5` |
| Nike Cortez | `#00ACC1` cyan | `#E0F7FA` |
| Nike Phantom | `#43A047` green | `#E8F5E9` |

The shop and cards switch to the selected shoe's tint as you swipe. On the detail
page the background is tinted by the chosen **colorway** (the colorway color at
16% opacity over white). Each shoe also has three colorway swatches, such as
Chicago Red, Shadow Black and Royal Blue.

### Shared UI colors

| Use | Color |
|---|---|
| Primary actions, selected chips, nav indicator, order tracker | `Colors.black` |
| Surfaces, cards, detail panel | `Colors.white` |
| Summary panels, order cards, cart footer | `#F4F4F4` |
| Cart badge | `Colors.red` |
| Totals and order amounts | `Colors.green` |
| Favorited heart, size error text, remove button | `Colors.red` |
| Secondary text | `Colors.black54` / `black45` |
| Disabled or out-of-stock sizes | `Colors.black26` with a strikethrough |

### Shape and typography

- Rounded corners everywhere: 28 on shoe cards, 30 on the detail panel, 12-14 on
  buttons, chips and inputs, 20 on order and favorite cards.
- Heavy weights for emphasis: prices and titles use `w800`/`w900`; supporting
  text uses regular or `w600`.
- Soft colored shadows on the shoe cards, using the shoe's accent color.
- The default Material font is used; no custom fonts are bundled.

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
