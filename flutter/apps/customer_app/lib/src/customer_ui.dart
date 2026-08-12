import 'package:flutter/material.dart';

import 'domain.dart';

abstract final class CustomerPalette {
  static const Color primary = Color(0xFF078A27);
  static const Color primaryDark = Color(0xFF056D1F);
  static const Color primaryLight = Color(0xFFE9F7EA);
  static const Color primarySoft = Color(0xFFF2FAF2);
  static const Color background = Color(0xFFFCFCFA);
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF7F8F5);
  static const Color border = Color(0xFFE7E9E4);
  static const Color textPrimary = Color(0xFF111310);
  static const Color textSecondary = Color(0xFF5F625C);
  static const Color textMuted = Color(0xFF8A8D86);
  static const Color discount = Color(0xFFFFCF31);
  static const Color promoCream = Color(0xFFFFF2D7);
  static const Color warning = Color(0xFFF6A000);
  static const Color danger = Color(0xFFE92720);
}

class CustomerCartButton extends StatelessWidget {
  const CustomerCartButton({
    required this.count,
    required this.onPressed,
    this.tooltip = 'Basket kholein',
    super.key,
  });

  final int count;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          const Icon(Icons.shopping_bag_outlined, size: 25),
          if (count > 0)
            Positioned(
              right: -7,
              top: -7,
              child: Container(
                constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: CustomerPalette.danger,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CustomerSectionHeader extends StatelessWidget {
  const CustomerSectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: CustomerPalette.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: CustomerPalette.primaryDark,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: const Size(48, 36),
            ),
            child: Text(
              actionLabel!,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }
}

class CustomerDiscountPill extends StatelessWidget {
  const CustomerDiscountPill({required this.saving, super.key});

  final double saving;

  @override
  Widget build(BuildContext context) {
    if (saving <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: CustomerPalette.discount,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        '${formatRupees(saving)} OFF',
        style: const TextStyle(
          color: CustomerPalette.textPrimary,
          fontSize: 9,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class CustomerProductImage extends StatelessWidget {
  const CustomerProductImage({
    required this.product,
    this.fit = BoxFit.contain,
    this.padding = const EdgeInsets.all(8),
    this.backgroundColor,
    super.key,
  });

  final CustomerProduct product;
  final BoxFit fit;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final String imageUrl = product.imageUrl.trim();
    final Widget localImage = _CustomerLocalProductImage(
      product: product,
      fit: fit,
    );
    return ColoredBox(
      color: backgroundColor ?? CustomerPalette.surface,
      child: Padding(
        padding: padding,
        child: imageUrl.isEmpty
            ? localImage
            : Image.network(
                imageUrl,
                fit: fit,
                filterQuality: FilterQuality.medium,
                loadingBuilder:
                    (
                      BuildContext context,
                      Widget child,
                      ImageChunkEvent? event,
                    ) {
                      if (event == null) return child;
                      return Center(
                        child: SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: event.expectedTotalBytes == null
                                ? null
                                : event.cumulativeBytesLoaded /
                                      event.expectedTotalBytes!,
                          ),
                        ),
                      );
                    },
                errorBuilder: (_, _, _) => localImage,
              ),
      ),
    );
  }
}

class _CustomerLocalProductImage extends StatelessWidget {
  const _CustomerLocalProductImage({required this.product, required this.fit});

  final CustomerProduct product;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return _CustomerAssetImage(
      assetPath: customerProductAsset(product),
      fit: fit,
      fallback: _ProductFallback(product: product),
    );
  }
}

class CustomerCategoryImage extends StatelessWidget {
  const CustomerCategoryImage({
    required this.category,
    this.fit = BoxFit.contain,
    this.padding = EdgeInsets.zero,
    this.alignment = Alignment.center,
    super.key,
  });

  final String category;
  final BoxFit fit;
  final EdgeInsetsGeometry padding;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: _CustomerAssetImage(
        assetPath: customerCategoryAsset(category),
        fit: fit,
        alignment: alignment,
        fallback: Icon(
          customerCategoryIcon(category),
          color: customerCategoryColor(category),
          size: 30,
        ),
      ),
    );
  }
}

class CustomerPromoImage extends StatelessWidget {
  const CustomerPromoImage({super.key});

