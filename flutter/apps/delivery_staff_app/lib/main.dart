import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kirana_core/kirana_core.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KiranaDeliveryApp());
}

class KiranaDeliveryApp extends StatelessWidget {
  const KiranaDeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kirana Delivery',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF075985)),
        scaffoldBackgroundColor: const Color(0xFFF5F8FA),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(15)),
            borderSide: BorderSide.none,
          ),
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            side: BorderSide(color: Color(0xFFDDE7EC)),
          ),
        ),
      ),
      home: const DeliveryRoot(),
    );
  }
}

class DeliveryRoot extends StatefulWidget {
  const DeliveryRoot({super.key});

  @override
  State<DeliveryRoot> createState() => _DeliveryRootState();
}

class _DeliveryRootState extends State<DeliveryRoot> {
  final KiranaApi _api = KiranaApi();
  DeliveryStaff? _staff;
  String? _token;

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  void _loggedIn(DeliveryLoginResult result) {
    _api.bearerToken = result.token;
    setState(() {
      _staff = result.staff;
      _token = result.token;
    });
  }

  void _logout() {
    _api.bearerToken = null;
    setState(() {
      _staff = null;
      _token = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final staff = _staff;
    if (staff == null) {
      return DeliveryLogin(api: _api, onLoggedIn: _loggedIn);
    }
    return DeliveryHome(
      api: _api,
      staff: staff,
      token: _token,
      onLogout: _logout,
    );
  }
}

class DeliveryLogin extends StatefulWidget {
  const DeliveryLogin({super.key, required this.api, required this.onLoggedIn});

  final KiranaApi api;
  final ValueChanged<DeliveryLoginResult> onLoggedIn;

  @override
  State<DeliveryLogin> createState() => _DeliveryLoginState();
}

class _DeliveryLoginState extends State<DeliveryLogin> {
  final _formKey = GlobalKey<FormState>();
  final _mobile = TextEditingController();
  final _pin = TextEditingController();
  bool _busy = false;
  bool _hidePin = true;
  String? _error;

  @override
  void dispose() {
    _mobile.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.api.loginDeliveryStaff(
        mobile: _mobile.text.trim(),
        pin: _pin.text,
      );
      if (!mounted) return;
      widget.onLoggedIn(result);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is ApiException
            ? error.message
            : 'Login nahi ho paaya. XAMPP aur API check karein.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Align(
                      child: Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Icon(
                          Icons.delivery_dining_rounded,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Delivery Partner',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Store manager se mila mobile number aur PIN enter karein.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 26),
                    TextFormField(
                      controller: _mobile,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      maxLength: 10,
                      decoration: const InputDecoration(
                        labelText: 'Mobile number',
                        prefixIcon: Icon(Icons.phone_android),
                      ),
                      validator: (value) =>
                          RegExp(r'^\d{10}$').hasMatch(value ?? '')
                          ? null
                          : '10-digit mobile enter karein',
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _pin,
                      keyboardType: TextInputType.number,
                      obscureText: _hidePin,
                      maxLength: 4,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: '4-digit PIN',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _hidePin = !_hidePin),
                          icon: Icon(
                            _hidePin
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) =>
                          RegExp(r'^\d{4}$').hasMatch(value ?? '')
                          ? null
                          : '4-digit PIN enter karein',
                    ),
                    if (_error != null) ...<Widget>[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _busy ? null : _submit,
                      icon: _busy
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login_rounded),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 13),
                        child: Text('Login'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DeliveryHome extends StatefulWidget {
  const DeliveryHome({
    super.key,
    required this.api,
    required this.staff,
    required this.token,
    required this.onLogout,
  });

  final KiranaApi api;
  final DeliveryStaff staff;
  final String? token;
  final VoidCallback onLogout;

  @override
  State<DeliveryHome> createState() => _DeliveryHomeState();
}

class _DeliveryHomeState extends State<DeliveryHome> {
  List<Order> _orders = <Order>[];
  Timer? _poller;
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
    _poller = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted && !_refreshing) _refresh(silent: true);
    });
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  Future<void> _refresh({bool silent = false}) async {
    if (_refreshing) return;
    setState(() {
      _refreshing = true;
      if (!silent) _error = null;
    });
    try {
      final orders = await widget.api.getOrders(
        deliveryStaffId: widget.staff.id,
      );
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _error = null;
      });
    } catch (error) {
      if (mounted && !silent) {
        setState(
          () => _error = error is ApiException
              ? error.message
              : 'Orders load nahi hue.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _refreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _orders
        .where(
          (order) =>
              !<String>{'DELIVERED', 'CANCELLED'}.contains(_wire(order.status)),
        )
        .toList();
    final history = _orders
        .where(
          (order) =>
              <String>{'DELIVERED', 'CANCELLED'}.contains(_wire(order.status)),
        )
        .toList();
    final cash = history
        .where(
          (order) =>
              _wire(order.status) == 'DELIVERED' &&
              order.paymentMethod.name.toLowerCase() == 'cod',
        )
        .fold<double>(0, (sum, order) => sum + order.totalAmount);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              widget.staff.name,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const Text('Delivery partner', style: TextStyle(fontSize: 11)),
          ],
        ),
        actions: <Widget>[
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
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') widget.onLogout();
            },
            itemBuilder: (_) => const <PopupMenuEntry<String>>[
              PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _HeaderStat(
                    label: 'Active',
                    value: '${active.length}',
                    icon: Icons.route_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _HeaderStat(
                    label: 'Delivered',
                    value:
                        '${history.where((o) => _wire(o.status) == 'DELIVERED').length}',
                    icon: Icons.check_circle_outline,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _HeaderStat(
                    label: 'COD cash',
                    value: _inr(cash),
                    icon: Icons.payments_outlined,
                  ),
                ),
              ],
            ),
          ),
          if (_error != null)
            MaterialBanner(
              content: Text(_error!),
              actions: <Widget>[
                TextButton(onPressed: _refresh, child: const Text('RETRY')),
              ],
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: (_tab == 0 ? active : history).isEmpty
                        ? ListView(
                            children: <Widget>[
                              const SizedBox(height: 110),
                              Icon(
                                _tab == 0
                                    ? Icons.route_outlined
                                    : Icons.history_rounded,
                                size: 54,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _tab == 0
                                    ? 'Abhi koi delivery assign nahi hai'
                                    : 'Delivery history khali hai',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(12, 14, 12, 100),
                            itemCount: (_tab == 0 ? active : history).length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 11),
                            itemBuilder: (_, index) => _deliveryCard(
                              (_tab == 0 ? active : history)[index],
                            ),
                          ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Active',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }

  Widget _deliveryCard(Order order) {
    final status = _wire(order.status);
    final color = _statusColor(status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Order #${order.id}',
                    style: const TextStyle(
                      fontSize: 17,
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
                    _label(status),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            _InfoRow(
              icon: Icons.person_outline,
              title: order.customerName,
              subtitle: order.customerPhone,
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.location_on_outlined,
              title: order.deliveryAddress.label,
              subtitle: order.deliveryAddress.addressLine,
            ),
            const Divider(height: 24),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${order.items.length} item(s) • ${order.paymentMethod.name.toUpperCase()}',
                  ),
                ),
                Text(
                  _inr(order.totalAmount),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            if (status == 'READY') ...<Widget>[
              const SizedBox(height: 13),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _changeStatus(order, 'OUT_FOR_DELIVERY'),
                  icon: const Icon(Icons.two_wheeler_rounded),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 11),
                    child: Text('Start delivery'),
                  ),
                ),
              ),
            ],
            if (status == 'OUT_FOR_DELIVERY') ...<Widget>[
              const SizedBox(height: 13),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.info_outline, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.paymentMethod.name.toLowerCase() == 'cod'
                            ? 'Customer se ${_inr(order.totalAmount)} collect karein.'
                            : 'Payment online/udhaar marked hai.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                  ),
                  onPressed: () => _confirmDelivered(order),
                  icon: const Icon(Icons.task_alt_rounded),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 11),
                    child: Text('Mark delivered'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelivered(Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.task_alt_rounded, size: 40),
        title: const Text('Delivery complete?'),
        content: Text(
          order.paymentMethod.name.toLowerCase() == 'cod'
              ? 'Confirm karein ki order aur ${_inr(order.totalAmount)} cash mil gaya.'
              : 'Confirm karein ki customer ko order mil gaya.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not yet'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _changeStatus(order, 'DELIVERED');
  }

  Future<void> _changeStatus(Order order, String target) async {
    final status = _enumStatus(target);
    if (status == null) return;
    try {
      await widget.api.updateOrderStatus(order.id, status);
      await _refresh(silent: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order ${_label(target).toLowerCase()} ho gaya.'),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException
          ? error.message
          : 'Status update nahi hua.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  OrderStatus? _enumStatus(String value) {
    for (final status in OrderStatus.values) {
      if (_wire(status) == value) return status;
    }
    return null;
  }

  String _wire(OrderStatus status) {
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

  String _label(String status) => status
      .split('_')
      .map(
        (part) => part.isEmpty
            ? part
            : '${part[0]}${part.substring(1).toLowerCase()}',
      )
      .join(' ');

  Color _statusColor(String status) {
    switch (status) {
      case 'READY':
        return Colors.teal;
      case 'OUT_FOR_DELIVERY':
        return Colors.indigo;
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 21, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),
            ],
          ),
        ),
      ],
    );
  }
}

String _inr(num value) {
  final fixed = value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
  return '₹$fixed';
}
