import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../application/receipt_pdf.dart';
import '../../domain/models/order.dart';

/// Opens the system print dialog for the order's receipt. From there the
/// receipt can be printed or saved as a PDF.
Future<void> printReceipt(BuildContext context, Order order) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final bytes = await buildReceiptPdf(order);
    await Printing.layoutPdf(
      name: receiptFileName(order),
      onLayout: (_) async => bytes,
    );
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(
        backgroundColor: Colors.black,
        content: Text("Couldn't create the receipt. Please try again."),
      ),
    );
  }
}

/// Shares the receipt PDF through the system share sheet.
Future<void> shareReceipt(BuildContext context, Order order) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final bytes = await buildReceiptPdf(order);
    await Printing.sharePdf(bytes: bytes, filename: receiptFileName(order));
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(
        backgroundColor: Colors.black,
        content: Text("Couldn't share the receipt. Please try again."),
      ),
    );
  }
}

/// "Print / Save PDF" button with a spinner while the PDF is being built.
class ReceiptButton extends StatefulWidget {
  final Order order;
  final bool compact;

  const ReceiptButton({super.key, required this.order, this.compact = false});

  @override
  State<ReceiptButton> createState() => _ReceiptButtonState();
}

class _ReceiptButtonState extends State<ReceiptButton> {
  bool _busy = false;

  Future<void> _onPressed() async {
    setState(() => _busy = true);
    await printReceipt(context, widget.order);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final icon = _busy
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.print_outlined, size: 18);

    if (widget.compact) {
      return TextButton.icon(
        onPressed: _busy ? null : _onPressed,
        icon: icon,
        label: const Text('Receipt'),
        style: TextButton.styleFrom(foregroundColor: Colors.black),
      );
    }
    return OutlinedButton.icon(
      onPressed: _busy ? null : _onPressed,
      icon: icon,
      label: const Text('Print / Save Receipt (PDF)'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black,
        side: const BorderSide(color: Colors.black, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}
