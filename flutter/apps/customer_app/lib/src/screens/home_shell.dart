import 'package:flutter/material.dart';

import '../customer_controller.dart';
import 'cart_page.dart';
import 'catalog_page.dart';
import 'checkout_page.dart';
import 'orders_page.dart';
import 'profile_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({required this.controller, super.key});

  final CustomerController controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  Future<void> _openCheckout() async {
    final bool? placed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) =>
            CheckoutPage(controller: widget.controller),
      ),
    );
    if (!mounted) return;
    if (placed ?? false) setState(() => _index = 2);
  }

  @override
  Widget build(BuildContext context) {
    final CustomerController controller = widget.controller;
    final String title = switch (_index) {
      0 => controller.selectedStore!.name,
      1 => 'Your basket',
      2 => 'My orders',
      _ => 'Profile',
    };

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (_index == 0)
              Text(
                '${controller.selectedStore!.code} • ${controller.selectedStore!.expectedDeliveryTime}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
          ],
        ),
        actions: <Widget>[
          if (_index != 1)
            Badge(
              isLabelVisible: controller.cartCount > 0,
              label: Text('${controller.cartCount}'),
              child: IconButton(
                tooltip: 'Basket kholein',
                onPressed: () => setState(() => _index = 1),
                icon: const Icon(Icons.shopping_basket_outlined),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: <Widget>[
          CatalogPage(controller: controller),
          CartPage(
            controller: controller,
            onBrowse: () => setState(() => _index = 0),
            onCheckout: _openCheckout,
          ),
          OrdersPage(controller: controller),
          ProfilePage(controller: controller),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int value) => setState(() => _index = value),
        destinations: <NavigationDestination>[
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront_rounded),
            label: 'Shop',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: controller.cartCount > 0,
              label: Text('${controller.cartCount}'),
              child: const Icon(Icons.shopping_basket_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: controller.cartCount > 0,
              label: Text('${controller.cartCount}'),
              child: const Icon(Icons.shopping_basket_rounded),
            ),
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
