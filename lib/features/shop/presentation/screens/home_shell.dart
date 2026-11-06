import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/home_tab_provider.dart';
import 'favorites_screen.dart';
import 'orders_screen.dart';
import 'shop_screen.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(homeTabProvider);

    return Scaffold(
      body: IndexedStack(
        index: tab.index,
        children: const [NikeShopPage(), FavoritesPage(), OrdersPage()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab.index,
        backgroundColor: Colors.white,
        indicatorColor: Colors.black,
        onDestinationSelected: (i) =>
            ref.read(homeTabProvider.notifier).select(HomeTab.values[i]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront, color: Colors.white),
            label: 'Shop',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite, color: Colors.white),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: Colors.white),
            label: 'Orders',
          ),
        ],
      ),
    );
  }
}