  static const String assetPath = 'assets/images/promos/free_delivery.png';

  @override
  Widget build(BuildContext context) {
    return _CustomerAssetImage(
      assetPath: assetPath,
      fit: BoxFit.cover,
      alignment: Alignment.centerRight,
      fallback: const SizedBox.shrink(),
    );
  }
}

class _CustomerAssetImage extends StatelessWidget {
  const _CustomerAssetImage({
    required this.assetPath,
    required this.fit,
    required this.fallback,
    this.alignment = Alignment.center,
  });

  final String assetPath;
  final BoxFit fit;
  final Widget fallback;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double pixelRatio = MediaQuery.devicePixelRatioOf(context);
        final int? cacheWidth = constraints.hasBoundedWidth
            ? (constraints.maxWidth * pixelRatio).ceil().clamp(96, 1200)
            : null;
        final int? cacheHeight = constraints.hasBoundedHeight
            ? (constraints.maxHeight * pixelRatio).ceil().clamp(96, 1200)
            : null;
        return Image.asset(
          assetPath,
          fit: fit,
          alignment: alignment,
          filterQuality: FilterQuality.medium,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
          errorBuilder: (_, _, _) => fallback,
        );
      },
    );
  }
}

String customerProductAsset(CustomerProduct product) {
  final String name = product.name.toLowerCase();
  if (name.contains('aashirvaad') ||
      name.contains('chakki atta') ||
      name.contains('wheat flour')) {
    return 'assets/images/products/atta.png';
  }
  if (name.contains('kachi ghani') || name.contains('mustard')) {
    return 'assets/images/products/mustard_oil.png';
  }
  if (name.contains('ghee')) {
    return 'assets/images/products/ghee.png';
  }
  if (name.contains('tea') || name.contains('coffee')) {
    return 'assets/images/products/tea.png';
  }
  if (name.contains('basmati') || name.contains('rice')) {
    return 'assets/images/products/basmati_rice.png';
  }
  if (name.contains('bhujia') || name.contains('namkeen')) {
    return 'assets/images/products/bhujia.png';
  }
  if (name.contains('sunlite') || name.contains('sunflower')) {
    return 'assets/images/products/sunflower_oil.png';
  }
  if (name.contains('salt')) {
    return 'assets/images/products/salt.png';
  }
  return customerCategoryAsset(product.category);
}

String customerCategoryAsset(String category) {
  final String value = category.toLowerCase();
  if (value.contains('atta') || value.contains('flour')) {
    return 'assets/images/products/atta.png';
  }
  if (value.contains('oil')) {
    return 'assets/images/products/mustard_oil.png';
  }
  if (value.contains('ghee')) {
    return 'assets/images/products/ghee.png';
  }
  if (value.contains('tea') || value.contains('coffee')) {
    return 'assets/images/products/tea.png';
  }
  if (value.contains('rice')) {
    return 'assets/images/products/basmati_rice.png';
  }
  if (value.contains('snack') || value.contains('namkeen')) {
    return 'assets/images/products/bhujia.png';
  }
  if (value.contains('salt') || value.contains('staple')) {
    return 'assets/images/products/salt.png';
  }
  return 'assets/images/categories/all_groceries.png';
}

class _ProductFallback extends StatelessWidget {
  const _ProductFallback({required this.product});

  final CustomerProduct product;

