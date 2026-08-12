import 'package:flutter/material.dart';

import '../customer_controller.dart';
import '../customer_ui.dart';
import '../domain.dart';
import 'product_detail_page.dart';

class CategoryProductsPage extends StatefulWidget {
  const CategoryProductsPage({
    required this.controller,
    required this.initialCategory,
    super.key,
  });

  final CustomerController controller;
  final String initialCategory;

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  final TextEditingController _searchController = TextEditingController();
  late String _category;
  bool _showSearch = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openProduct(CustomerProduct product) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ProductDetailPage(
          controller: widget.controller,
          product: product,
          onGoToBasket: () {
            Navigator.of(context).pop();
            if (mounted) Navigator.of(context).pop(1);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CustomerController controller = widget.controller;
    final List<String> categories =
        controller.products
            .map((CustomerProduct product) => product.category.trim())
            .where((String category) => category.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final List<String> filters = <String>['All', ...categories];
    if (!filters.contains(_category)) _category = 'All';
    final String query = _query.trim().toLowerCase();
    final List<CustomerProduct> products = controller.products
        .where((CustomerProduct product) {
          final bool categoryMatches =
              _category == 'All' || product.category == _category;
          final bool queryMatches =
              query.isEmpty ||
              product.name.toLowerCase().contains(query) ||
              product.packSize.toLowerCase().contains(query);
          return categoryMatches && queryMatches;
        })
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        titleSpacing: 0,
        title: Text(_category == 'All' ? 'All products' : _category),
        actions: <Widget>[
          IconButton(
            tooltip: 'Search products',
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  _query = '';
                }
              });
            },
            icon: Icon(
              _showSearch ? Icons.close_rounded : Icons.search_rounded,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.loadProducts,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 26),
          children: <Widget>[
            if (_showSearch) ...<Widget>[
              TextField(
                autofocus: true,
                controller: _searchController,
                onChanged: (String value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  hintText: 'Search in this category',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 12),
            ],
            _CategoryBanner(category: _category),
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (BuildContext context, int index) {
                  final String filter = filters[index];
                  final bool selected = filter == _category;
                  return ChoiceChip(
                    label: Text(filter),
                    selected: selected,
                    showCheckmark: false,
                    selectedColor: CustomerPalette.primary,
                    backgroundColor: CustomerPalette.surface,
                    side: const BorderSide(color: CustomerPalette.border),
                    labelStyle: TextStyle(
                      color: selected
                          ? Colors.white
                          : CustomerPalette.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    onSelected: (_) => setState(() => _category = filter),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            if (controller.catalogError != null) ...<Widget>[
              _CategoryError(
                message: controller.catalogError!,
                onRetry: controller.loadProducts,
              ),
              const SizedBox(height: 12),
            ],
            if (controller.loadingCatalog && controller.products.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 100),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (products.isEmpty &&
                !(controller.catalogError != null &&
                    controller.products.isEmpty))
              const _EmptyCategory()
            else
              ...products.map(
                (CustomerProduct product) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _ProductListTile(
                    product: product,
                    quantity: controller.quantityFor(product.id),
                    onTap: () => _openProduct(product),
                    onQuantityChanged: (int value) =>
                        controller.setQuantity(product, value),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: CustomerBottomNavigation(
        selectedIndex: 0,
        cartCount: controller.cartCount,
        onSelected: (int index) {
          if (index == 0) {
            Navigator.of(context).pop();
          } else {
            Navigator.of(context).pop(index);
          }
        },
      ),
    );
  }
}

class _CategoryError extends StatelessWidget {
  const _CategoryError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECE9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.cloud_off_rounded, color: CustomerPalette.danger),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, height: 1.3),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _CategoryBanner extends StatelessWidget {
  const _CategoryBanner({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final String title = category == 'All'
        ? 'Everyday essentials'
        : 'Best quality ${category.toLowerCase()}';
    final Color accent = customerCategoryColor(category);
    return Container(
      height: 106,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            const Color(0xFFFFF1DC),
            accent.withValues(alpha: 0.16),
          ],
        ),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Stack(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 118, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CustomerPalette.danger,
                    fontSize: 15,
                    height: 1.18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Explore now  \u2192',
                  style: TextStyle(
                    color: CustomerPalette.danger,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 25,
            top: 15,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: CustomerCategoryImage(
                  category: category,
                  fit: BoxFit.cover,
                  padding: const EdgeInsets.all(5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductListTile extends StatelessWidget {
  const _ProductListTile({
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
          padding: const EdgeInsets.all(10),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 72,
                height: 84,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: CustomerProductImage(product: product),
                      ),
                    ),
                    if (product.saving > 0)
                      Positioned(
                        left: -2,
                        top: -2,
                        child: CustomerDiscountPill(saving: product.saving),
                      ),
                  ],
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
                        height: 1.22,
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
                    const SizedBox(height: 9),
                    CustomerPriceLine(price: product.price, mrp: product.mrp),
                  ],
                ),
              ),
              const SizedBox(width: 9),
              CustomerQuantityControl(
                quantity: quantity,
                max: product.stock,
                onChanged: onQuantityChanged,
                compact: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCategory extends StatelessWidget {
  const _EmptyCategory();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 90),
      child: Column(
        children: <Widget>[
          Icon(
            Icons.inventory_2_outlined,
            size: 46,
            color: CustomerPalette.textMuted,
          ),
          SizedBox(height: 12),
          Text('Is category mein abhi products nahi hain.'),
        ],
      ),
    );
  }
}
