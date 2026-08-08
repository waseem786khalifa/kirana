import 'package:flutter/material.dart';

import '../customer_controller.dart';
import '../domain.dart';

class CartPage extends StatelessWidget {
  const CartPage({
    required this.controller,
    required this.onBrowse,
    required this.onCheckout,
    super.key,
  });

  final CustomerController controller;
  final VoidCallback onBrowse;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    if (controller.cartLines.isEmpty) {
      return _EmptyCart(onBrowse: onBrowse);
    }

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            key: const PageStorageKey<String>('cart-scroll'),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            children: <Widget>[
              if (controller.amountUntilMinimum > 0)
                _MinimumOrderCard(controller: controller)
              else
                _DeliveryMessage(controller: controller),
              const SizedBox(height: 12),
              ...controller.cartLines.map(
                (CartLine line) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CartLineCard(controller: controller, line: line),
                ),
              ),
              const SizedBox(height: 6),
              _BillCard(controller: controller),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text('Total', style: TextStyle(fontSize: 12)),
                      Text(
                        formatRupees(controller.total),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    key: const Key('proceed-checkout'),
                    onPressed: controller.canCheckout ? onCheckout : null,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Checkout'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CartLineCard extends StatelessWidget {
  const _CartLineCard({required this.controller, required this.line});

  final CustomerController controller;
  final CartLine line;

  @override
  Widget build(BuildContext context) {
    final CustomerProduct product = line.product;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            Container(
              width: 70,
              height: 70,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: product.imageUrl.isEmpty
                  ? const Icon(Icons.inventory_2_outlined)
                  : Image.network(
                      product.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.inventory_2_outlined),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.packSize,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatRupees(line.total),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    tooltip: line.quantity == 1
                        ? 'Cart se hatayein'
                        : 'Quantity kam karein',
                    onPressed: () =>
                        controller.setQuantity(product, line.quantity - 1),
                    icon: Icon(
                      line.quantity == 1
                          ? Icons.delete_outline_rounded
                          : Icons.remove_rounded,
                    ),
                  ),
                  Text(
                    '${line.quantity}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  IconButton(
                    tooltip: line.quantity < product.stock
                        ? 'Quantity badhayein'
                        : 'Maximum available stock',
                    onPressed: line.quantity < product.stock
                        ? () =>
                              controller.setQuantity(product, line.quantity + 1)
                        : null,
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MinimumOrderCard extends StatelessWidget {
  const _MinimumOrderCard({required this.controller});

  final CustomerController controller;

  @override
  Widget build(BuildContext context) {
    final double minimum = controller.selectedStore!.minimumOrder;
    final double progress = minimum <= 0
        ? 1
        : (controller.subtotal / minimum).clamp(0, 1);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${formatRupees(controller.amountUntilMinimum)} aur add karein to order place hoga',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 9),
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 5),
          Text('Minimum order: ${formatRupees(minimum)}'),
        ],
      ),
    );
  }
}

class _DeliveryMessage extends StatelessWidget {
  const _DeliveryMessage({required this.controller});

  final CustomerController controller;

  @override
  Widget build(BuildContext context) {
    final CustomerStore store = controller.selectedStore!;
    final bool free = controller.deliveryCharge == 0;
    String text;
    if (!store.isOpen) {
      text = 'Dukaan band hai; checkout filhaal available nahi hai.';
    } else if (!store.deliveryAvailable) {
      text = 'Home delivery filhaal available nahi hai.';
    } else if (free) {
      text = 'Yay! Is order par delivery FREE hai.';
    } else {
      final double remaining = (store.freeDeliveryAbove - controller.subtotal)
          .clamp(0, double.infinity);
      text =
          '${formatRupees(remaining)} aur add karein aur FREE delivery paayein.';
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: free
            ? const Color(0xFFE1F5E9)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            free ? Icons.local_shipping_rounded : Icons.info_outline_rounded,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  const _BillCard({required this.controller});

  final CustomerController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Bill details',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            _BillRow(
              label: 'MRP total',
              value: formatRupees(controller.mrpTotal),
            ),
            if (controller.discount > 0)
              _BillRow(
                label: 'Product savings',
                value: '-${formatRupees(controller.discount)}',
                valueColor: const Color(0xFF147447),
              ),
            _BillRow(
              label: 'Item subtotal',
              value: formatRupees(controller.subtotal),
            ),
            _BillRow(
              label: 'Delivery fee',
              value: controller.deliveryCharge == 0
                  ? 'FREE'
                  : formatRupees(controller.deliveryCharge),
              valueColor: controller.deliveryCharge == 0
                  ? const Color(0xFF147447)
                  : null,
            ),
            const Divider(height: 24),
            _BillRow(
              label: 'To pay',
              value: formatRupees(controller.total),
              emphasize: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = emphasize
        ? Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: style)),
          Text(
            value,
            style: style?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircleAvatar(
              radius: 42,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: const Icon(Icons.shopping_basket_outlined, size: 42),
            ),
            const SizedBox(height: 18),
            Text(
              'Basket abhi khaali hai',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 7),
            const Text(
              'Dukaan se apne daily essentials add karein.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onBrowse,
              icon: const Icon(Icons.storefront_rounded),
              label: const Text('Shop products'),
            ),
          ],
        ),
      ),
    );
  }
}