  @override
  Widget build(BuildContext context) {
    final Color accent = customerCategoryColor(product.category);
    final String mark = _brandMark(product.name);
    final BoxDecoration decoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[accent.withValues(alpha: 0.92), accent],
      ),
      borderRadius: BorderRadius.circular(9),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: accent.withValues(alpha: 0.2),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact =
            constraints.maxWidth < 72 || constraints.maxHeight < 88;
        if (compact) {
          final double shortestSide =
              constraints.maxWidth < constraints.maxHeight
              ? constraints.maxWidth
              : constraints.maxHeight;
          final double circleSize = (shortestSide * 0.48)
              .clamp(16.0, 30.0)
              .toDouble();
          return Center(
            child: FractionallySizedBox(
              widthFactor: 0.78,
              heightFactor: 0.78,
              child: DecoratedBox(
                decoration: decoration,
                child: Center(
                  child: Container(
                    width: circleSize,
                    height: circleSize,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      customerCategoryIcon(product.category),
                      color: accent,
                      size: circleSize * 0.58,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        return Center(
          child: FractionallySizedBox(
            widthFactor: 0.62,
            heightFactor: 0.82,
            child: DecoratedBox(
              decoration: decoration,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      mark,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        customerCategoryIcon(product.category),
                        color: accent,
                        size: 21,
                      ),
                    ),
                    Text(
                      product.category.toUpperCase(),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 7.5,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class CustomerPriceLine extends StatelessWidget {
  const CustomerPriceLine({
    required this.price,
    required this.mrp,
    this.priceSize = 15,
    super.key,
  });

  final double price;
  final double mrp;
  final double priceSize;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Text(
          formatRupees(price),
          style: TextStyle(
            color: CustomerPalette.textPrimary,
            fontSize: priceSize,
            height: 1.1,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (mrp > price)
          Text(
            formatRupees(mrp),
            style: const TextStyle(
              color: CustomerPalette.textMuted,
              fontSize: 11,
              decoration: TextDecoration.lineThrough,
            ),
          ),
      ],
    );
  }
}

class CustomerQuantityControl extends StatelessWidget {
  const CustomerQuantityControl({
    required this.quantity,
    required this.max,
    required this.onChanged,
    this.compact = false,
    this.deleteAtOne = false,
    super.key,
  });

  final int quantity;
  final int max;
  final ValueChanged<int> onChanged;
  final bool compact;
  final bool deleteAtOne;

  @override
  Widget build(BuildContext context) {
    final double height = compact ? 36 : 40;
    if (quantity <= 0) {
      return SizedBox(
        height: height,
        child: FilledButton(
          onPressed: max <= 0 ? null : () => onChanged(1),
          style: FilledButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: compact ? 15 : 18),
            minimumSize: Size(compact ? 70 : 96, height),
            backgroundColor: CustomerPalette.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: CustomerPalette.border,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            max <= 0 ? 'OUT' : 'ADD',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
        ),
      );
    }

    return Container(
      height: height,
      constraints: BoxConstraints(minWidth: compact ? 96 : 112),
      decoration: BoxDecoration(
        color: CustomerPalette.primaryLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          _QuantityButton(
            tooltip: quantity == 1 && deleteAtOne
                ? 'Basket se hatayein'
                : 'Quantity kam karein',
            icon: quantity == 1 && deleteAtOne
                ? Icons.delete_outline_rounded
                : Icons.remove_rounded,
            onPressed: () => onChanged(quantity - 1),
            compact: compact,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '$quantity',
              style: const TextStyle(
                color: CustomerPalette.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _QuantityButton(
            tooltip: quantity < max
                ? 'Quantity badhayein'
                : 'Maximum available stock',
            icon: Icons.add_rounded,
            onPressed: quantity < max ? () => onChanged(quantity + 1) : null,
            compact: compact,
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    required this.compact,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: BoxConstraints.tightFor(
        width: compact ? 34 : 38,
        height: compact ? 34 : 38,
      ),
      icon: Icon(icon, size: 18, color: CustomerPalette.primaryDark),
    );
  }
}

class CustomerPrimaryButton extends StatelessWidget {
  const CustomerPrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 52,
    this.busy = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !busy;
    return SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: <Color>[
                    CustomerPalette.primaryDark,
                    CustomerPalette.primary,
                  ],
                )
              : null,
          color: enabled ? null : CustomerPalette.border,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextButton.icon(
          onPressed: busy ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            disabledForegroundColor: CustomerPalette.textMuted,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Icon(icon ?? Icons.arrow_forward_rounded, size: 19),
          label: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class CustomerBottomNavigation extends StatelessWidget {
  const CustomerBottomNavigation({
    required this.selectedIndex,
    required this.cartCount,
    required this.onSelected,
    super.key,
  });

  final int selectedIndex;
  final int cartCount;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    Widget basketIcon(IconData icon) => Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Icon(icon),
        if (cartCount > 0)
          Positioned(
            right: -9,
            top: -7,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: CustomerPalette.danger,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white),
              ),
              alignment: Alignment.center,
              child: Text(
                cartCount > 99 ? '99+' : '$cartCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: CustomerPalette.border)),
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        destinations: <NavigationDestination>[
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront_rounded),
            label: 'Shop',
          ),
          NavigationDestination(
            icon: basketIcon(Icons.shopping_bag_outlined),
            selectedIcon: basketIcon(Icons.shopping_bag_rounded),
            label: 'Basket',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Orders',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

Future<void> showCustomerStoreContactSheet(
  BuildContext context, {
  required CustomerStore store,
  String? orderId,
}) {
  final String hours = <String>[
    store.openingTime.trim(),
    store.closingTime.trim(),
  ].where((String value) => value.isNotEmpty).join(' – ');
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: CustomerPalette.surface,
    builder: (BuildContext sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              orderId == null ? 'Store contact' : 'Order help',
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: 5),
            Text(
              orderId == null
                  ? store.name
                  : 'Order #$orderId  •  ${store.name}',
              style: const TextStyle(
                color: CustomerPalette.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            _StoreContactRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: store.phone.trim().isEmpty
                  ? 'Phone number unavailable'
                  : store.phone.trim(),
            ),
            const SizedBox(height: 12),
            _StoreContactRow(
              icon: Icons.location_on_outlined,
              label: 'Address',
              value: store.address.trim().isEmpty
                  ? 'Address unavailable'
                  : store.address.trim(),
            ),
            if (hours.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              _StoreContactRow(
                icon: Icons.schedule_rounded,
                label: 'Store hours',
                value: hours,
              ),
            ],
            const SizedBox(height: 18),
            CustomerPrimaryButton(
              label: 'Done',
              icon: Icons.check_rounded,
              onPressed: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        ),
      ),
    ),
  );
}

class _StoreContactRow extends StatelessWidget {
  const _StoreContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: CustomerPalette.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: CustomerPalette.primaryDark, size: 20),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: const TextStyle(
                  color: CustomerPalette.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              SelectableText(
                value,
                style: const TextStyle(
                  color: CustomerPalette.textPrimary,
                  fontSize: 12.5,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

IconData customerCategoryIcon(String category) {
  final String value = category.toLowerCase();
  if (value.contains('atta') || value.contains('flour')) {
    return Icons.bakery_dining_rounded;
  }
  if (value.contains('oil')) return Icons.water_drop_rounded;
  if (value.contains('ghee') || value.contains('dairy')) {
    return Icons.breakfast_dining_rounded;
  }
  if (value.contains('rice') || value.contains('dal')) {
    return Icons.grain_rounded;
  }
  if (value.contains('tea') || value.contains('coffee')) {
    return Icons.emoji_food_beverage_rounded;
  }
  if (value.contains('snack') || value.contains('biscuit')) {
    return Icons.cookie_rounded;
  }
  if (value.contains('fruit') || value.contains('vegetable')) {
    return Icons.eco_rounded;
  }
  if (value == 'all') return Icons.grid_view_rounded;
  return Icons.local_grocery_store_rounded;
}

Color customerCategoryColor(String category) {
  final String value = category.toLowerCase();
  if (value.contains('atta') || value.contains('flour')) {
    return const Color(0xFFE86D3C);
  }
  if (value.contains('oil')) return const Color(0xFFF3A712);
  if (value.contains('ghee') || value.contains('dairy')) {
    return const Color(0xFFD58C16);
  }
  if (value.contains('rice') || value.contains('dal')) {
    return const Color(0xFF7E57C2);
  }
  if (value.contains('tea') || value.contains('coffee')) {
    return const Color(0xFF8D6E63);
  }
  if (value.contains('snack') || value.contains('biscuit')) {
    return const Color(0xFFE64A43);
  }
  if (value.contains('fruit') || value.contains('vegetable')) {
    return const Color(0xFF43A047);
  }
  return CustomerPalette.primary;
}

String _brandMark(String name) {
  final List<String> words = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((String word) => word.isNotEmpty)
      .take(3)
      .toList(growable: false);
  if (words.isEmpty) return 'KS';
  if (words.length == 1) {
    final int end = words.first.length < 3 ? words.first.length : 3;
    return words.first.substring(0, end).toUpperCase();
  }
  return words.map((String word) => word[0]).join().toUpperCase();
}
