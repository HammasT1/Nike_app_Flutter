import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/home_tab_provider.dart';
import '../../application/orders_provider.dart';
import '../../domain/models/order.dart';

class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> {
  late final Timer _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Order status is simulated from its age, so re-evaluate periodically.
    _ticker = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Orders',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 26),
        ),
      ),
      body: orders.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      size: 64,
                      color: Colors.black26,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'No orders yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Your placed orders will show up here.',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 18),
                    OutlinedButton(
                      onPressed: () => ref
                          .read(homeTabProvider.notifier)
                          .select(HomeTab.shop),
                      child: const Text('Start shopping'),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) =>
                  _OrderCard(order: orders[index], now: _now),
            ),
    );
  }
}

String _formatDate(DateTime d) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final minute = d.minute.toString().padLeft(2, '0');
  final period = d.hour < 12 ? 'AM' : 'PM';
  return '${months[d.month - 1]} ${d.day}, ${d.year} · $hour:$minute $period';
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final DateTime now;

  const _OrderCard({required this.order, required this.now});

  @override
  Widget build(BuildContext context) {
    final status = order.statusAt(now);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${order.id}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              Text(
                '\$${order.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${_formatDate(order.placedAt)} · ${order.paymentMethod}',
            style: const TextStyle(color: Colors.black54, fontSize: 12.5),
          ),
          const SizedBox(height: 14),
          _StatusStepper(status: status),
          const SizedBox(height: 14),
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: item.shoe.bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Image.asset(
                      item.shoe.imagePath,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.shoe.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Size ${item.size} · ${item.colorway} · Qty ${item.quantity}',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text('\$${item.total.toStringAsFixed(2)}'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusStepper extends StatelessWidget {
  final OrderStatus status;

  const _StatusStepper({required this.status});

  @override
  Widget build(BuildContext context) {
    const steps = OrderStatus.values;

    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                height: 3,
                margin: const EdgeInsets.only(bottom: 18),
                color: i <= status.index ? Colors.black : Colors.black12,
              ),
            ),
          Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i <= status.index ? Colors.black : Colors.white,
                  border: Border.all(
                    color: i <= status.index ? Colors.black : Colors.black26,
                    width: 2,
                  ),
                ),
                child: i <= status.index
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 4),
              Text(
                steps[i].label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: i == status.index
                      ? FontWeight.w800
                      : FontWeight.w500,
                  color: i <= status.index ? Colors.black : Colors.black45,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
