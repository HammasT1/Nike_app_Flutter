import 'package:flutter/material.dart';

class Shoe {
  final String id;
  final String name;
  final String imagePath;
  final double price;
  final Color accent;
  final Color bg;
  final String description;

  const Shoe({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.price,
    required this.accent,
    required this.bg,
    required this.description,
  });
}
