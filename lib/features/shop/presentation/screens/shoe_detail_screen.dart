import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/cart_provider.dart';
import '../../domain/models/cart_item.dart';
import '../../domain/models/shoe.dart';
import '../widgets/variant_selectors.dart';
import '../widgets/wishlist_button.dart';
import 'checkout_screen.dart';

class ShoeDetailPage extends ConsumerStatefulWidget {
  final Shoe shoe;

  const ShoeDetailPage({super.key, required this.shoe});

  @override
  ConsumerState<ShoeDetailPage> createState() => _ShoeDetailPageState();
}

class _ShoeDetailPageState extends ConsumerState<ShoeDetailPage>
    with TickerProviderStateMixin {
  final GlobalKey _detailShoeImageKey = GlobalKey();
  final GlobalKey _detailCartIconKey = GlobalKey();

  late final AnimationController _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  )..forward();

  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  int qty = 1;
  int? _size;
  bool _sizeError = false;
  late ShoeColorway _colorway = widget.shoe.colorways.first;

  /// Light tint of the chosen colorway, used for the page background.
  Color get _tint =>
      Color.alphaBlend(_colorway.color.withValues(alpha: 0.16), Colors.white);

  /// Returns the chosen size, or flags the missing selection.
  int? _requireSize() {
    if (_size == null) {
      setState(() => _sizeError = true);
      return null;
    }
    return _size;
  }

  void _addToCart(int size) {
    ref
        .read(cartProvider.notifier)
        .add(widget.shoe, size: size, colorway: _colorway.name, qty: qty);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 900),
        backgroundColor: Colors.black,
        content: Text('${widget.shoe.name} added to cart'),
      ),
    );
  }

  @override
  void dispose() {
    _entry.dispose();
    _float.dispose();
    super.dispose();
  }

  Future<void> _animateAddToCartAndReturn() async {
    final size = _requireSize();
    if (size == null) return;

    final sourceContext = _detailShoeImageKey.currentContext;
    final targetContext = _detailCartIconKey.currentContext;
    final overlay = Overlay.of(context);

    if (sourceContext == null || targetContext == null) {
      _addToCart(size);
      Navigator.pop(context);
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
                                  color: widget.shoe.accent.withValues(
                                    alpha: 0.35,
                                  ),
                                  blurRadius: 18,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(7),
                            child: Image.asset(
                              widget.shoe.imagePath,
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

    if (mounted) {
      _addToCart(size);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: Material(
            color: Colors.black.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back, color: Colors.black),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: WishlistButton(
              shoeId: widget.shoe.id,
              background: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            child: Container(
              key: _detailCartIconKey,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        color: _tint,
        child: SafeArea(
          child: FadeTransition(
            opacity: CurvedAnimation(parent: _entry, curve: Curves.easeOut),
            child: Column(
              children: [
                const SizedBox(height: 10),
                AnimatedBuilder(
                  animation: _float,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, (_float.value - 0.5) * 16),
                      child: child,
                    );
                  },
                  child: Hero(
                    tag: 'shoe_${widget.shoe.id}',
                    child: Container(
                      key: _detailShoeImageKey,
                      child: Image.asset(
                        widget.shoe.imagePath,
                        height: 220,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 0.15),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _entry,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.shoe.name,
                                    style: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.shoe.category.label,
                                    style: const TextStyle(
                                      color: Colors.black45,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.shoe.description,
                                    style: TextStyle(
                                      color: Colors.black.withValues(
                                        alpha: 0.65,
                                      ),
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Price',
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '\$${widget.shoe.price.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: widget.shoe.accent,
                                          fontSize: 30,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Color: ${_colorway.name}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ColorwaySelector(
                                    shoe: widget.shoe,
                                    selected: _colorway,
                                    onSelected: (c) =>
                                        setState(() => _colorway = c),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Text(
                                        'Size (US)',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      if (_sizeError)
                                        const Flexible(
                                          child: Text(
                                            'Please select a size',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  SizeSelector(
                                    shoe: widget.shoe,
                                    selected: _size,
                                    onSelected: (s) => setState(() {
                                      _size = s;
                                      _sizeError = false;
                                    }),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Quantity',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.black12,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            IconButton(
                                              onPressed: () {
                                                if (qty > 1) {
                                                  setState(() => qty--);
                                                }
                                              },
                                              icon: const Icon(Icons.remove),
                                            ),
                                            Text(
                                              '$qty',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 17,
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () =>
                                                  setState(() => qty++),
                                              icon: const Icon(Icons.add),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  onPressed: _animateAddToCartAndReturn,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'Add To Cart',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    final size = _requireSize();
                                    if (size == null) return;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CheckoutPage(
                                          fromCart: false,
                                          cartItems: [
                                            CartItem(
                                              shoe: widget.shoe,
                                              size: size,
                                              colorway: _colorway.name,
                                              quantity: qty,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    side: const BorderSide(
                                      color: Colors.black,
                                      width: 2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'Buy Now',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
