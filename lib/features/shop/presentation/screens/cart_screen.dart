import 'package:flutter/material.dart';

import '../../domain/models/cart_item.dart';
import 'checkout_screen.dart';

class CartPage extends StatefulWidget {
  final List<CartItem> cart;
  final VoidCallback onCartChanged;

  const CartPage({super.key, required this.cart, required this.onCartChanged});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _checkoutPop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );

  double get total => widget.cart.fold(0, (sum, e) => sum + e.total);

  @override
  void dispose() {
    _checkoutPop.dispose();
    super.dispose();
  }

  Future<void> _openCheckout() async {
    await _checkoutPop.forward(from: 0);
    await _checkoutPop.reverse();
    if (!mounted) return;

    await Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 460),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, __, ___) => CheckoutPage(cartItems: widget.cart),
        transitionsBuilder: (_, animation, __, child) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          );
          final scale = Tween<double>(begin: 0.92, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          );
          final slide =
              Tween<Offset>(
                begin: const Offset(0, 0.03),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );

          return FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: slide,
              child: ScaleTransition(scale: scale, child: child),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Cart')),
      body: widget.cart.isEmpty
          ? const Center(
              child: Text(
                'Your cart is empty',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.cart.length,
                    itemBuilder: (context, index) {
                      final item = widget.cart[index];
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            item.shoe.imagePath,
                            width: 62,
                            height: 62,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(item.shoe.name),
                        subtitle: Text(
                          '\$${item.shoe.price.toStringAsFixed(2)} x ${item.quantity}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () {
                                if (item.quantity > 1) {
                                  setState(() => item.quantity--);
                                  widget.onCartChanged();
                                }
                              },
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() => item.quantity++);
                                widget.onCartChanged();
                              },
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() => widget.cart.removeAt(index));
                                widget.onCartChanged();
                              },
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4F4F4),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(22),
                      topRight: Radius.circular(22),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '\$${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: AnimatedBuilder(
                          animation: _checkoutPop,
                          builder: (context, child) {
                            final t = Curves.easeOutBack.transform(
                              _checkoutPop.value,
                            );
                            return Transform.scale(
                              scale: 1 + (0.06 * t),
                              child: child,
                            );
                          },
                          child: FilledButton(
                            onPressed: _openCheckout,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Checkout'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
