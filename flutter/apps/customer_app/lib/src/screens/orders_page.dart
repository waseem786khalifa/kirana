import 'package:flutter/material.dart';

import '../customer_controller.dart';
import '../domain.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({required this.controller, super.key});

  final CustomerController controller;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.loadOrders,
      child: ListView(
        key: const PageStorageKey<String>('orders-scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Order history & tracking',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                tooltip: 'Orders refresh karein',
                onPressed: controller.loadingOrders
                    ? null
                    : controller.loadOrders,
                icon: controller.loadingOrders
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (controller.ordersError != null)
            _OrdersError(
              message: controller.ordersError!,
              onRetry: controller.loadOrders,
            ),
          if (controller.ordersError != null) const SizedBox(height: 12),
          if (controller.loadingOrders && controller.orders.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 100),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (controller.orders.isEmpty)
            const _NoOrders()
          else
            ...controller.orders.map(
              (CustomerOrder order) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OrderCard(order: order),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final _StatusDisplay status = _statusDisplay(order.status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Order #${order.id}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(order.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: status.color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(status.icon, color: status.color, size: 15),
                      const SizedBox(width: 4),
                      Text(
                        status.label,
                        style: TextStyle(
                          color: status.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!status.terminal) ...<Widget>[
              const SizedBox(height: 16),
              _StatusProgress(step: status.step),
            ],
            const Divider(height: 26),
            ...order.items
                .take(3)
                .map(
                  (CustomerOrderItem item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            '${item.name} (${item.packSize}) × ${item.quantity}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(formatRupees(item.price * item.quantity)),
                      ],
                    ),
                  ),
                ),
            if (order.items.length > 3)
              Text(
                '+ ${order.items.length - 3} aur items',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (order.rejectionReason?.isNotEmpty ?? false) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Reason: ${order.rejectionReason}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(child: Text(order.paymentMethod.toUpperCase())),
                Text(
                  formatRupees(order.total),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusProgress extends StatelessWidget {
  const _StatusProgress({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    const List<String> labels = <String>[
      'Placed',
      'Accepted',
      'Packing',
      'On the way',
      'Delivered',
    ];
    return Semantics(
      label: 'Order progress: ${labels[step.clamp(0, labels.length - 1)]}',
      child: Row(
        children: List<Widget>.generate(labels.length, (int index) {
          final bool reached = index <= step;
          return Expanded(
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    if (index > 0)
                      Expanded(
                        child: Container(
                          height: 3,
                          color: index <= step
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: reached
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      child: reached
                          ? const Icon(
                              Icons.check_rounded,
                              size: 13,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    if (index < labels.length - 1)
                      Expanded(
                        child: Container(
                          height: 3,
                          color: index < step
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _StatusDisplay {
  const _StatusDisplay({
    required this.label,
    required this.icon,
    required this.color,
    required this.step,
    this.terminal = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final int step;
  final bool terminal;
}

_StatusDisplay _statusDisplay(String raw) {
  final String status = raw
      .toUpperCase()
      .replaceAll('ORDERSTATUS.', '')
      .replaceAll('NEWORDER', 'NEW');
  return switch (status) {
    'NEW' => const _StatusDisplay(
      label: 'Order placed',
      icon: Icons.receipt_long_rounded,
      color: Color(0xFF8A5B00),
      step: 0,
    ),
    'ACCEPTED' => const _StatusDisplay(
      label: 'Accepted',
      icon: Icons.thumb_up_alt_rounded,
      color: Color(0xFF176B45),
      step: 1,
    ),
    'PREPARING' => const _StatusDisplay(
      label: 'Packing',
      icon: Icons.inventory_2_rounded,
      color: Color(0xFF176B45),
      step: 2,
    ),
    'READY' => const _StatusDisplay(
      label: 'Ready',
      icon: Icons.shopping_bag_rounded,
      color: Color(0xFF2457A6),
      step: 2,
    ),
    'OUT_FOR_DELIVERY' => const _StatusDisplay(
      label: 'On the way',
      icon: Icons.delivery_dining_rounded,
      color: Color(0xFF6236A0),
      step: 3,
    ),
    'DELIVERED' => const _StatusDisplay(
      label: 'Delivered',
      icon: Icons.check_circle_rounded,
      color: Color(0xFF176B45),
      step: 4,
      terminal: true,
    ),
    'CANCELLED' => const _StatusDisplay(
      label: 'Cancelled',
      icon: Icons.cancel_rounded,
      color: Color(0xFFB3261E),
      step: 0,
      terminal: true,
    ),
    _ => const _StatusDisplay(
      label: 'Updating',
      icon: Icons.sync_rounded,
      color: Color(0xFF5F6368),
      step: 0,
    ),
  };
}

String _formatDate(DateTime value) {
  final DateTime local = value.toLocal();
  final String minute = local.minute.toString().padLeft(2, '0');
  final int hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final String period = local.hour >= 12 ? 'PM' : 'AM';
  return '${local.day}/${local.month}/${local.year} • $hour12:$minute $period';
}

class _OrdersError extends StatelessWidget {
  const _OrdersError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.cloud_off_rounded),
          const SizedBox(width: 9),
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _NoOrders extends StatelessWidget {
  const _NoOrders();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 90),
      child: Column(
        children: <Widget>[
          CircleAvatar(
            radius: 40,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: const Icon(Icons.receipt_long_outlined, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            'Abhi koi order nahi hai',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          const Text('Order place karne ke baad live status yahan dikhega.'),
        ],
      ),
    );
  }
}
