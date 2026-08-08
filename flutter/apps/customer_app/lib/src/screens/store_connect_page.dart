import 'package:flutter/material.dart';

import '../customer_controller.dart';
import '../domain.dart';
import '../repository.dart';

class StoreConnectPage extends StatefulWidget {
  const StoreConnectPage({required this.controller, super.key});

  final CustomerController controller;

  @override
  State<StoreConnectPage> createState() => _StoreConnectPageState();
}

class _StoreConnectPageState extends State<StoreConnectPage> {
  final TextEditingController _codeController = TextEditingController();
  bool _connecting = false;
  String? _codeError;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _connectCode() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _connecting = true;
      _codeError = null;
    });
    try {
      await widget.controller.connectByCode(_codeController.text);
    } on CustomerRepositoryException catch (error) {
      if (!mounted) return;
      setState(() => _codeError = error.message);
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _select(CustomerStore store) async {
    setState(() => _connecting = true);
    await widget.controller.selectStore(store);
    if (mounted) setState(() => _connecting = false);
  }

  @override
  Widget build(BuildContext context) {
    final CustomerController controller = widget.controller;
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apni dukaan connect karein'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Profile se sign out karein',
            onPressed: _connecting ? null : controller.signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.loadStores,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF145A3B), Color(0xFF267A55)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(
                    Icons.storefront_rounded,
                    color: Color(0xFFFFCE62),
                    size: 34,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Namaste, ${controller.profile?.name.split(' ').first ?? ''}!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Shop code daaliye ya available dukaan ki list se chuniye.',
                    style: TextStyle(color: Color(0xFFD9F2E5), height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    key: const Key('store-code'),
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _connecting ? null : _connectCode(),
                    decoration: InputDecoration(
                      hintText: 'Jaise: BALAJI123',
                      errorText: _codeError,
                      prefixIcon: const Icon(Icons.qr_code_2_rounded),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.all(6),
                        child: FilledButton(
                          key: const Key('connect-store'),
                          onPressed: _connecting ? null : _connectCode,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(92, 44),
                          ),
                          child: _connecting
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Connect'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Available kirana stores',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (controller.loadingStores)
                  const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (controller.storesError != null)
              _StoreError(
                message: controller.storesError!,
                onRetry: controller.loadStores,
              )
            else if (!controller.loadingStores && controller.stores.isEmpty)
              const _EmptyStores()
            else
              ...controller.stores.map(
                (CustomerStore store) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _StoreCard(
                    store: store,
                    enabled: !_connecting,
                    onTap: () => _select(store),
                  ),
                ),
              ),
            if (controller.sessionWarning != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                controller.sessionWarning!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({
    required this.store,
    required this.enabled,
    required this.onTap,
  });

  final CustomerStore store;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
                radius: 27,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.store_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            store.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _OpenBadge(isOpen: store.isOpen),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      store.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        _InfoChip(icon: Icons.tag_rounded, label: store.code),
                        _InfoChip(
                          icon: Icons.delivery_dining_rounded,
                          label: store.expectedDeliveryTime,
                        ),
                        _InfoChip(
                          icon: Icons.shopping_bag_outlined,
                          label: 'Min ${formatRupees(store.minimumOrder)}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpenBadge extends StatelessWidget {
  const _OpenBadge({required this.isOpen});

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen ? const Color(0xFFE2F6EA) : const Color(0xFFFFE8E5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        isOpen ? 'OPEN' : 'CLOSED',
        style: TextStyle(
          color: isOpen ? const Color(0xFF11613C) : const Color(0xFFB3261E),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _StoreError extends StatelessWidget {
  const _StoreError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            Icon(
              Icons.cloud_off_rounded,
              color: Theme.of(context).colorScheme.error,
              size: 36,
            ),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStores extends StatelessWidget {
  const _EmptyStores();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 42),
      child: Column(
        children: <Widget>[
          Icon(Icons.store_mall_directory_outlined, size: 44),
          SizedBox(height: 10),
          Text('Abhi koi store list mein available nahi hai.'),
          SizedBox(height: 4),
          Text('Shop code se connect kar sakte hain.'),
        ],
      ),
    );
  }
}
