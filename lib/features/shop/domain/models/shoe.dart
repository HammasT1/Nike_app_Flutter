import 'package:flutter/material.dart';

enum ShoeCategory {
  running('Running'),
  lifestyle('Lifestyle'),
  basketball('Basketball'),
  football('Football');

  const ShoeCategory(this.label);
  final String label;
}

class ShoeColorway {
  final String name;
  final Color color;

  const ShoeColorway(this.name, this.color);
}

class Shoe {
  final String id;
  final String name;
  final String imagePath;
  final double price;
  final Color accent;
  final Color bg;
  final String description;
  final ShoeCategory category;
  final List<int> sizes;
  final Set<int> outOfStockSizes;
  final List<ShoeColorway> colorways;

  const Shoe({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.price,
    required this.accent,
    required this.bg,
    required this.description,
    required this.category,
    required this.colorways,
    this.sizes = const [6, 7, 8, 9, 10, 11, 12],
    this.outOfStockSizes = const {},
  });

  bool isSizeAvailable(int size) =>
      sizes.contains(size) && !outOfStockSizes.contains(size);
}
