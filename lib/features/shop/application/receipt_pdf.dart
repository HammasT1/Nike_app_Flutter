import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/formatters.dart';
import '../domain/models/order.dart';

/// Product photos are large; shrink them so the receipt stays small.
Future<Uint8List> _loadThumbnail(AssetBundle bundle, String path) async {
  final data = await bundle.load(path);
  final codec = await ui.instantiateImageCodec(
    data.buffer.asUint8List(),
    targetWidth: 240,
  );
  final frame = await codec.getNextFrame();
  final png = await frame.image.toByteData(format: ui.ImageByteFormat.png);
  frame.image.dispose();
  codec.dispose();
  return png!.buffer.asUint8List();
}

String receiptFileName(Order order) => 'Nike-Receipt-${order.id}.pdf';

/// Builds a printable receipt ("chit") listing every shoe in the order.
Future<Uint8List> buildReceiptPdf(
  Order order, {
  AssetBundle? bundle,
  bool compress = true,
}) async {
  final assets = bundle ?? rootBundle;

  // One thumbnail per distinct shoe image.
  final thumbnails = <String, pw.MemoryImage>{};
  for (final item in order.items) {
    final path = item.shoe.imagePath;
    if (thumbnails.containsKey(path)) continue;
    thumbnails[path] = pw.MemoryImage(await _loadThumbnail(assets, path));
  }

  const ink = PdfColors.black;
  const muted = PdfColors.grey700;
  const line = PdfColors.grey300;

  pw.Widget headerCell(String text, {pw.TextAlign align = pw.TextAlign.left}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        child: pw.Text(
          text,
          textAlign: align,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: muted,
          ),
        ),
      );

  final doc = pw.Document(
    compress: compress,
    title: 'Nike Shop receipt ${order.id}',
    author: 'Nike Shop',
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (context) => [
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            color: ink,
            borderRadius: pw.BorderRadius.circular(12),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'NIKE SHOP',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'ORDER RECEIPT',
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 12),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 18),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Order #${order.id}',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  formatOrderDate(order.placedAt).replaceAll('·', '-'),
                  style: const pw.TextStyle(color: muted),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Payment', style: const pw.TextStyle(color: muted)),
                pw.SizedBox(height: 4),
                pw.Text(
                  order.paymentMethod,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 18),
        pw.Table(
          border: const pw.TableBorder(
            horizontalInside: pw.BorderSide(color: line),
            bottom: pw.BorderSide(color: line),
          ),
          columnWidths: const {
            0: pw.FixedColumnWidth(64),
            1: pw.FlexColumnWidth(3),
            2: pw.FixedColumnWidth(36),
            3: pw.FixedColumnWidth(64),
            4: pw.FixedColumnWidth(70),
          },
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                headerCell(''),
                headerCell('ITEM'),
                headerCell('QTY', align: pw.TextAlign.center),
                headerCell('PRICE', align: pw.TextAlign.right),
                headerCell('TOTAL', align: pw.TextAlign.right),
              ],
            ),
            for (final item in order.items)
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Container(
                      width: 52,
                      height: 52,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Image(
                        thumbnails[item.shoe.imagePath]!,
                        fit: pw.BoxFit.contain,
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          item.shoe.name,
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Size ${item.size} - ${item.colorway}',
                          style: const pw.TextStyle(fontSize: 9, color: muted),
                        ),
                      ],
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      '${item.quantity}',
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      formatMoney(item.shoe.price),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      formatMoney(item.total),
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
          ],
        ),
        pw.SizedBox(height: 14),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Container(
            width: 220,
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Items', style: const pw.TextStyle(color: muted)),
                    pw.Text('${order.itemCount}'),
                  ],
                ),
                pw.Divider(color: line),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAL',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      formatMoney(order.total),
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(height: 28),
        pw.Center(
          child: pw.Text(
            'Thank you for shopping with Nike Shop!',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Center(
          child: pw.Text(
            'Demo store - no real payment was taken for this order.',
            style: const pw.TextStyle(fontSize: 9, color: muted),
          ),
        ),
      ],
    ),
  );

  return doc.save();
}
