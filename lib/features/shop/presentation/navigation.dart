import 'package:flutter/material.dart';

import '../domain/models/shoe.dart';
import 'screens/shoe_detail_screen.dart';

Future<void> openShoeDetail(BuildContext context, Shoe shoe) {
  return Navigator.push(
    context,
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => ShoeDetailPage(shoe: shoe),
      transitionsBuilder: (_, animation, __, child) {
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        final rotate = Tween<double>(begin: 0.05, end: 0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );
        final scale = Tween<double>(begin: 0.96, end: 1).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        );
        final slide =
            Tween<Offset>(
              begin: const Offset(0.08, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: slide,
            child: RotationTransition(
              turns: rotate,
              child: ScaleTransition(scale: scale, child: child),
            ),
          ),
        );
      },
    ),
  );
}
