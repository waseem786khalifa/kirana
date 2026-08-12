import 'package:flutter/material.dart';

import '../customer_controller.dart';
import '../customer_ui.dart';
import '../domain.dart';
import 'category_products_page.dart';
import 'product_detail_page.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({
    required this.controller,
    required this.onNavigateTab,
    super.key,
  });

  final CustomerController controller;
  final ValueChanged<int> onNavigateTab;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openCategory(String category) async {
    final int? tab = await Navigator.of(context).push<int>(
      MaterialPageRoute<int>(
        builder: (BuildContext context) => CategoryProductsPage(
          controller: widget.controller,
          initialCategory: category,
        ),
      ),
    );
    if (tab != null && mounted) widget.onNavigateTab(tab);
  }

  Future<void> _openProduct(CustomerProduct product) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ProductDetailPage(
          controller: widget.controller,
          product: product,
          onGoToBasket: () {
            Navigator.of(context).pop();
            widget.onNavigateTab(1);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CustomerController controller = widget.controller;
    final String normalized = _query.trim().toLowerCase();
    final List<CustomerProduct> products = controller.products;
    final List<String> categories =
        products
            .map((CustomerProduct product) => product.category.trim())
            .where((String category) => category.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final List<CustomerProduct> visible = normalized.isEmpty
        ? products.take(4).toList(growable: false)
        : products
              .where(
                (CustomerProduct product) =>
                    product.name.toLowerCase().contains(normalized) ||
                    product.category.toLowerCase().contains(normalized) ||
                    product.packSize.toLowerCase().contains(normalized),
              )
              .toList(growable: false);

    return RefreshIndicator(
      onRefresh: controller.loadProducts,
      child: CustomScrollView(
        key: const PageStorageKey<String>('catalog-scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            sliver: SliverList.list(
              children: <Widget>[
                TextField(
                  key: const Key('catalog-search'),
                  controller: _searchController,
                  onChanged: (String value) => setState(() => _query = value),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Atta, tel, biscuit search karein...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 22),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            tooltip: 'Search clear karein',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close_rounded, size: 20),
                          )
                        : IconButton(
                            tooltip: 'Voice search',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Voice search abhi available nahi hai.',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.mic_none_rounded, size: 21),
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                if (normalized.isEmpty) ...<Widget>[
                  _DeliveryPromo(store: controller.selectedStore!),
                  const SizedBox(height: 14),
                  _CategoryRail(
                    categories: categories,
                    onSelected: _openCategory,
                  ),
                  const SizedBox(height: 17),
                  CustomerSectionHeader(
                    title: 'Popular products',
                    actionLabel: 'View all',
                    onAction: () => _openCategory('All'),
                  ),
                  const SizedBox(height: 8),
                ] else ...<Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Search results',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        '${visible.length} items',
                        style: const TextStyle(
                          color: CustomerPalette.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                if (!controller.selectedStore!.isOpen)
                  const _StoreNotice(
                    icon: Icons.schedule_rounded,
                    text:
                        'Dukaan abhi band hai. Catalogue browse kar sakte hain.',
                  )
                else if (!controller.selectedStore!.deliveryAvailable)
                  const _StoreNotice(
                    icon: Icons.delivery_dining_outlined,
                    text: 'Home delivery abhi available nahi hai.',
                  ),
                if ((!controller.selectedStore!.isOpen ||
                        !controller.selectedStore!.deliveryAvailable) &&
                    visible.isNotEmpty)
                  const SizedBox(height: 10),
                if (controller.catalogError != null)
                  _CatalogError(
                    message: controller.catalogError!,
                    onRetry: controller.loadProducts,
                  ),
              ],
            ),
          ),
          if (controller.loadingCatalog && products.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (controller.catalogError == null && visible.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyCatalog(hasQuery: normalized.isNotEmpty),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 210,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 276,
                ),
                delegate: SliverChildBuilderDelegate((
                  BuildContext context,
                  int index,
                ) {
                  final CustomerProduct product = visible[index];
                  return _ProductGridCard(
                    product: product,
                    quantity: controller.quantityFor(product.id),
                    onTap: () => _openProduct(product),
                    onQuantityChanged: (int value) =>
                        controller.setQuantity(product, value),
                  );
                }, childCount: visible.length),
              ),
            ),
          if (normalized.isEmpty && products.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              sliver: SliverToBoxAdapter(
                child: _BestOfferCard(
                  product: _bestOffer(products),
                  onTap: () => _openProduct(_bestOffer(products)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DeliveryPromo extends StatelessWidget {
  const _DeliveryPromo({required this.store});

  final CustomerStore store;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFFFF3D8), Color(0xFFFFE3A7)],
        ),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Stack(
        children: <Widget>[
          const Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(13)),
              child: CustomerPromoImage(),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    Color(0xFFFFF3D8),
                    Color(0xFFFFF3D8),
                    Color(0x66FFF3D8),
                    Color(0x00FFF3D8),
                  ],
                  stops: <double>[0, 0.48, 0.7, 1],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 112, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'FREE DELIVERY',
                  style: TextStyle(
                    color: CustomerPalette.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'On orders above ${formatRupees(store.freeDeliveryAbove)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CustomerPalette.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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

class _CategoryRail extends StatelessWidget {
  const _CategoryRail({required this.categories, required this.onSelected});

  final List<String> categories;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final List<String> items = <String>['All', ...categories];
    return SizedBox(
      height: 82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (BuildContext context, int index) {
          final String category = items[index];
          final bool selected = index == 0;
          return SizedBox(
            width: 58,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onSelected(category),
              child: Column(
                children: <Widget>[
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: selected
                          ? CustomerPalette.primaryLight
                          : CustomerPalette.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: CustomerPalette.border),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: CustomerCategoryImage(
                        category: category,
                        padding: const EdgeInsets.all(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected
                          ? CustomerPalette.primaryDark
                          : CustomerPalette.textPrimary,
                      fontSize: 9,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  const _ProductGridCard({
    required this.product,
    required this.quantity,
    required this.onTap,
    required this.onQuantityChanged,
  });

  final CustomerProduct product;
  final int quantity;
  final VoidCallback onTap;
  final ValueChanged<int> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                height: 105,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CustomerProductImage(product: product),
                    ),
                    if (product.saving > 0)
                      Positioned(
                        left: 0,
                        top: 0,
                        child: CustomerDiscountPill(saving: product.saving),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 7),
              Text(
                product.packSize,
                style: const TextStyle(
                  color: CustomerPalette.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                height: 34,
                child: Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CustomerPalette.textPrimary,
                    fontSize: 12,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              CustomerPriceLine(price: product.price, mrp: product.mrp),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: CustomerQuantityControl(
                  quantity: quantity,
                  max: product.stock,
                  onChanged: onQuantityChanged,
                  compact: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BestOfferCard extends StatelessWidget {
  const _BestOfferCard({required this.product, required this.onTap});

  final CustomerProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const CustomerSectionHeader(title: 'Best offers for you'),
        const SizedBox(height: 8),
        Material(
          color: const Color(0xFFF0F8E9),
          borderRadius: BorderRadius.circular(13),
          child: InkWell(
            borderRadius: BorderRadius.circular(13),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: CustomerPalette.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.local_offer_rounded,
                      color: CustomerPalette.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          product.saving > 0
                              ? 'Save ${formatRupees(product.saving)}'
                              : 'Everyday value',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: CustomerPalette.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StoreNotice extends StatelessWidget {
  const _StoreNotice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CustomerPalette.promoCream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogError extends StatelessWidget {
  const _CatalogError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            const Icon(Icons.cloud_off_rounded, color: CustomerPalette.danger),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _EmptyCatalog extends StatelessWidget {
  const _EmptyCatalog({required this.hasQuery});

  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.search_off_rounded,
              color: CustomerPalette.textMuted,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              hasQuery
                  ? 'Koi matching product nahi mila'
                  : 'Catalogue khaali hai',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

CustomerProduct _bestOffer(List<CustomerProduct> products) {
  return products.reduce(
    (CustomerProduct best, CustomerProduct product) =>
        product.saving > best.saving ? product : best,
  );
}
