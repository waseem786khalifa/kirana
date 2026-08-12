import 'package:flutter/material.dart';

import '../customer_controller.dart';
import '../customer_ui.dart';
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
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
            children: <Widget>[
              _DeliveryProgress(controller: controller),
              if (_checkoutBlocker(controller)
                  case final String message) ...<Widget>[
                const SizedBox(height: 10),
                _CheckoutBlocker(message: message),
              ],
              const SizedBox(height: 12),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: List<Widget>.generate(
                    controller.cartLines.length * 2 - 1,
                    (int index) {
                      if (index.isOdd) return const Divider();
                      final CartLine line = controller.cartLines[index ~/ 2];
                      return _CartLine(controller: controller, line: line);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _BillCard(controller: controller),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 11),
            decoration: const BoxDecoration(
              color: CustomerPalette.surface,
              border: Border(top: BorderSide(color: CustomerPalette.border)),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 12,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 104,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text(
                        'Total',
                        style: TextStyle(
                          color: CustomerPalette.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        formatRupees(controller.total),
                        style: const TextStyle(
                          fontSize: 19,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CustomerPrimaryButton(
                    key: const Key('proceed-checkout'),
                    label: controller.amountUntilMinimum > 0
                        ? 'Add ${formatRupees(controller.amountUntilMinimum)} more'
                        : 'Checkout',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: controller.canCheckout ? onCheckout : null,
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

String? _checkoutBlocker(CustomerController controller) {
  final CustomerStore store = controller.selectedStore!;
  if (!store.isOpen) {
    return 'Dukaan abhi band hai. Store open hone par checkout kar sakte hain.';
  }
  if (!store.deliveryAvailable) {
    return 'Is store par home delivery abhi available nahi hai.';
  }
  if (!store.codEnabled && !store.upiEnabled) {
    return 'Store ne abhi koi online order payment method enable nahi kiya hai.';
  }
  return null;
}

class _CheckoutBlocker extends StatelessWidget {
  const _CheckoutBlocker({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CustomerPalette.promoCream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.info_outline_rounded, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 11.5, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryProgress extends StatelessWidget {
  const _DeliveryProgress({required this.controller});

  final CustomerController controller;

  @override
  Widget build(BuildContext context) {
    final CustomerStore store = controller.selectedStore!;
    final bool minimumMet = controller.amountUntilMinimum == 0;
    final bool freeDelivery = controller.deliveryCharge == 0 && minimumMet;
    final double threshold = minimumMet
        ? store.freeDeliveryAbove
        : store.minimumOrder;
    final double progress = threshold <= 0
        ? 1
        : (controller.subtotal / threshold).clamp(0, 1);
    final double remaining = minimumMet
        ? (store.freeDeliveryAbove - controller.subtotal).clamp(
            0,
            double.infinity,
          )
        : controller.amountUntilMinimum;
    final String headline = freeDelivery
        ? 'Yay! Free delivery unlocked'
        : minimumMet
        ? 'Add ${formatRupees(remaining)} for free delivery'
        : 'Add ${formatRupees(remaining)} to place order';
    final String caption = freeDelivery
        ? store.deliveryCharge > 0
              ? 'You saved ${formatRupees(store.deliveryCharge)} on delivery'
              : 'No delivery fee on this order'
        : minimumMet
        ? 'Free delivery above ${formatRupees(store.freeDeliveryAbove)}'
        : 'Minimum order is ${formatRupees(store.minimumOrder)}';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 11),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFF1F9EC), Color(0xFFE8F6E7)],
        ),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: CustomerPalette.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              freeDelivery
                  ? Icons.local_offer_rounded
                  : Icons.shopping_bag_outlined,
              color: CustomerPalette.primary,
              size: 23,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  headline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CustomerPalette.primaryDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CustomerPalette.textSecondary,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    value: progress,
                    backgroundColor: Colors.white,
                    color: CustomerPalette.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          const Icon(
            Icons.delivery_dining_rounded,
            color: CustomerPalette.primaryDark,
            size: 39,
          ),
        ],
      ),
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({required this.controller, required this.line});

  final CustomerController controller;
  final CartLine line;

  @override
  Widget build(BuildContext context) {
    final CustomerProduct product = line.product;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 67,
            height: 76,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: CustomerProductImage(product: product),
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
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.packSize,
                  style: const TextStyle(
                    color: CustomerPalette.textSecondary,
                    fontSize: 10.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formatRupees(line.total),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          CustomerQuantityControl(
            quantity: line.quantity,
            max: product.stock,
            onChanged: (int value) => controller.setQuantity(product, value),
            compact: true,
            deleteAtOne: true,
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
    final CustomerStore store = controller.selectedStore!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Bill details',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
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
                valueColor: CustomerPalette.primaryDark,
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
              oldValue:
                  controller.deliveryCharge == 0 && store.deliveryCharge > 0
                  ? formatRupees(store.deliveryCharge)
                  : null,
              valueColor: controller.deliveryCharge == 0
                  ? CustomerPalette.primaryDark
                  : null,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),
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
    this.oldValue,
    this.valueColor,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final String? oldValue;
  final Color? valueColor;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = TextStyle(
      color: CustomerPalette.textPrimary,
      fontSize: emphasize ? 15 : 12,
      fontWeight: emphasize ? FontWeight.w900 : FontWeight.w500,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: style)),
          if (oldValue != null) ...<Widget>[
            Text(
              oldValue!,
              style: const TextStyle(
                color: CustomerPalette.textMuted,
                fontSize: 10,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            value,
            style: style.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w900,
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
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                color: CustomerPalette.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: CustomerPalette.primaryDark,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Basket abhi khaali hai',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 7),
            const Text(
              'Dukaan se apne daily essentials add karein.',
              textAlign: TextAlign.center,
              style: TextStyle(color: CustomerPalette.textSecondary),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: 210,
              child: CustomerPrimaryButton(
                label: 'Shop products',
                icon: Icons.storefront_rounded,
                onPressed: onBrowse,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
