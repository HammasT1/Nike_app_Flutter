import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../data/shoes_data.dart';
import '../../domain/models/cart_item.dart';
import '../../domain/models/shoe.dart';
import '../widgets/animated_shoe_card.dart';
import 'cart_screen.dart';
import 'shoe_detail_screen.dart';

class NikeShopPage extends StatefulWidget {
  const NikeShopPage({super.key});

  @override
  State<NikeShopPage> createState() => _NikeShopPageState();
}

class _NikeShopPageState extends State<NikeShopPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController(viewportFraction: 0.84);
  final List<CartItem> _cart = [];
  final GlobalKey _cartIconKey = GlobalKey();
  final List<GlobalKey> _shoeImageKeys = List<GlobalKey>.generate(
    kShoes.length,
    (_) => GlobalKey(),
  );
  int _current = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _insertIntoCart(Shoe shoe, {int qty = 1}) {
    final index = _cart.indexWhere((e) => e.shoe.id == shoe.id);
    if (index >= 0) {
      _cart[index].quantity += qty;
    } else {
      _cart.add(CartItem(shoe: shoe, quantity: qty));
    }
    setState(() {});
  }

  void _addToCart(Shoe shoe, {int qty = 1}) {
    _insertIntoCart(shoe, qty: qty);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 900),
        backgroundColor: Colors.black,
        content: Text('${shoe.name} added to cart'),
      ),
    );
  }

  Future<void> _animateAddToCart(Shoe shoe, {int qty = 1}) async {
    final sourceContext = _shoeImageKeys[_current].currentContext;
    final targetContext = _cartIconKey.currentContext;
    final overlay = Overlay.of(context);

    if (sourceContext == null || targetContext == null) {
      _addToCart(shoe, qty: qty);
      return;
    }

    final sourceBox = sourceContext.findRenderObject() as RenderBox;
    final targetBox = targetContext.findRenderObject() as RenderBox;

    final start = sourceBox.localToGlobal(
      Offset(sourceBox.size.width * 0.5 - 18, sourceBox.size.height * 0.5 - 18),
    );
    final end = targetBox.localToGlobal(
      Offset(targetBox.size.width * 0.5 - 14, targetBox.size.height * 0.5 - 14),
    );

    late OverlayEntry entry;
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1180),
    );

    entry = OverlayEntry(
      builder: (context) {
        return IgnorePointer(
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final t = controller.value;
              final moveT = Curves.easeInOutCubicEmphasized.transform(t);
              final x = lerpDouble(start.dx, end.dx, moveT) ?? end.dx;
              final y =
                  (lerpDouble(start.dy, end.dy, moveT) ?? end.dy) -
                  (56 * math.sin(math.pi * moveT));
              final scale = t < 0.20
                  ? (lerpDouble(1.35, 1.05, t / 0.20) ?? 1.05)
                  : (lerpDouble(
                          1.05,
                          0.34,
                          Curves.easeInOutCubic.transform((t - 0.20) / 0.80),
                        ) ??
                        0.34);
              final opacity = t < 0.95 ? 1.0 : (1.0 - ((t - 0.95) / 0.05));

              return Stack(
                children: [
                  Positioned(
                    left: x,
                    top: y,
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: scale,
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: shoe.accent.withOpacity(0.35),
                                  blurRadius: 18,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(7),
                            child: Image.asset(
                              shoe.imagePath,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    overlay.insert(entry);
    await controller.forward();
    entry.remove();
    controller.dispose();

    _insertIntoCart(shoe, qty: qty);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 900),
        backgroundColor: Colors.black,
        content: Text('${shoe.name} added to cart'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shoe = kShoes[_current];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Nike Shop',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 28,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14, top: 10, bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CartPage(
                      cart: _cart,
                      onCartChanged: () => setState(() {}),
                    ),
                  ),
                );
                setState(() {});
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    key: _cartIconKey,
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      color: Colors.black,
                      size: 28,
                    ),
                  ),
                  if (_cart.isNotEmpty)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.75, end: 1),
                        duration: const Duration(milliseconds: 280),
                        builder: (context, value, child) {
                          return Transform.scale(scale: value, child: child);
                        },
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${_cart.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic,
        color: shoe.bg,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: kShoes.length,
                  onPageChanged: (value) => setState(() => _current = value),
                  itemBuilder: (context, index) {
                    return AnimatedShoeCard(
                      shoe: kShoes[index],
                      selected: index == _current,
                      imageKey: _shoeImageKeys[index],
                      onTap: () async {
                        await Navigator.push(
                          context,
                          PageRouteBuilder(
                            transitionDuration: const Duration(
                              milliseconds: 420,
                            ),
                            reverseTransitionDuration: const Duration(
                              milliseconds: 300,
                            ),
                            pageBuilder: (_, __, ___) => ShoeDetailPage(
                              shoe: kShoes[index],
                              onAdd: _addToCart,
                            ),
                            transitionsBuilder: (_, animation, __, child) {
                              final fade = CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOut,
                              );
                              final rotate = Tween<double>(begin: 0.05, end: 0)
                                  .animate(
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOutCubic,
                                    ),
                                  );
                              final scale = Tween<double>(begin: 0.96, end: 1)
                                  .animate(
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOutBack,
                                    ),
                                  );
                              final slide =
                                  Tween<Offset>(
                                    begin: const Offset(0.08, 0),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOutCubic,
                                    ),
                                  );
                              return FadeTransition(
                                opacity: fade,
                                child: SlideTransition(
                                  position: slide,
                                  child: RotationTransition(
                                    turns: rotate,
                                    child: ScaleTransition(
                                      scale: scale,
                                      child: child,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                        setState(() {});
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(kShoes.length, (i) {
                        final active = i == _current;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          height: 10,
                          width: active ? 30 : 10,
                          decoration: BoxDecoration(
                            color: active ? Colors.black : Colors.black26,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutBack,
                      child: FilledButton.icon(
                        onPressed: () => _animateAddToCart(shoe),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 26,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.add_shopping_cart, size: 20),
                        label: const Text(
                          'Add To Cart',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
