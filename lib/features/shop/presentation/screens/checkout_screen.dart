import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/cart_provider.dart';
import '../../application/orders_provider.dart';
import '../../domain/formatters.dart';
import '../../domain/models/cart_item.dart';
import 'order_confirmation_screen.dart';

class _PaymentMethod {
  final String name;
  final IconData icon;

  const _PaymentMethod(this.name, this.icon);
}

class CheckoutPage extends ConsumerStatefulWidget {
  final List<CartItem> cartItems;

  /// True when checking out the whole cart (which is emptied on success);
  /// false for a single-shoe "Buy Now" that leaves the cart alone.
  final bool fromCart;

  const CheckoutPage({
    super.key,
    required this.cartItems,
    required this.fromCart,
  });

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage>
    with SingleTickerProviderStateMixin {
  static const _paymentMethods = [
    _PaymentMethod('Cash on Delivery', Icons.payments_outlined),
    _PaymentMethod('Easypaisa', Icons.phone_android),
    _PaymentMethod('JazzCash', Icons.account_balance_wallet_outlined),
    _PaymentMethod('Visa / Mastercard', Icons.credit_card),
    _PaymentMethod('Apple Pay', Icons.apple),
  ];

  /// How long the "Processing" state shows before the order is placed.
  static const _processingTime = Duration(milliseconds: 1500);

  int _selectedPaymentMethod = 0;
  bool _processing = false;

  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..forward();

  double get total => widget.cartItems.fold(0, (sum, e) => sum + e.total);

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  /// Fades and slides a section in during the given slice of the entry
  /// animation, so sections appear one after another.
  Widget _stagger({
    required double from,
    required double to,
    required Widget child,
  }) {
    final curve = CurvedAnimation(
      parent: _enter,
      curve: Interval(from, to, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(curve),
        child: child,
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (widget.cartItems.isEmpty || _processing) return;

    setState(() => _processing = true);
    await Future<void>.delayed(_processingTime);
    // Leaving the page while "processing" cancels the order.
    if (!mounted) return;

    final order = ref
        .read(ordersProvider.notifier)
        .place(
          items: widget.cartItems,
          paymentMethod: _paymentMethods[_selectedPaymentMethod].name,
        );
    if (widget.fromCart) ref.read(cartProvider.notifier).clear();

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => OrderConfirmationPage(order: order),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
    ),
  );

  Widget _buildPaymentOption(int i) {
    final method = _paymentMethods[i];
    final selected = _selectedPaymentMethod == i;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + (i * 90)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(24 * (1 - value), 0),
        child: Opacity(opacity: value, child: child),
      ),
      child: GestureDetector(
        onTap: _processing
            ? null
            : () => setState(() => _selectedPaymentMethod = i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? Colors.black : const Color(0xFFF4F4F4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? Colors.black : Colors.black12,
              width: 1.5,
            ),
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: Row(
            children: [
              AnimatedScale(
                scale: selected ? 1.15 : 1,
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutBack,
                child: Icon(
                  method.icon,
                  color: selected ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 240),
                  // Build on the theme's text style so the app's font family
                  // is kept (a bare TextStyle would lose it).
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: selected ? Colors.white : Colors.black87,
                  ),
                  child: Text(method.name),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: selected
                    ? const Icon(
                        Icons.check_circle,
                        key: ValueKey('on'),
                        color: Colors.white,
                      )
                    : const Icon(
                        Icons.radio_button_unchecked,
                        key: ValueKey('off'),
                        color: Colors.black38,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemRow(int index, CartItem item) {
    // Items pop in one after another once the summary section has appeared.
    final start = 0.45 + (index * 0.08).clamp(0.0, 0.3);
    final curve = CurvedAnimation(
      parent: _enter,
      curve: Interval(
        start,
        (start + 0.35).clamp(0.0, 1.0),
        curve: Curves.easeOutBack,
      ),
    );

    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _enter,
        curve: Interval(start, (start + 0.2).clamp(0.0, 1.0)),
      ),
      child: ScaleTransition(
        scale: curve,
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: item.shoe.bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Image.asset(item.shoe.imagePath, fit: BoxFit.contain),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.shoe.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Size ${item.size} · ${item.colorway} · Qty ${item.quantity}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatMoney(item.total),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          for (var i = 0; i < widget.cartItems.length; i++)
            _buildItemRow(i, widget.cartItems[i]),
          const Divider(height: 8),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              // The total counts up from zero as the page opens.
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: total),
                duration: const Duration(milliseconds: 1100),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Text(
                  formatMoney(value),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.green,
                    fontSize: 22,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceOrderButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(_processing ? 28 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _processing ? 0.05 : 0.22),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(_processing ? 28 : 16),
          onTap: _placeOrder,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: _processing
                  ? const Row(
                      key: ValueKey('processing'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Processing...',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      'Checkout Now',
                      key: ValueKey('idle'),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: IgnorePointer(
        ignoring: _processing,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _stagger(from: 0, to: 0.35, child: _sectionTitle('Payment Method')),
            for (var i = 0; i < _paymentMethods.length; i++)
              _buildPaymentOption(i),
            const SizedBox(height: 10),
            _stagger(from: 0.3, to: 0.6, child: _sectionTitle('Order Summary')),
            _stagger(from: 0.35, to: 0.75, child: _buildSummary()),
            const SizedBox(height: 18),
            _stagger(from: 0.65, to: 1, child: _buildPlaceOrderButton()),
          ],
        ),
      ),
    );
  }
}
