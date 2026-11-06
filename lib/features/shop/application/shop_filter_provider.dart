import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/shoes_data.dart';
import '../domain/models/shoe.dart';

enum ShoeSort {
  featured('Featured'),
  priceLow('Price: Low to High'),
  priceHigh('Price: High to Low'),
  name('Name: A to Z');

  const ShoeSort(this.label);
  final String label;
}

class ShoeFilter {
  final String query;
  final ShoeCategory? category;
  final ShoeSort sort;

  const ShoeFilter({
    this.query = '',
    this.category,
    this.sort = ShoeSort.featured,
  });

  bool get isActive =>
      query.trim().isNotEmpty || category != null || sort != ShoeSort.featured;
}

class ShoeFilterNotifier extends Notifier<ShoeFilter> {
  @override
  ShoeFilter build() => const ShoeFilter();

  void setQuery(String query) => state = ShoeFilter(
    query: query,
    category: state.category,
    sort: state.sort,
  );

  void setCategory(ShoeCategory? category) => state = ShoeFilter(
    query: state.query,
    category: category,
    sort: state.sort,
  );

  void setSort(ShoeSort sort) => state = ShoeFilter(
    query: state.query,
    category: state.category,
    sort: sort,
  );

  void reset() => state = const ShoeFilter();
}

final shoeFilterProvider = NotifierProvider<ShoeFilterNotifier, ShoeFilter>(
  ShoeFilterNotifier.new,
);

List<Shoe> applyShoeFilter(List<Shoe> shoes, ShoeFilter filter) {
  final query = filter.query.trim().toLowerCase();
  final result = shoes.where((shoe) {
    if (filter.category != null && shoe.category != filter.category) {
      return false;
    }
    if (query.isEmpty) return true;
    return shoe.name.toLowerCase().contains(query) ||
        shoe.description.toLowerCase().contains(query) ||
        shoe.category.label.toLowerCase().contains(query);
  }).toList();

  switch (filter.sort) {
    case ShoeSort.featured:
      break;
    case ShoeSort.priceLow:
      result.sort((a, b) => a.price.compareTo(b.price));
    case ShoeSort.priceHigh:
      result.sort((a, b) => b.price.compareTo(a.price));
    case ShoeSort.name:
      result.sort((a, b) => a.name.compareTo(b.name));
  }
  return result;
}

final filteredShoesProvider = Provider<List<Shoe>>(
  (ref) => applyShoeFilter(kShoes, ref.watch(shoeFilterProvider)),
);
