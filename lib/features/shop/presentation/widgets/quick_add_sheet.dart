import 'package:flutter/material.dart';

import '../../domain/models/shoe.dart';
import 'variant_selectors.dart';

class QuickAddSelection {
  final int size;
  final ShoeColorway colorway;

  const QuickAddSelection(this.size, this.colorway);
}

/// Bottom sheet that asks for a size and colorway. Resolves to `null` when
/// dismissed.
Future<QuickAddSelection?> showQuickAddSheet(BuildContext context, Shoe shoe) {
  return showModalBottomSheet<QuickAddSelection>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (_) => _QuickAddSheet(shoe: shoe),
  );
}

class _QuickAddSheet extends StatefulWidget {
  final Shoe shoe;

  const _QuickAddSheet({required this.shoe});

  @override
  State<_QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<_QuickAddSheet> {
  int? _size;
  late ShoeColorway _colorway = widget.shoe.colorways.first;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.shoe.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select size',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            SizeSelector(
              shoe: widget.shoe,
              selected: _size,
              onSelected: (s) => setState(() => _size = s),
            ),
            const SizedBox(height: 18),
            Text(
              'Color: ${_colorway.name}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            ColorwaySelector(
              shoe: widget.shoe,
              selected: _colorway,
              onSelected: (c) => setState(() => _colorway = c),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _size == null
                    ? null
                    : () => Navigator.pop(
                        context,
                        QuickAddSelection(_size!, _colorway),
                      ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(_size == null ? 'Select a size' : 'Add To Cart'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
