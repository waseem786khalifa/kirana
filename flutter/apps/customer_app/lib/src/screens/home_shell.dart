import 'package:flutter/material.dart';

import '../customer_controller.dart';
import '../customer_ui.dart';
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

  void _selectTab(int value) {
    if (value < 0 || value > 3 || value == _index) return;
    setState(() => _index = value);
  }

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

  Future<void> _confirmStoreChange() async {
    final bool? change = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      backgroundColor: CustomerPalette.surface,
      builder: (BuildContext context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Connected store',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                widget.controller.selectedStore!.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                widget.controller.selectedStore!.address,
                style: const TextStyle(color: CustomerPalette.textSecondary),
              ),
              if (widget.controller.cartCount > 0) ...<Widget>[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: CustomerPalette.promoCream,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Store change karne par current basket clear ho jayegi.',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              CustomerPrimaryButton(
                label: 'Change store',
                icon: Icons.swap_horiz_rounded,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ),
      ),
    );
    if ((change ?? false) && mounted) await widget.controller.changeStore();
  }

  @override
  Widget build(BuildContext context) {
    final CustomerController controller = widget.controller;
    final String title = switch (_index) {
      1 => 'Your basket',
      2 => 'My orders',
      3 => 'Profile',
      _ => controller.selectedStore!.name,
    };

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: _index == 0 ? 72 : 62,
        titleSpacing: 20,
        title: _index == 0
            ? InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _confirmStoreChange,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 19,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${controller.selectedStore!.code}  \u2022  ${controller.selectedStore!.expectedDeliveryTime}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: CustomerPalette.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Text(title),
        actions: <Widget>[
          CustomerCartButton(
            count: controller.cartCount,
            onPressed: () => _selectTab(1),
          ),
          const SizedBox(width: 9),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: <Widget>[
          CatalogPage(controller: controller, onNavigateTab: _selectTab),
          CartPage(
            controller: controller,
            onBrowse: () => _selectTab(0),
            onCheckout: _openCheckout,
          ),
          OrdersPage(controller: controller),
          ProfilePage(controller: controller),
        ],
      ),
      bottomNavigationBar: CustomerBottomNavigation(
        selectedIndex: _index,
        cartCount: controller.cartCount,
        onSelected: _selectTab,
      ),
    );
  }
}
