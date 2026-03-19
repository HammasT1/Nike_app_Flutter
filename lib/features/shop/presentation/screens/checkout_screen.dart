import 'package:flutter/material.dart';

import '../../domain/models/cart_item.dart';

class CheckoutPage extends StatefulWidget {
  final List<CartItem> cartItems;

  const CheckoutPage({super.key, required this.cartItems});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage>
    with SingleTickerProviderStateMixin {
  final List<String> _paymentMethods = const [
    'Cash on Delivery',
    'Easypaisa',
    'JazzCash',
    'Visa / Mastercard',
    'Apple Pay',
  ];
  int _selectedPaymentMethod = 0;

  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  )..forward();

  double get total => widget.cartItems.fold(0, (sum, e) => sum + e.total);

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  void _placeOrder() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Order Placed'),
          content: Text(
            'Payment: ${_paymentMethods[_selectedPaymentMethod]}\nTotal: \$${total.toStringAsFixed(2)}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final summaryScale = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.35, 1, curve: Curves.easeOutBack),
    );
    final buttonSlide =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _enter,
            curve: const Interval(0.55, 1, curve: Curves.easeOutCubic),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: FadeTransition(
        opacity: CurvedAnimation(parent: _enter, curve: Curves.easeOut),
        child: SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0.08, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic),
              ),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Payment Method',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < _paymentMethods.length; i++)
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(milliseconds: 280 + (i * 80)),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(18 * (1 - value), 0),
                            child: Opacity(opacity: value, child: child),
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedPaymentMethod == i
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _selectedPaymentMethod == i
                                  ? Colors.black
                                  : Colors.black12,
                            ),
                          ),
                          child: RadioListTile<int>(
                            value: i,
                            groupValue: _selectedPaymentMethod,
                            title: Text(
                              _paymentMethods[i],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            activeColor: Colors.black,
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _selectedPaymentMethod = value);
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: Text(
                  'Selected: ${_paymentMethods[_selectedPaymentMethod]}',
                  key: ValueKey(_selectedPaymentMethod),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ScaleTransition(
                scale: summaryScale,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      for (final item in widget.cartItems)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  '${item.shoe.name} x ${item.quantity}',
                                ),
                              ),
                              Text('\$${item.total.toStringAsFixed(2)}'),
                            ],
                          ),
                        ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '\$${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.green,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SlideTransition(
                position: buttonSlide,
                child: FilledButton(
                  onPressed: _placeOrder,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Checkout Now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
