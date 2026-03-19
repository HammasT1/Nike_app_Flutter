import 'package:flutter/material.dart';

import '../../domain/models/shoe.dart';

class AnimatedShoeCard extends StatefulWidget {
  final Shoe shoe;
  final bool selected;
  final Future<void> Function() onTap;
  final GlobalKey imageKey;

  const AnimatedShoeCard({
    super.key,
    required this.shoe,
    required this.selected,
    required this.onTap,
    required this.imageKey,
  });

  @override
  State<AnimatedShoeCard> createState() => _AnimatedShoeCardState();
}

class _AnimatedShoeCardState extends State<AnimatedShoeCard>
    with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  )..repeat(reverse: true);

  late final AnimationController _tapSpin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  bool _isOpening = false;
  bool _isPressed = false;

  @override
  void dispose() {
    _pulse.dispose();
    _tapSpin.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_isOpening) return;
    _isOpening = true;
    setState(() => _isPressed = false);
    await _tapSpin.forward(from: 0);
    await widget.onTap();
    if (mounted) {
      _tapSpin.value = 0;
      _isOpening = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      scale: widget.selected ? 1.0 : 0.94,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 260),
        opacity: widget.selected ? 1 : 0.78,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            scale: _isPressed ? 0.97 : 1,
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: _handleTap,
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapCancel: () => setState(() => _isPressed = false),
              onTapUp: (_) => setState(() => _isPressed = false),
              child: AnimatedBuilder(
                animation: Listenable.merge([_pulse, _tapSpin]),
                builder: (context, child) {
                  final spinT = Curves.easeInOutCubic.transform(_tapSpin.value);
                  final lift = Tween<double>(
                    begin: 0.0,
                    end: -12.0,
                  ).chain(CurveTween(curve: Curves.easeOut)).transform(spinT);

                  final cardScale = TweenSequence<double>([
                    TweenSequenceItem<double>(
                      tween: Tween<double>(
                        begin: 1.0,
                        end: 0.96,
                      ).chain(CurveTween(curve: Curves.easeOut)),
                      weight: 24,
                    ),
                    TweenSequenceItem<double>(
                      tween: Tween<double>(
                        begin: 0.96,
                        end: 1.03,
                      ).chain(CurveTween(curve: Curves.easeOutBack)),
                      weight: 36,
                    ),
                    TweenSequenceItem<double>(
                      tween: Tween<double>(
                        begin: 1.03,
                        end: 1.0,
                      ).chain(CurveTween(curve: Curves.easeInOut)),
                      weight: 40,
                    ),
                  ]).transform(_tapSpin.value);

                  return Transform.translate(
                    offset: Offset(0, lift),
                    child: Transform.scale(
                      scale: cardScale,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: widget.shoe.accent.withOpacity(
                                0.18 + _pulse.value * 0.12,
                              ),
                              blurRadius: 20 + _pulse.value * 12,
                              spreadRadius: 3 + _pulse.value * 5,
                            ),
                          ],
                        ),
                        child: child,
                      ),
                    ),
                  );
                },
                child: Card(
                  elevation: 16,
                  shadowColor: widget.shoe.accent.withOpacity(0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        colors: [widget.shoe.bg, Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.96, end: 1.0),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutBack,
                          builder: (context, value, child) =>
                              Transform.scale(scale: value, child: child),
                          child: AnimatedBuilder(
                            animation: _tapSpin,
                            builder: (context, child) {
                              final spin = Curves.easeInOutCubic.transform(
                                _tapSpin.value,
                              );
                              final angle = spin * 2 * 3.141592653589793;
                              final scale =
                                  1 + (0.06 * (1 - (spin - 0.5).abs() * 2));
                              return Transform.rotate(
                                angle: angle,
                                child: Transform.scale(
                                  scale: scale,
                                  child: child,
                                ),
                              );
                            },
                            child: Hero(
                              tag: 'shoe_${widget.shoe.id}',
                              child: Container(
                                key: widget.imageKey,
                                child: Image.asset(
                                  widget.shoe.imagePath,
                                  height: 220,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.shoe.name,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '\$${widget.shoe.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: widget.shoe.accent,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to open',
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.55),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
