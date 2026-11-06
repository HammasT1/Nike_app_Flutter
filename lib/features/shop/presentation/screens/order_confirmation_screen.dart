import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/home_tab_provider.dart';
import '../../domain/formatters.dart';
import '../../domain/models/cart_item.dart';
import '../../domain/models/order.dart';
import '../widgets/receipt_actions.dart';

class OrderConfirmationPage extends ConsumerStatefulWidget {
  final Order order;

  const OrderConfirmationPage({super.key, required this.order});

  @override
  ConsumerState<OrderConfirmationPage> createState() =>
      _OrderConfirmationPageState();
}

class _OrderConfirmationPageState extends ConsumerState<OrderConfirmationPage>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..forward();

  late final AnimationController _confettiController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..forward();

  late final List<_Particle> _particles = _Particle.burst(
    colors: [
      for (final item in widget.order.items) item.shoe.accent,
      Colors.black,
      const Color(0xFFFFC107),
    ],
  );

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _finish(HomeTab tab) {
    ref.read(homeTabProvider.notifier).select(tab);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Animation<double> _slice(
    double from,
    double to, [
    Curve curve = Curves.easeOut,
  ]) => CurvedAnimation(
    parent: _controller,
    curve: Interval(from, to, curve: curve),
  );

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final badgeScale = _slice(0, 0.32, Curves.elasticOut);
    final checkProgress = _slice(0.18, 0.5);
    final textFade = _slice(0.45, 0.7);
    final summarySlide = _slice(0.5, 0.8, Curves.easeOutCubic);
    final buttonsFade = _slice(0.8, 1);

    // Back is intercepted so the user lands on the shop rather than on a
    // checkout page for an order that has already been placed.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish(HomeTab.shop);
      },
      child: Scaffold(
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 24,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ScaleTransition(
                                scale: badgeScale,
                                child: Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.25,
                                        ),
                                        blurRadius: 24,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: AnimatedBuilder(
                                    animation: checkProgress,
                                    builder: (context, _) => CustomPaint(
                                      painter: _CheckPainter(
                                        checkProgress.value,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),
                              FadeTransition(
                                opacity: textFade,
                                child: Column(
                                  children: [
                                    const Text(
                                      'Order Placed!',
                                      style: TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Order #${order.id}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              FadeTransition(
                                opacity: summarySlide,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.15),
                                    end: Offset.zero,
                                  ).animate(summarySlide),
                                  child: _buildSummary(order),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  FadeTransition(
                    opacity: buttonsFade,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ReceiptButton(order: order),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () => _finish(HomeTab.orders),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: const Text('View My Orders'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => _finish(HomeTab.shop),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: const Text('Continue Shopping'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Confetti falls over everything but never blocks taps.
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _confettiController,
                  builder: (context, _) => CustomPaint(
                    painter: _ConfettiPainter(
                      _confettiController.value,
                      _particles,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(Order order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          // The shoes just bought pop in one after another.
          for (var i = 0; i < order.items.length; i++)
            _ShoeLine(
              item: order.items[i],
              animation: _slice(
                (0.55 + i * 0.07).clamp(0.0, 0.85),
                (0.8 + i * 0.07).clamp(0.0, 1.0),
                Curves.easeOutBack,
              ),
            ),
          const Divider(height: 18),
          _row('Items', '${order.itemCount}'),
          const SizedBox(height: 6),
          _row('Payment', order.paymentMethod),
          const Divider(height: 22),
          _row('Total', formatMoney(order.total), bold: true),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
      fontSize: bold ? 18 : 14,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style.copyWith(color: Colors.black54)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(value, style: style, textAlign: TextAlign.right),
        ),
      ],
    );
  }
}

class _ShoeLine extends StatelessWidget {
  final CartItem item;
  final Animation<double> animation;

  const _ShoeLine({required this.item, required this.animation});

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: animation,
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: item.shoe.bg,
                borderRadius: BorderRadius.circular(12),
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
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double progress;

  _CheckPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.30, size.height * 0.52)
      ..lineTo(size.width * 0.45, size.height * 0.66)
      ..lineTo(size.width * 0.72, size.height * 0.36);

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * progress), paint);
    }
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}

/// One piece of confetti. All values are fractions so it works at any size.
class _Particle {
  final double x; // start column, 0..1
  final double delay; // 0..0.4 of the animation
  final double fall; // how much of the screen height it falls
  final double sway; // horizontal drift amplitude
  final double spin;
  final double size;
  final Color color;

  const _Particle({
    required this.x,
    required this.delay,
    required this.fall,
    required this.sway,
    required this.spin,
    required this.size,
    required this.color,
  });

  static List<_Particle> burst({required List<Color> colors, int count = 44}) {
    final random = math.Random(7); // fixed seed: same burst every time
    return List.generate(count, (i) {
      return _Particle(
        x: random.nextDouble(),
        delay: random.nextDouble() * 0.4,
        fall: 0.7 + random.nextDouble() * 0.4,
        sway: 10 + random.nextDouble() * 26,
        spin: (random.nextDouble() - 0.5) * 14,
        size: 6 + random.nextDouble() * 7,
        color: colors[i % colors.length],
      );
    });
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_Particle> particles;

  _ConfettiPainter(this.progress, this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = ((progress - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (t <= 0 || t >= 1) continue;

      final eased = Curves.easeIn.transform(t);
      final dx = p.x * size.width + math.sin(t * 6 + p.x * 9) * p.sway;
      final dy = -20 + eased * size.height * p.fall;
      final opacity = t > 0.8 ? (1 - t) / 0.2 : 1.0;

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(t * p.spin);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.55,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = p.color.withValues(alpha: opacity.clamp(0.0, 1.0)),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
