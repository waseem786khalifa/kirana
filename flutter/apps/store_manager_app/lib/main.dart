import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kirana_core/kirana_core.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KiranaManagerApp());
}

class KiranaManagerApp extends StatelessWidget {
  const KiranaManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF087F5B),
      brightness: Brightness.light,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kirana Manager',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF6F8F7),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
            side: BorderSide(color: Color(0xFFE3E9E6)),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const ManagerHome(),
    );
  }
}

enum _ManagerTab { dashboard, orders, inventory, team }

class ManagerHome extends StatefulWidget {
  const ManagerHome({super.key});

  @override
  State<ManagerHome> createState() => _ManagerHomeState();
}

class _ManagerHomeState extends State<ManagerHome> {
  final KiranaApi _api = KiranaApi();
  final TextEditingController _productSearch = TextEditingController();

  List<Store> _stores = <Store>[];
  List<Order> _orders = <Order>[];
  List<Product> _products = <Product>[];
  List<DeliveryStaff> _staff = <DeliveryStaff>[];
  Store? _store;
  Timer? _poller;
  _ManagerTab _tab = _ManagerTab.dashboard;
  bool _loading = true;
  bool _refreshing = false;
  int _refreshRequestId = 0;
  String? _error;
  String _orderFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _poller?.cancel();
    _productSearch.dispose();
    _api.close();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final stores = await _api.getStores();
      if (stores.isEmpty) {
        throw ApiException(
          code: 'NO_STORE',
          message: 'No store is configured yet.',
        );
      }
      if (!mounted) return;
      setState(() {
        _stores = stores;
        _store = stores.first;
      });
      await _refresh();
      _poller = Timer.periodic(const Duration(seconds: 12), (_) {
        if (mounted && !_refreshing) _refresh(silent: true);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh({bool silent = false}) async {
    final store = _store;
    if (store == null) return;
    final requestId = ++_refreshRequestId;
    setState(() {
      _refreshing = true;
      if (!silent) _error = null;
    });
    try {
      final result = await Future.wait<Object>(<Future<Object>>[
        _api.getOrders(storeId: store.id),
        _api.getProducts(storeId: store.id),
        _api.getDeliveryStaff(storeId: store.id),
      ]);
      if (!mounted ||
          requestId != _refreshRequestId ||
          _store?.id != store.id) {
        return;
      }
      setState(() {
        _orders = result[0] as List<Order>;
        _products = result[1] as List<Product>;
        _staff = result[2] as List<DeliveryStaff>;
        _error = null;
      });
    } catch (error) {
      if (mounted &&
          requestId == _refreshRequestId &&
          _store?.id == store.id &&
          !silent) {
        setState(() => _error = _friendlyError(error));
      }
    } finally {
      if (mounted && requestId == _refreshRequestId) {
        setState(() => _refreshing = false);
      }
    }
  }

  Future<void> _selectStore(Store? value) async {
    if (value == null || value.id == _store?.id) return;
    setState(() {
      _store = value;
      _orders = <Order>[];
      _products = <Product>[];
      _staff = <DeliveryStaff>[];
    });
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const _LoadingPage(label: 'Store dashboard load ho raha hai…');
    }

    if (_store == null) {
      return _FailurePage(
        message: _error ?? 'Store nahi mila',
        onRetry: _bootstrap,
      );
    }

    final store = _store!;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Kirana Manager',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            Text(
              'Code: ${store.code}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: <Widget>[
          if (_stores.length > 1)
            DropdownButtonHideUnderline(
              child: DropdownButton<Store>(
                value: store,
                dropdownColor: Theme.of(context).colorScheme.primaryContainer,
                iconEnabledColor: Colors.white,
                selectedItemBuilder: (_) => _stores
                    .map(
                      (item) => Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                items: _stores
                    .map(
                      (item) => DropdownMenuItem<Store>(
                        value: item,
                        child: Text(item.name),
                      ),
                    )
                    .toList(),
                onChanged: _selectStore,
              ),
            ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refreshing ? null : _refresh,
            icon: _refreshing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          if (_error != null)
            MaterialBanner(
              content: Text(_error!),
              leading: const Icon(Icons.cloud_off_rounded),
              actions: <Widget>[
                TextButton(onPressed: _refresh, child: const Text('RETRY')),
              ],
            ),
          Expanded(child: _buildBody(store)),
        ],
      ),
      floatingActionButton: _tab == _ManagerTab.inventory
          ? FloatingActionButton.extended(
              onPressed: _showAddProduct,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Product'),
            )
          : _tab == _ManagerTab.team
          ? FloatingActionButton.extended(
              onPressed: _showAddStaff,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Delivery staff'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab.index,
        onDestinationSelected: (index) =>
            setState(() => _tab = _ManagerTab.values[index]),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Inventory',
          ),
          NavigationDestination(
            icon: Icon(Icons.delivery_dining_outlined),
            selectedIcon: Icon(Icons.delivery_dining),
            label: 'Team',
          ),
        ],
      ),
    );
  }

  Widget _buildBody(Store store) {
    switch (_tab) {
      case _ManagerTab.dashboard:
        return _dashboard(store);
      case _ManagerTab.orders:
        return _ordersPage();
      case _ManagerTab.inventory:
        return _inventoryPage();
      case _ManagerTab.team:
        return _teamPage();
    }
  }

  Widget _dashboard(Store store) {
    final newOrders = _orders
        .where((order) => _statusWire(order.status) == 'NEW')
        .length;
    final active = _orders
        .where(
          (order) => !<String>{
            'DELIVERED',
            'CANCELLED',
          }.contains(_statusWire(order.status)),
        )
        .length;
    final delivered = _orders
        .where((order) => _statusWire(order.status) == 'DELIVERED')
        .toList();
    final sales = delivered.fold<double>(
      0,
      (sum, order) => sum + order.totalAmount,
    );
    final lowStock = _products.where((product) => product.stock <= 5).length;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: <Widget>[
          Text(
            store.name,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(store.address, style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.65,
            children: <Widget>[
              _StatCard(
                label: 'New orders',
                value: '$newOrders',
                icon: Icons.notifications_active_outlined,
                color: Colors.deepOrange,
              ),
              _StatCard(
                label: 'Active orders',
                value: '$active',
                icon: Icons.sync_rounded,
                color: Colors.blue,
              ),
              _StatCard(
                label: 'Delivered sales',
                value: _inr(sales),
                icon: Icons.currency_rupee_rounded,
                color: Colors.green,
              ),
              _StatCard(
                label: 'Low stock',
                value: '$lowStock',
                icon: Icons.warning_amber_rounded,
                color: Colors.amber.shade800,
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Recent orders',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              TextButton(
                onPressed: () => setState(() => _tab = _ManagerTab.orders),
                child: const Text('View all'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_orders.isEmpty)
            const _EmptyCard(
              icon: Icons.receipt_long_outlined,
              message: 'Abhi koi order nahi hai',
            )
          else
            ..._orders
                .take(4)
                .map(
                  (order) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _compactOrder(order),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _compactOrder(Order order) {
    final color = _statusColor(_statusWire(order.status));
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: .12),
          foregroundColor: color,
          child: const Icon(Icons.shopping_bag_outlined),
        ),
        title: Text(
          '#${order.id} • ${order.customerName}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${order.items.length} item(s) • ${_statusLabel(_statusWire(order.status))}',
        ),
        trailing: Text(
          _inr(order.totalAmount),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        onTap: () => setState(() => _tab = _ManagerTab.orders),
      ),
    );
  }

  Widget _ordersPage() {
    const filters = <String>[
      'ALL',
      'NEW',
      'ACCEPTED',
      'PREPARING',
      'READY',
      'OUT_FOR_DELIVERY',
      'DELIVERED',
      'CANCELLED',
    ];
    final visible = _orders
        .where(
          (order) =>
              _orderFilter == 'ALL' ||
              _statusWire(order.status) == _orderFilter,
        )
        .toList();
    return Column(
      children: <Widget>[
        SizedBox(
          height: 58,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 7),
            itemBuilder: (_, index) {
              final filter = filters[index];
              return ChoiceChip(
                selected: _orderFilter == filter,
                label: Text(filter == 'ALL' ? 'All' : _statusLabel(filter)),
                onSelected: (_) => setState(() => _orderFilter = filter),
              );
            },
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: visible.isEmpty
                ? ListView(
                    children: const <Widget>[
                      SizedBox(height: 100),
                      _EmptyCard(
                        icon: Icons.inbox_outlined,
                        message: 'Is status mein koi order nahi hai',
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, index) => _orderCard(visible[index]),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _orderCard(Order order) {
    final status = _statusWire(order.status);
    final color = _statusColor(status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '#${order.id} • ${order.customerName}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              order.customerPhone,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            Text(
              order.deliveryAddress.addressLine,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Divider(height: 22),
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: <Widget>[
                    Expanded(child: Text('${item.quantity} × ${item.nameEn}')),
                    Text(_inr(item.price * item.quantity)),
                  ],
                ),
              ),
            ),
            const Divider(height: 20),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${order.paymentMethod.name.toUpperCase()} • ${order.items.length} item(s)',
                  ),
                ),
                Text(
                  _inr(order.totalAmount),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _orderActions(order, status),
          ],
        ),
      ),
    );
  }

  Widget _orderActions(Order order, String status) {
    switch (status) {
      case 'NEW':
        return Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton(
                onPressed: () => _updateStatus(
                  order,
                  'CANCELLED',
                  rejectionReason: 'Rejected by store',
                ),
                child: const Text('Reject'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: () => _updateStatus(order, 'ACCEPTED'),
                child: const Text('Accept'),
              ),
            ),
          ],
        );
      case 'ACCEPTED':
        return SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => _updateStatus(order, 'PREPARING'),
            child: const Text('Start preparing'),
          ),
        );
      case 'PREPARING':
        return SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => _updateStatus(order, 'READY'),
            child: const Text('Mark ready'),
          ),
        );
      case 'READY':
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _assignDelivery(order),
            icon: const Icon(Icons.delivery_dining),
            label: const Text('Assign delivery staff'),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<bool> _updateStatus(
    Order order,
    String target, {
    int? deliveryStaffId,
    String? rejectionReason,
  }) async {
    final status = _enumStatus(target);
    if (status == null) return false;
    try {
      await _api.updateOrderStatus(
        order.id,
        status,
        deliveryStaffId: deliveryStaffId,
        rejectionReason: rejectionReason,
      );
      await _refresh(silent: true);
      return true;
    } catch (error) {
      _showError(error);
      return false;
    }
  }

  Future<void> _assignDelivery(Order order) async {
    if (_staff.where((item) => item.isActive).isEmpty) {
      _showMessage('Pehle ek active delivery staff add karein.');
      return;
    }
    final selected = await showModalBottomSheet<DeliveryStaff>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          children: <Widget>[
            Text(
              'Assign delivery staff',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            ..._staff
                .where((item) => item.isActive)
                .map(
                  (item) => ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.delivery_dining),
                    ),
                    title: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(item.mobile),
                    onTap: () => Navigator.pop(context, item),
                  ),
                ),
          ],
        ),
      ),
    );
    if (selected != null) {
      final assigned = await _updateStatus(
        order,
        'READY',
        deliveryStaffId: selected.id,
      );
      if (assigned && mounted) {
        _showMessage('Order ${selected.name} ko assign ho gaya.');
      }
    }
  }

  Widget _inventoryPage() {
    final query = _productSearch.text.trim().toLowerCase();
    final visible = _products.where((product) {
      return query.isEmpty ||
          product.nameEn.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query);
    }).toList();
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
        children: <Widget>[
          TextField(
            controller: _productSearch,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search product or category',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            const _EmptyCard(
              icon: Icons.inventory_2_outlined,
              message: 'Product nahi mila',
            )
          else
            ...visible.map(
              (product) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _productCard(product),
              ),
            ),
        ],
      ),
    );
  }

  Widget _productCard(Product product) {
    final low = product.stock <= 5;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 25,
              backgroundColor: low
                  ? Colors.orange.shade50
                  : Colors.green.shade50,
              foregroundColor: low
                  ? Colors.orange.shade800
                  : Colors.green.shade800,
              child: Icon(
                low ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    product.nameEn,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    '${product.packSize} • ${_inr(product.sellingPrice)}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  Text(
                    'Stock: ${product.stock}',
                    style: TextStyle(
                      color: low ? Colors.deepOrange : Colors.green.shade800,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: <Widget>[
                Switch(
                  value: product.availableForOnline && !product.isHidden,
                  onChanged: (value) => _toggleProduct(product, value),
                ),
                IconButton(
                  tooltip: 'Update stock',
                  onPressed: () => _editStock(product),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleProduct(Product product, bool value) async {
    try {
      await _api.updateProduct(product.id, <String, dynamic>{
        'available_for_online': value,
        'is_hidden': !value,
      });
      await _refresh(silent: true);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _editStock(Product product) async {
    final controller = TextEditingController(text: '${product.stock}');
    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${product.nameEn} stock'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Available quantity'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, int.tryParse(controller.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value < 0) return;
    try {
      await _api.updateProduct(product.id, <String, dynamic>{'stock': value});
      await _refresh(silent: true);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _showAddProduct() async {
    final name = TextEditingController();
    final category = TextEditingController(text: 'Grocery');
    final pack = TextEditingController(text: '1 unit');
    final mrp = TextEditingController();
    final price = TextEditingController();
    final stock = TextEditingController(text: '10');
    final key = GlobalKey<FormState>();
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add product'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: key,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: 'Product name',
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    validator: _required,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: pack,
                    decoration: const InputDecoration(labelText: 'Pack size'),
                    validator: _required,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextFormField(
                          controller: mrp,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'MRP'),
                          validator: _positiveNumber,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: price,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Selling price',
                          ),
                          validator: _positiveNumber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: stock,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Stock'),
                    validator: _nonNegativeNumber,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (key.currentState!.validate()) Navigator.pop(context, true);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (save == true && _store != null) {
      try {
        await _api.createProduct(<String, dynamic>{
          'store_id': _store!.id,
          'name_en': name.text.trim(),
          'name_hi': name.text.trim(),
          'category': category.text.trim(),
          'pack_size': pack.text.trim(),
          'mrp': double.parse(mrp.text),
          'selling_price': double.parse(price.text),
          'stock': int.parse(stock.text),
          'available_for_online': true,
        });
        await _refresh(silent: true);
      } catch (error) {
        _showError(error);
      }
    }
    name.dispose();
    category.dispose();
    pack.dispose();
    mrp.dispose();
    price.dispose();
    stock.dispose();
  }

  Widget _teamPage() {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 100),
        children: <Widget>[
          Text(
            'Delivery team',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          Text(
            'Rider mobile aur PIN se Delivery app mein login karega.',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 14),
          if (_staff.isEmpty)
            const _EmptyCard(
              icon: Icons.delivery_dining_outlined,
              message: 'Delivery staff add nahi hua',
            )
          else
            ..._staff.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      child: Text(
                        item.name.isEmpty ? '?' : item.name[0].toUpperCase(),
                      ),
                    ),
                    title: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text(item.mobile),
                    trailing: Chip(
                      avatar: Icon(
                        item.isActive ? Icons.check_circle : Icons.pause_circle,
                        size: 17,
                      ),
                      label: Text(item.isActive ? 'Active' : 'Paused'),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showAddStaff() async {
    final name = TextEditingController();
    final mobile = TextEditingController();
    final pin = TextEditingController();
    final key = GlobalKey<FormState>();
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add delivery staff'),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: _required,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: mobile,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(labelText: 'Mobile'),
                validator: _mobile,
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: pin,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration: const InputDecoration(labelText: '4-digit PIN'),
                validator: _pin,
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (key.currentState!.validate()) Navigator.pop(context, true);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (save == true && _store != null) {
      try {
        await _api.createDeliveryStaff(<String, dynamic>{
          'store_id': _store!.id,
          'name': name.text.trim(),
          'mobile': mobile.text.trim(),
          'pin': pin.text,
        });
        await _refresh(silent: true);
      } catch (error) {
        _showError(error);
      }
    }
    name.dispose();
    mobile.dispose();
    pin.dispose();
  }

  OrderStatus? _enumStatus(String wire) {
    for (final value in OrderStatus.values) {
      if (_statusWire(value) == wire) return value;
    }
    return null;
  }

  String _statusWire(OrderStatus status) {
    switch (status.name) {
      case 'newOrder':
      case 'new':
        return 'NEW';
      case 'outForDelivery':
        return 'OUT_FOR_DELIVERY';
      default:
        return status.name
            .replaceAllMapped(RegExp(r'([A-Z])'), (match) => '_${match[1]}')
            .toUpperCase();
    }
  }

  String _statusLabel(String value) => value
      .split('_')
      .map(
        (part) => part.isEmpty
            ? part
            : '${part[0]}${part.substring(1).toLowerCase()}',
      )
      .join(' ');

  Color _statusColor(String status) {
    switch (status) {
      case 'NEW':
        return Colors.deepOrange;
      case 'ACCEPTED':
        return Colors.blue;
      case 'PREPARING':
        return Colors.purple;
      case 'READY':
        return Colors.teal;
      case 'OUT_FOR_DELIVERY':
        return Colors.indigo;
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _friendlyError(Object error) {
    if (error is ApiException) return error.message;
    return 'Server se connect nahi ho paaya. API URL aur XAMPP check karein.';
  }

  void _showError(Object error) => _showMessage(_friendlyError(error));

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  static String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;
  static String? _mobile(String? value) =>
      RegExp(r'^\d{10}$').hasMatch(value ?? '')
      ? null
      : '10-digit mobile enter karein';
  static String? _pin(String? value) => RegExp(r'^\d{4}$').hasMatch(value ?? '')
      ? null
      : '4-digit PIN enter karein';
  static String? _positiveNumber(String? value) =>
      (double.tryParse(value ?? '') ?? 0) > 0
      ? null
      : 'Positive amount enter karein';
  static String? _nonNegativeNumber(String? value) =>
      (int.tryParse(value ?? '') ?? -1) >= 0
      ? null
      : 'Valid stock enter karein';
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              backgroundColor: color.withValues(alpha: .12),
              foregroundColor: color,
              child: Icon(icon),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
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

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 42),
        child: Column(
          children: <Widget>[
            Icon(icon, size: 42, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingPage extends StatelessWidget {
  const _LoadingPage({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _FailurePage extends StatelessWidget {
  const _FailurePage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.cloud_off_rounded, size: 58),
              const SizedBox(height: 14),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _inr(num value) {
  final fixed = value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
  return '₹$fixed';
}
