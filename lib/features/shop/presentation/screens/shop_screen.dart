import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/cart_provider.dart';
import '../../application/shop_filter_provider.dart';
import '../../domain/models/shoe.dart';
import '../navigation.dart';
import '../widgets/animated_shoe_card.dart';
import '../widgets/quick_add_sheet.dart';
import 'cart_screen.dart';

class NikeShopPage extends ConsumerStatefulWidget {
  const NikeShopPage({super.key});

  @override
  ConsumerState<NikeShopPage> createState() => _NikeShopPageState();
}

class _NikeShopPageState extends ConsumerState<NikeShopPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController(viewportFraction: 0.84);
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _cartIconKey = GlobalKey();
  final Map<String, GlobalKey> _shoeImageKeys = {};
  int _current = 0;

  GlobalKey _imageKeyFor(Shoe shoe) =>
      _shoeImageKeys.putIfAbsent(shoe.id, GlobalKey.new);

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Any change to the visible list sends the carousel back to the first shoe.
  void _resetCarousel() {
    _current = 0;
    if (_pageController.hasClients) _pageController.jumpToPage(0);
  }

  void _showAddedSnack(Shoe shoe) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 900),
        backgroundColor: Colors.black,
        content: Text('${shoe.name} added to cart'),
      ),
    );
  }

  Future<void> _quickAdd(Shoe shoe) async {
    final selection = await showQuickAddSheet(context, shoe);
    if (selection == null || !mounted) return;
    await _animateAddToCart(shoe, selection);
  }

  Future<void> _animateAddToCart(Shoe shoe, QuickAddSelection selection) async {
    void commit() {
      ref
          .read(cartProvider.notifier)
          .add(shoe, size: selection.size, colorway: selection.colorway.name);
      _showAddedSnack(shoe);
    }

    final sourceContext = _imageKeyFor(shoe).currentContext;
    final targetContext = _cartIconKey.currentContext;
    final overlay = Overlay.of(context);

    if (sourceContext == null || targetContext == null) {
      commit();
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
                                  color: shoe.accent.withValues(alpha: 0.35),
                                  blurRadius: 18,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(7),
                            child: Image.asset(
                              shoe.imagePath,
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

    if (mounted) commit();
  }

  Widget _buildCartAction(int cartLines) {
    return Padding(
      padding: const EdgeInsets.only(right: 14, top: 10, bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CartPage()),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              key: _cartIconKey,
              padding: const EdgeInsets.all(8.0),
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: Colors.black,
                size: 28,
              ),
            ),
            if (cartLines > 0)
              Positioned(
                right: -2,
                top: -2,
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(cartLines),
                  tween: Tween(begin: 0.75, end: 1),
                  duration: const Duration(milliseconds: 280),
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$cartLines',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
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

  Widget _buildSearchAndFilters(ShoeFilter filter) {
    final notifier = ref.read(shoeFilterProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onChanged: (value) {
                    notifier.setQuery(value);
                    _resetCarousel();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search shoes',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.8),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: filter.query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchController.clear();
                              notifier.setQuery('');
                              _resetCarousel();
                            },
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<ShoeSort>(
                tooltip: 'Sort',
                initialValue: filter.sort,
                onSelected: (sort) {
                  notifier.setSort(sort);
                  _resetCarousel();
                },
                itemBuilder: (_) => [
                  for (final sort in ShoeSort.values)
                    PopupMenuItem(value: sort, child: Text(sort.label)),
                ],
                child: Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: filter.sort == ShoeSort.featured
                        ? Colors.white.withValues(alpha: 0.8)
                        : Colors.black,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.swap_vert,
                    color: filter.sort == ShoeSort.featured
                        ? Colors.black
                        : Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _categoryChip('All', filter.category == null, () {
                  notifier.setCategory(null);
                  _resetCarousel();
                }),
                for (final category in ShoeCategory.values)
                  _categoryChip(
                    category.label,
                    filter.category == category,
                    () {
                      notifier.setCategory(category);
                      _resetCarousel();
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: Colors.black,
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        side: BorderSide.none,
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.black,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 60, color: Colors.black38),
            const SizedBox(height: 12),
            const Text(
              'No shoes found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try a different search or category.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                _searchController.clear();
                ref.read(shoeFilterProvider.notifier).reset();
                _resetCarousel();
              },
              child: const Text('Clear filters'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(shoeFilterProvider);
    final shoes = ref.watch(filteredShoesProvider);
    final cartLines = ref.watch(cartProvider.select((c) => c.length));

    if (_current >= shoes.length) _current = 0;
    final shoe = shoes.isEmpty ? null : shoes[_current];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Nike Shop',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 28,
          ),
        ),
        actions: [_buildCartAction(cartLines)],
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic,
        color: shoe?.bg ?? const Color(0xFFF4F4F4),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: kToolbarHeight),
              _buildSearchAndFilters(filter),
              Expanded(
                child: shoes.isEmpty
                    ? _buildEmptyState()
                    : PageView.builder(
                        controller: _pageController,
                        itemCount: shoes.length,
                        onPageChanged: (value) =>
                            setState(() => _current = value),
                        itemBuilder: (context, index) {
                          final item = shoes[index];
                          return AnimatedShoeCard(
                            key: ValueKey(item.id),
                            shoe: item,
                            selected: index == _current,
                            imageKey: _imageKeyFor(item),
                            onTap: () => openShoeDetail(context, item),
                          );
                        },
                      ),
              ),
              if (shoe != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(shoes.length, (i) {
                          final active = i == _current;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            height: 10,
                            width: active ? 30 : 10,
                            decoration: BoxDecoration(
                              color: active ? Colors.black : Colors.black26,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: () => _quickAdd(shoe),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 26,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.add_shopping_cart, size: 20),
                        label: const Text(
                          'Add To Cart',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
