import 'package:flutter/material.dart';

import '../customer_controller.dart';
import '../domain.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({required this.controller, super.key});

  final CustomerController controller;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _category = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CustomerController controller = widget.controller;
    final List<String> categories = <String>[
      'All',
      ...controller.products
          .map((CustomerProduct item) => item.category)
          .toSet()
          .toList()
        ..sort(),
    ];
    if (!categories.contains(_category)) _category = 'All';
    final String normalized = _query.trim().toLowerCase();
    final List<CustomerProduct> visible = controller.products
        .where((CustomerProduct product) {
          final bool categoryMatches =
              _category == 'All' || product.category == _category;
          final bool searchMatches =
              normalized.isEmpty ||
              product.name.toLowerCase().contains(normalized) ||
              product.category.toLowerCase().contains(normalized) ||
              product.packSize.toLowerCase().contains(normalized);
          return categoryMatches && searchMatches;
        })
        .toList(growable: false);

    return RefreshIndicator(
      onRefresh: controller.loadProducts,
      child: CustomScrollView(
        key: const PageStorageKey<String>('catalog-scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverList.list(
              children: <Widget>[
                if (!controller.selectedStore!.isOpen)
                  const _NoticeBanner(
                    icon: Icons.schedule_rounded,
                    text:
                        'Dukaan abhi band hai. Aap catalogue dekh sakte hain, order open hone par place hoga.',
                  )
                else if (!controller.selectedStore!.deliveryAvailable)
                  const _NoticeBanner(
                    icon: Icons.delivery_dining_outlined,
                    text: 'Home delivery abhi available nahi hai.',
                  ),
                if (!controller.selectedStore!.isOpen ||
                    !controller.selectedStore!.deliveryAvailable)
                  const SizedBox(height: 12),
                TextField(
                  key: const Key('catalog-search'),
                  controller: _searchController,
                  onChanged: (String value) => setState(() => _query = value),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Atta, tel, biscuit search karein…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Search clear karein',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (BuildContext context, int index) {
                      final String item = categories[index];
                      return ChoiceChip(
                        label: Text(item),
                        selected: _category == item,
                        onSelected: (_) => setState(() => _category = item),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _category == 'All' ? 'Popular products' : _category,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text('${visible.length} items'),
                  ],
                ),
                const SizedBox(height: 12),
                if (controller.catalogError != null)
                  _CatalogError(
                    message: controller.catalogError!,
                    onRetry: controller.loadProducts,
                  ),
              ],
            ),
          ),
          if (controller.loadingCatalog && controller.products.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (controller.catalogError == null && visible.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyCatalog(
                hasFilter: normalized.isNotEmpty || _category != 'All',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              sliver: SliverLayoutBuilder(
                builder: (BuildContext context, constraints) {
                  final int columns = constraints.crossAxisExtent >= 900
                      ? 4
                      : constraints.crossAxisExtent >= 600
                      ? 3
                      : 2;
                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 304,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) => _ProductCard(
                        product: visible[index],
                        quantity: controller.quantityFor(visible[index].id),
                        onQuantityChanged: (int quantity) =>
                            controller.setQuantity(visible[index], quantity),
                      ),
                      childCount: visible.length,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.quantity,
    required this.onQuantityChanged,
  });

  final CustomerProduct product;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool outOfStock = product.stock <= 0;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Stack(
                children: <Widget>[
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: product.imageUrl.isEmpty
                        ? const Icon(Icons.inventory_2_outlined, size: 54)
                        : Image.network(
                            product.imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.inventory_2_outlined,
                              size: 54,
                            ),
                          ),
                  ),
                  if (product.saving > 0 && !outOfStock)
                    Positioned(
                      left: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFCA4B),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${formatRupees(product.saving)} OFF',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              product.packSize,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: <Widget>[
                Text(
                  formatRupees(product.price),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (product.mrp > product.price) ...<Widget>[
                  const SizedBox(width: 6),
                  Text(
                    formatRupees(product.mrp),
                    style: theme.textTheme.bodySmall?.copyWith(
                      decoration: TextDecoration.lineThrough,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            if (outOfStock)
              const SizedBox(
                height: 42,
                width: double.infinity,
                child: FilledButton(
                  onPressed: null,
                  child: Text('Out of stock'),
                ),
              )
            else if (quantity == 0)
              SizedBox(
                height: 42,
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  key: Key('add-product-${product.id}'),
                  onPressed: () => onQuantityChanged(1),
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                  label: const Text('ADD'),
                ),
              )
            else
              _QuantityPicker(
                quantity: quantity,
                canIncrease: quantity < product.stock,
                onDecrease: () => onQuantityChanged(quantity - 1),
                onIncrease: () => onQuantityChanged(quantity + 1),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuantityPicker extends StatelessWidget {
  const _QuantityPicker({
    required this.quantity,
    required this.canIncrease,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final bool canIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          IconButton(
            tooltip: 'Quantity kam karein',
            onPressed: onDecrease,
            color: Colors.white,
            icon: const Icon(Icons.remove_rounded, size: 19),
          ),
          Text(
            '$quantity',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          IconButton(
            tooltip: canIncrease
                ? 'Quantity badhayein'
                : 'Maximum stock cart mein hai',
            onPressed: canIncrease ? onIncrease : null,
            color: Colors.white,
            disabledColor: Colors.white38,
            icon: const Icon(Icons.add_rounded, size: 19),
          ),
        ],
      ),
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
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
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.cloud_off_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
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
  const _EmptyCatalog({required this.hasFilter});

  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.search_off_rounded, size: 52),
            const SizedBox(height: 10),
            Text(
              hasFilter
                  ? 'Is search mein koi product nahi mila.'
                  : 'Catalogue abhi khaali hai.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text('Pull down karke refresh karein.'),
          ],
        ),
      ),
    );
  }
}
