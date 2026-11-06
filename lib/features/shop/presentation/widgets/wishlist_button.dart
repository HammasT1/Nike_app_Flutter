import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/wishlist_provider.dart';

class WishlistButton extends ConsumerWidget {
  final String shoeId;
  final Color background;

  const WishlistButton({
    super.key,
    required this.shoeId,
    this.background = Colors.white,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(
      wishlistProvider.select((s) => s.contains(shoeId)),
    );

    return Material(
      color: background,
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => ref.read(wishlistProvider.notifier).toggle(shoeId),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: TweenAnimationBuilder<double>(
            key: ValueKey(isFavorite),
            tween: Tween(begin: isFavorite ? 0.6 : 1.0, end: 1.0),
            duration: const Duration(milliseconds: 380),
            curve: Curves.elasticOut,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.black87,
              size: 22,
              semanticLabel: isFavorite
                  ? 'Remove from favorites'
                  : 'Add to favorites',
            ),
          ),
        ),
      ),
    );
  }
}
