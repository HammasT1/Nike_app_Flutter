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
  ),
  Shoe(
    id: '2',
    name: 'Nike Air Force',
    imagePath: 'assets/four.png',
    price: 149.99,
    accent: Color(0xFF1E88E5),
    bg: Color(0xFFE3F2FD),
    description: 'Street-ready classic with soft and durable comfort.',
  ),
  Shoe(
    id: '3',
    name: 'Nike Air Max',
    imagePath: 'assets/three.png',
    price: 179.99,
    accent: Color(0xFFFB8C00),
    bg: Color(0xFFFFF3E0),
    description: 'Visible Air unit and a bold runner-inspired profile.',
  ),
  Shoe(
    id: '4',
    name: 'Nike React',
    imagePath: 'assets/two.png',
    price: 159.99,
    accent: Color(0xFF8E24AA),
    bg: Color(0xFFF3E5F5),
    description: 'Responsive foam ride made for all-day movement.',
  ),
  Shoe(
    id: '5',
    name: 'Nike Cortez',
    imagePath: 'assets/lightblue.png',
    price: 139.99,
    accent: Color(0xFF00ACC1),
    bg: Color(0xFFE0F7FA),
    description: 'Retro design with modern comfort and clean lines.',
  ),
  Shoe(
    id: '6',
    name: 'Nike Phantom',
    imagePath: 'assets/op.png',
    price: 189.99,
    accent: Color(0xFF43A047),
    bg: Color(0xFFE8F5E9),
    description: 'Performance-forward build with premium upper details.',
  ),
];
