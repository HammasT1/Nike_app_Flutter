import 'package:flutter/material.dart';

import '../../domain/models/shoe.dart';

class SizeSelector extends StatelessWidget {
  final Shoe shoe;
  final int? selected;
  final ValueChanged<int> onSelected;

  const SizeSelector({
    super.key,
    required this.shoe,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final size in shoe.sizes)
          _SizeChip(
            size: size,
            available: shoe.isSizeAvailable(size),
            selected: selected == size,
            accent: shoe.accent,
            onTap: () => onSelected(size),
          ),
      ],
    );
  }
}

class _SizeChip extends StatelessWidget {
  final int size;
  final bool available;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _SizeChip({
    required this.size,
    required this.available,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      enabled: available,
      label: available ? 'Size $size' : 'Size $size, out of stock',
      child: GestureDetector(
        onTap: available ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? Colors.black
                  : (available ? Colors.black26 : Colors.black12),
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            '$size',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected
                  ? Colors.white
                  : (available ? Colors.black : Colors.black26),
              decoration: available ? null : TextDecoration.lineThrough,
            ),
          ),
        ),
      ),
    );
  }
}

class ColorwaySelector extends StatelessWidget {
  final Shoe shoe;
  final ShoeColorway selected;
  final ValueChanged<ShoeColorway> onSelected;

  const ColorwaySelector({
    super.key,
    required this.shoe,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final colorway in shoe.colorways)
          Semantics(
            button: true,
            selected: colorway.name == selected.name,
            label: 'Color ${colorway.name}',
            child: GestureDetector(
              onTap: () => onSelected(colorway),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorway.name == selected.name
                        ? Colors.black
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: colorway.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black12),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
