import 'package:flutter/material.dart';

import '../domain/models/shoe.dart';

const List<Shoe> kShoes = [
  Shoe(
    id: '1',
    name: 'Air Jordan 1',
    imagePath: 'assets/Airjordan.png',
    price: 199.99,
    accent: Color(0xFFE53935),
    bg: Color(0xFFFFEBEE),
    description: 'Iconic high-top silhouette with premium cushioning.',
    category: ShoeCategory.basketball,
    outOfStockSizes: {6, 11},
    colorways: [
      ShoeColorway('Chicago Red', Color(0xFFE53935)),
      ShoeColorway('Shadow Black', Color(0xFF212121)),
      ShoeColorway('Royal Blue', Color(0xFF1E4DB7)),
    ],
  ),
  Shoe(
    id: '2',
    name: 'Nike Air Force',
    imagePath: 'assets/four.png',
    price: 149.99,
    accent: Color(0xFF1E88E5),
    bg: Color(0xFFE3F2FD),
    description: 'Street-ready classic with soft and durable comfort.',
    category: ShoeCategory.lifestyle,
    outOfStockSizes: {12},
    colorways: [
      ShoeColorway('Sky Blue', Color(0xFF1E88E5)),
      ShoeColorway('Triple White', Color(0xFFBDBDBD)),
      ShoeColorway('Midnight', Color(0xFF263238)),
    ],
  ),
  Shoe(
    id: '3',
    name: 'Nike Air Max',
    imagePath: 'assets/three.png',
    price: 179.99,
    accent: Color(0xFFFB8C00),
    bg: Color(0xFFFFF3E0),
    description: 'Visible Air unit and a bold runner-inspired profile.',
    category: ShoeCategory.running,
    outOfStockSizes: {7, 9},
    colorways: [
      ShoeColorway('Sunset Orange', Color(0xFFFB8C00)),
      ShoeColorway('Volt', Color(0xFFC6D800)),
      ShoeColorway('Graphite', Color(0xFF616161)),
    ],
  ),
  Shoe(
    id: '4',
    name: 'Nike React',
    imagePath: 'assets/two.png',
    price: 159.99,
    accent: Color(0xFF8E24AA),
    bg: Color(0xFFF3E5F5),
    description: 'Responsive foam ride made for all-day movement.',
    category: ShoeCategory.running,
    outOfStockSizes: {8},
    colorways: [
      ShoeColorway('Violet', Color(0xFF8E24AA)),
      ShoeColorway('Pink Foam', Color(0xFFEC407A)),
      ShoeColorway('Ocean', Color(0xFF00897B)),
    ],
  ),
  Shoe(
    id: '5',
    name: 'Nike Cortez',
    imagePath: 'assets/lightblue.png',
    price: 139.99,
    accent: Color(0xFF00ACC1),
    bg: Color(0xFFE0F7FA),
    description: 'Retro design with modern comfort and clean lines.',
    category: ShoeCategory.lifestyle,
    outOfStockSizes: {10, 12},
    colorways: [
      ShoeColorway('Aqua', Color(0xFF00ACC1)),
      ShoeColorway('Sail', Color(0xFFD7CCC8)),
      ShoeColorway('Forest', Color(0xFF2E7D32)),
    ],
  ),
  Shoe(
    id: '6',
    name: 'Nike Phantom',
    imagePath: 'assets/op.png',
    price: 189.99,
    accent: Color(0xFF43A047),
    bg: Color(0xFFE8F5E9),
    description: 'Performance-forward build with premium upper details.',
    category: ShoeCategory.football,
    outOfStockSizes: {6, 9},
    colorways: [
      ShoeColorway('Pitch Green', Color(0xFF43A047)),
      ShoeColorway('Blackout', Color(0xFF212121)),
      ShoeColorway('Crimson', Color(0xFFC62828)),
    ],
  ),
];

Shoe? shoeById(String id) {
  for (final shoe in kShoes) {
    if (shoe.id == id) return shoe;
  }
  return null;
}
