import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/cart_provider.dart';
import '../../application/home_tab_provider.dart';
import '../../application/wishlist_provider.dart';
import '../../data/shoes_data.dart';
import '../../domain/models/shoe.dart';
import '../navigation.dart';
import '../widgets/quick_add_sheet.dart';
import '../widgets/wishlist_button.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(wishlistProvider);
    final favorites = kShoes.where((s) => ids.contains(s.id)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Favorites',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 26),
        ),
      ),
      body: favorites.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.favorite_border,
                      size: 64,
                      color: Colors.black26,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'No favorites yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap the heart on any shoe to save it here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 18),
                    OutlinedButton(
                      onPressed: () => ref
                          .read(homeTabProvider.notifier)
                          .select(HomeTab.shop),
                      child: const Text('Browse shoes'),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _FavoriteTile(shoe: favorites[index]),
            ),
    );
  }
}

class _FavoriteTile extends ConsumerWidget {
  final Shoe shoe;

  const _FavoriteTile({required this.shoe});

  Future<void> _quickAdd(BuildContext context, WidgetRef ref) async {
    final selection = await showQuickAddSheet(context, shoe);
    if (selection == null || !context.mounted) return;
    ref
        .read(cartProvider.notifier)
        .add(shoe, size: selection.size, colorway: selection.colorway.name);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 900),
        backgroundColor: Colors.black,
        content: Text('${shoe.name} added to cart'),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: shoe.bg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => openShoeDetail(context, shoe),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 92,
                height: 92,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Image.asset(shoe.imagePath, fit: BoxFit.contain),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shoe.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      shoe.category.label,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${shoe.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: shoe.accent,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 34,
                      child: FilledButton(
                        onPressed: () => _quickAdd(context, ref),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        child: const Text('Add To Cart'),
                      ),
                    ),
                  ],
                ),
              ),
              WishlistButton(shoeId: shoe.id),
            ],
          ),
        ),
      ),
    );
  }
}
