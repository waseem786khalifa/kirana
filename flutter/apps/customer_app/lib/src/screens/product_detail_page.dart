import 'package:flutter/material.dart';

import '../customer_controller.dart';
import '../customer_ui.dart';
import '../domain.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({
    required this.controller,
    required this.product,
    required this.onGoToBasket,
    super.key,
  });

  final CustomerController controller;
  final CustomerProduct product;
  final VoidCallback onGoToBasket;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  bool _favorite = false;

  CustomerProduct get _product {
    for (final CustomerProduct item in widget.controller.products) {
      if (item.id == widget.product.id) return item;
    }
    return widget.product;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (BuildContext context, Widget? child) {
        final CustomerProduct product = _product;
        final int quantity = widget.controller.quantityFor(product.id);
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            titleSpacing: 0,
            title: const Text('Product details'),
            actions: <Widget>[
              CustomerCartButton(
                count: widget.controller.cartCount,
                onPressed: widget.onGoToBasket,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: CustomScrollView(
            slivers: <Widget>[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                sliver: SliverList.list(
                  children: <Widget>[
                    _ProductMedia(
                      product: product,
                      favorite: _favorite,
                      onFavorite: () => setState(() => _favorite = !_favorite),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      product.category.toUpperCase(),
                      style: const TextStyle(
                        color: CustomerPalette.primaryDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontSize: 22, height: 1.18),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.packSize,
                      style: const TextStyle(
                        color: CustomerPalette.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        CustomerPriceLine(
                          price: product.price,
                          mrp: product.mrp,
                          priceSize: 22,
                        ),
                        if (product.saving > 0) ...<Widget>[
                          const SizedBox(width: 10),
                          CustomerDiscountPill(saving: product.saving),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.stock > 0
                          ? '${product.stock} units available'
                          : 'Currently out of stock',
                      style: TextStyle(
                        color: product.stock > 0
                            ? CustomerPalette.primaryDark
                            : CustomerPalette.danger,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _DeliveryCard(
                      store: widget.controller.selectedStore!,
                      subtotal: widget.controller.subtotal,
                    ),
                    const SizedBox(height: 14),
                    _InfoSection(product: product),
                    const SizedBox(height: 20),
                    const CustomerSectionHeader(title: 'Similar products'),
                    const SizedBox(height: 10),
                    _SimilarProducts(
                      products: widget.controller.products
                          .where(
                            (CustomerProduct item) =>
                                item.id != product.id &&
                                item.category == product.category,
                          )
                          .take(6)
                          .toList(growable: false),
                      controller: widget.controller,
                      onOpen: (CustomerProduct item) {
                        Navigator.of(context).pushReplacement<void, void>(
                          MaterialPageRoute<void>(
                            builder: (BuildContext context) =>
                                ProductDetailPage(
                                  controller: widget.controller,
                                  product: item,
                                  onGoToBasket: widget.onGoToBasket,
                                ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: _PurchaseBar(
            product: product,
            quantity: quantity,
            onQuantityChanged: (int value) =>
                widget.controller.setQuantity(product, value),
            onGoToBasket: widget.onGoToBasket,
          ),
        );
      },
    );
  }
}

class _ProductMedia extends StatelessWidget {
  const _ProductMedia({
    required this.product,
    required this.favorite,
    required this.onFavorite,
  });

  final CustomerProduct product;
  final bool favorite;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 294,
      decoration: BoxDecoration(
        color: CustomerPalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CustomerPalette.border),
      ),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CustomerProductImage(
                product: product,
                padding: const EdgeInsets.fromLTRB(48, 34, 48, 28),
              ),
            ),
          ),
          if (product.saving > 0)
            Positioned(
              left: 13,
              top: 13,
              child: CustomerDiscountPill(saving: product.saving),
            ),
          Positioned(
            right: 10,
            top: 8,
            child: IconButton(
              tooltip: favorite
                  ? 'Favourites se hatayein'
                  : 'Favourites mein add karein',
              onPressed: onFavorite,
              style: IconButton.styleFrom(
                backgroundColor: CustomerPalette.surfaceMuted,
              ),
              icon: Icon(
                favorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: favorite
                    ? CustomerPalette.danger
                    : CustomerPalette.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.store, required this.subtotal});

  final CustomerStore store;
  final double subtotal;

  @override
  Widget build(BuildContext context) {
    final double remaining = (store.freeDeliveryAbove - subtotal).clamp(
      0,
      double.infinity,
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CustomerPalette.primarySoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CustomerPalette.primaryLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: CustomerPalette.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delivery_dining_rounded,
              color: CustomerPalette.primaryDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Delivery in ${store.expectedDeliveryTime}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'From ${store.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CustomerPalette.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  remaining == 0
                      ? 'This basket qualifies for free delivery.'
                      : 'Add ${formatRupees(remaining)} more for free delivery.',
                  style: const TextStyle(
                    color: CustomerPalette.primaryDark,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.product});

  final CustomerProduct product;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          ExpansionTile(
            initiallyExpanded: true,
            tilePadding: const EdgeInsets.symmetric(horizontal: 14),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            title: const Text(
              'Product details',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            children: <Widget>[
              _DetailRow(label: 'Category', value: product.category),
              _DetailRow(label: 'Pack size', value: product.packSize),
              _DetailRow(label: 'Available stock', value: '${product.stock}'),
            ],
          ),
          const Divider(),
          const ExpansionTile(
            tilePadding: EdgeInsets.symmetric(horizontal: 14),
            childrenPadding: EdgeInsets.fromLTRB(14, 0, 14, 14),
            title: Text(
              'Delivery & returns',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            children: <Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Delivery availability and order support are managed by your connected kirana store.',
                  style: TextStyle(
                    color: CustomerPalette.textSecondary,
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: const TextStyle(
                color: CustomerPalette.textSecondary,
                fontSize: 11.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SimilarProducts extends StatelessWidget {
  const _SimilarProducts({
    required this.products,
    required this.controller,
    required this.onOpen,
  });

  final List<CustomerProduct> products;
  final CustomerController controller;
  final ValueChanged<CustomerProduct> onOpen;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Text(
        'No similar products available right now.',
        style: TextStyle(color: CustomerPalette.textSecondary, fontSize: 12),
      );
    }
    return SizedBox(
      height: 188,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (BuildContext context, int index) {
          final CustomerProduct product = products[index];
          return SizedBox(
            width: 142,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onOpen(product),
                child: Padding(
                  padding: const EdgeInsets.all(9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(
                        height: 85,
                        width: double.infinity,
                        child: CustomerProductImage(product: product),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      CustomerPriceLine(
                        price: product.price,
                        mrp: product.mrp,
                        priceSize: 13,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PurchaseBar extends StatelessWidget {
  const _PurchaseBar({
    required this.product,
    required this.quantity,
    required this.onQuantityChanged,
    required this.onGoToBasket,
  });

  final CustomerProduct product;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onGoToBasket;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 11, 16, 12),
        decoration: const BoxDecoration(
          color: CustomerPalette.surface,
          border: Border(top: BorderSide(color: CustomerPalette.border)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 12,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: quantity == 0
            ? CustomerPrimaryButton(
                key: Key('detail-add-${product.id}'),
                label: 'Add to basket  \u2022  ${formatRupees(product.price)}',
                icon: Icons.shopping_bag_outlined,
                onPressed: product.stock <= 0
                    ? null
                    : () => onQuantityChanged(1),
              )
            : Row(
                children: <Widget>[
                  CustomerQuantityControl(
                    quantity: quantity,
                    max: product.stock,
                    onChanged: onQuantityChanged,
                    deleteAtOne: true,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomerPrimaryButton(
                      label: 'Go to basket',
                      icon: Icons.shopping_bag_rounded,
                      onPressed: onGoToBasket,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
