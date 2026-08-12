import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../customer_controller.dart';
import '../customer_ui.dart';
import '../domain.dart';
import '../repository.dart';

enum _StoreSort { fastest, name, freeDelivery }

class StoreConnectPage extends StatefulWidget {
  const StoreConnectPage({required this.controller, super.key});

  final CustomerController controller;

  @override
  State<StoreConnectPage> createState() => _StoreConnectPageState();
}

class _StoreConnectPageState extends State<StoreConnectPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _category = 'All';
  _StoreSort _sort = _StoreSort.fastest;
  int? _connectingStoreId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _select(CustomerStore store) async {
    if (_connectingStoreId != null) return;
    setState(() => _connectingStoreId = store.id);
    try {
      await widget.controller.selectStore(store);
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_selectionMessage(error))));
    } finally {
      if (mounted) setState(() => _connectingStoreId = null);
    }
  }

  Future<void> _showCodeEntry() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: CustomerPalette.surface,
      builder: (BuildContext context) =>
          _StoreCodeSheet(controller: widget.controller),
    );
  }

  Future<void> _showProfile() async {
    final CustomerProfile? profile = widget.controller.profile;
    await showModalBottomSheet<void>(
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
              Text('Profile', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _ProfileLine(
                icon: Icons.person_outline_rounded,
                value: profile?.name.trim().isNotEmpty == true
                    ? profile!.name.trim()
                    : 'Customer',
              ),
              const SizedBox(height: 10),
              _ProfileLine(
                icon: Icons.phone_outlined,
                value: profile?.mobile.trim() ?? '',
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.of(sheetContext).pop();
                  await widget.controller.signOut();
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onBottomNavigation(int index) {
    if (index == 0) return;
    if (index == 3) {
      _showProfile();
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Pehle apni dukaan chuniye.')));
  }

  @override
  Widget build(BuildContext context) {
    final CustomerController controller = widget.controller;
    final List<String> categories = _storeCategories(controller.stores);
    if (_category != 'All' && !categories.contains(_category)) {
      _category = 'All';
    }
    final List<CustomerStore> visibleStores = _filteredStores(
      controller.stores,
      _query,
      _category,
      _sort,
    );
    final List<CustomerStore> availableNow =
        _query.trim().isEmpty && _category == 'All'
        ? visibleStores
              .where(
                (CustomerStore store) =>
                    store.isOpen && store.deliveryAvailable,
              )
              .take(3)
              .toList(growable: false)
        : const <CustomerStore>[];
    final bool firstLoad =
        controller.loadingStores && controller.stores.isEmpty;
    final bool fullError =
        controller.storesError != null && controller.stores.isEmpty;
    final double horizontalPadding = MediaQuery.sizeOf(context).width < 360
        ? 12
        : MediaQuery.sizeOf(context).width >= 700
        ? 24
        : 16;

    return Scaffold(
      bottomNavigationBar: CustomerBottomNavigation(
        selectedIndex: 0,
        cartCount: 0,
        onSelected: _onBottomNavigation,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.loadStores,
          child: CustomScrollView(
            key: const PageStorageKey<String>('store-list-scroll'),
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: _StorePageWidth(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      8,
                      horizontalPadding,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _DeliveryStrip(stores: controller.stores),
                        const SizedBox(height: 18),
                        _StorePageHeader(
                          stores: controller.stores,
                          loading: controller.loadingStores,
                          onCodePressed: _showCodeEntry,
                          onProfilePressed: _showProfile,
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          key: const Key('store-search'),
                          controller: _searchController,
                          onChanged: (String value) =>
                              setState(() => _query = value),
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'Search stores, areas, categories...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _query.isEmpty
                                ? const Icon(Icons.mic_none_rounded)
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
                        _StoreCategoryRail(
                          categories: categories,
                          selected: _category,
                          onSelected: (String value) =>
                              setState(() => _category = value),
                        ),
                        if (controller.storesError != null &&
                            controller.stores.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 12),
                          _InlineStoreError(
                            message: controller.storesError!,
                            onRetry: controller.loadStores,
                          ),
                        ],
                        if (controller.sessionWarning != null) ...<Widget>[
                          const SizedBox(height: 12),
                          _SessionWarning(message: controller.sessionWarning!),
                        ],
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
              if (firstLoad)
                SliverList.builder(
                  itemCount: 3,
                  itemBuilder: (_, _) => _StorePageWidth(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        0,
                        horizontalPadding,
                        12,
                      ),
                      child: const _StoreCardSkeleton(),
                    ),
                  ),
                )
              else if (fullError)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _StorePageWidth(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        0,
                        horizontalPadding,
                        28,
                      ),
                      child: _StoreError(
                        message: controller.storesError!,
                        onRetry: controller.loadStores,
                      ),
                    ),
                  ),
                )
              else if (controller.stores.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyStores(filtered: false),
                )
              else if (visibleStores.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyStores(filtered: true),
                )
              else ...<Widget>[
                if (availableNow.isNotEmpty) ...<Widget>[
                  SliverToBoxAdapter(
                    child: _StorePageWidth(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          0,
                          horizontalPadding,
                          10,
                        ),
                        child: const CustomerSectionHeader(
                          title: 'Available now',
                        ),
                      ),
                    ),
                  ),
                  _storeSliver(availableNow, horizontalPadding, featured: true),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                ],
                SliverToBoxAdapter(
                  child: _StorePageWidth(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        2,
                        horizontalPadding,
                        10,
                      ),
                      child: _AllStoresHeader(
                        count: visibleStores.length,
                        value: _sort,
                        onChanged: (_StoreSort value) =>
                            setState(() => _sort = value),
                      ),
                    ),
                  ),
                ),
                _storeSliver(visibleStores, horizontalPadding),
                const SliverToBoxAdapter(child: SizedBox(height: 22)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _storeSliver(
    List<CustomerStore> stores,
    double horizontalPadding, {
    bool featured = false,
  }) {
    return SliverList.builder(
      itemCount: stores.length,
      itemBuilder: (BuildContext context, int index) {
        final CustomerStore store = stores[index];
        return _StorePageWidth(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              0,
              horizontalPadding,
              11,
            ),
            child: _StoreCard(
              key: ValueKey<String>(
                '${featured ? 'featured' : 'all'}-store-${store.id}',
              ),
              store: store,
              busy: _connectingStoreId == store.id,
              enabled: _connectingStoreId == null,
              onTap: () => _select(store),
            ),
          ),
        );
      },
    );
  }
}

class _StorePageWidth extends StatelessWidget {
  const _StorePageWidth({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: child,
      ),
    );
  }
}

class _DeliveryStrip extends StatelessWidget {
  const _DeliveryStrip({required this.stores});

  final List<CustomerStore> stores;

  @override
  Widget build(BuildContext context) {
    final List<CustomerStore> deliveryStores = stores
        .where((CustomerStore store) => store.deliveryAvailable)
        .toList(growable: false);
    final List<double> thresholds = deliveryStores
        .map((CustomerStore store) => store.freeDeliveryAbove)
        .where((double value) => value > 0)
        .toList(growable: false);
    final double threshold = thresholds.isEmpty
        ? 0
        : thresholds.reduce((double a, double b) => a < b ? a : b);
    final String title = threshold > 0
        ? 'Free delivery from ${formatRupees(threshold)}'
        : 'Local stores, delivered to you';
    final String subtitle = deliveryStores.isEmpty && stores.isNotEmpty
        ? 'Browse catalogues and check store availability'
        : 'Choose a store to see its live catalogue';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFFFF8ED), Color(0xFFFFF2D8)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delivery_dining_rounded,
              color: CustomerPalette.primaryDark,
            ),
          ),
          const SizedBox(width: 11),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
        ],
      ),
    );
  }
}

class _StorePageHeader extends StatelessWidget {
  const _StorePageHeader({
    required this.stores,
    required this.loading,
    required this.onCodePressed,
    required this.onProfilePressed,
  });

  final List<CustomerStore> stores;
  final bool loading;
  final VoidCallback onCodePressed;
  final VoidCallback onProfilePressed;

  @override
  Widget build(BuildContext context) {
    final int available = stores
        .where((CustomerStore store) => store.isOpen && store.deliveryAvailable)
        .length;
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Flexible(
                    child: Text(
                      'All stores',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 25,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ),
                  SizedBox(width: 5),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 24),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: <Widget>[
                  Flexible(
                    child: Text(
                      stores.isEmpty
                          ? loading
                                ? 'Finding available kirana stores...'
                                : 'No stores loaded'
                          : '${stores.length} stores  •  $available delivering now',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CustomerPalette.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (loading) ...<Widget>[
                    const SizedBox(width: 8),
                    const SizedBox.square(
                      dimension: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          key: const Key('store-code-action'),
          onPressed: onCodePressed,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 11),
            minimumSize: const Size(78, 46),
          ),
          icon: const Icon(Icons.sell_outlined, size: 18),
          label: const Text(
            'Code',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 7),
        IconButton.outlined(
          tooltip: 'Profile',
          onPressed: onProfilePressed,
          style: IconButton.styleFrom(
            minimumSize: const Size(46, 46),
            side: const BorderSide(color: CustomerPalette.border),
          ),
          icon: const Icon(Icons.person_rounded),
        ),
      ],
    );
  }
}

class _StoreCategoryRail extends StatelessWidget {
  const _StoreCategoryRail({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final List<String> values = <String>['All', ...categories];
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (BuildContext context, int index) {
          final String category = values[index];
          final bool active = selected == category;
          return Semantics(
            button: true,
            selected: active,
            label: '$category category',
            child: InkWell(
              borderRadius: BorderRadius.circular(13),
              onTap: () => onSelected(category),
              child: SizedBox(
                width: 66,
                child: Column(
                  children: <Widget>[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 58,
                      height: 56,
                      decoration: BoxDecoration(
                        color: active
                            ? CustomerPalette.primaryLight
                            : CustomerPalette.surface,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: active
                              ? CustomerPalette.primary.withValues(alpha: 0.2)
                              : CustomerPalette.border,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CustomerCategoryImage(
                          category: category,
                          padding: const EdgeInsets.all(6),
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
                        color: active
                            ? CustomerPalette.primaryDark
                            : CustomerPalette.textPrimary,
                        fontSize: 9.5,
                        fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: active ? 42 : 0,
                      height: 3,
                      decoration: BoxDecoration(
                        color: CustomerPalette.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AllStoresHeader extends StatelessWidget {
  const _AllStoresHeader({
    required this.count,
    required this.value,
    required this.onChanged,
  });

  final int count;
  final _StoreSort value;
  final ValueChanged<_StoreSort> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            'All stores ($count)',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ),
        PopupMenuButton<_StoreSort>(
          tooltip: 'Store sort karein',
          initialValue: value,
          onSelected: onChanged,
          itemBuilder: (_) => const <PopupMenuEntry<_StoreSort>>[
            PopupMenuItem<_StoreSort>(
              value: _StoreSort.fastest,
              child: Text('Fastest delivery'),
            ),
            PopupMenuItem<_StoreSort>(
              value: _StoreSort.name,
              child: Text('Store name'),
            ),
            PopupMenuItem<_StoreSort>(
              value: _StoreSort.freeDelivery,
              child: Text('Free delivery first'),
            ),
          ],
          child: Container(
            constraints: const BoxConstraints(minHeight: 42),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              color: CustomerPalette.surface,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: CustomerPalette.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  _sortLabel(value),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({
    required this.store,
    required this.enabled,
    required this.busy,
    required this.onTap,
    super.key,
  });

  final CustomerStore store;
  final bool enabled;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final List<String> categories = store.categories.take(3).toList();
    final String deliveryText;
    if (!store.deliveryAvailable) {
      deliveryText = 'Home delivery unavailable';
    } else if (store.deliveryCharge <= 0 || store.freeDeliveryAbove <= 0) {
      deliveryText = 'FREE delivery';
    } else {
      deliveryText =
          'FREE delivery above ${formatRupees(store.freeDeliveryAbove)}';
    }
    final String semantics = <String>[
      store.name,
      store.isOpen ? 'Open' : 'Closed',
      if (store.deliveryAvailable) store.expectedDeliveryTime,
      deliveryText,
      if (store.address.trim().isNotEmpty) store.address,
    ].where((String value) => value.trim().isNotEmpty).join(', ');

    return Semantics(
      button: true,
      enabled: enabled,
      label: semantics,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: CustomerPalette.border),
        ),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _StoreLogo(store: store),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  store.name.trim().isEmpty
                                      ? 'Kirana Store'
                                      : store.name.trim(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    height: 1.15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              if (store.maxSaving > 0) ...<Widget>[
                                const SizedBox(width: 7),
                                _SavingBadge(saving: store.maxSaving),
                              ],
                            ],
                          ),
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 7,
                            runSpacing: 3,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: <Widget>[
                              _StoreStatus(open: store.isOpen),
                              if (store.code.trim().isNotEmpty)
                                Text(
                                  store.code.trim(),
                                  style: const TextStyle(
                                    color: CustomerPalette.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              if (store.deliveryAvailable &&
                                  store.expectedDeliveryTime.trim().isNotEmpty)
                                Text(
                                  '•  ${store.expectedDeliveryTime.trim()}',
                                  style: const TextStyle(
                                    color: CustomerPalette.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: <Widget>[
                              Icon(
                                store.deliveryAvailable
                                    ? Icons.delivery_dining_rounded
                                    : Icons.block_rounded,
                                size: 15,
                                color: store.deliveryAvailable
                                    ? CustomerPalette.primary
                                    : CustomerPalette.textMuted,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  deliveryText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: store.deliveryAvailable
                                        ? CustomerPalette.primaryDark
                                        : CustomerPalette.textMuted,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (store.address.trim().isNotEmpty) ...<Widget>[
                            const SizedBox(height: 5),
                            Text(
                              store.address.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: CustomerPalette.textMuted,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 5,
                            children: <Widget>[
                              ...categories.map(
                                (String value) => _CategoryPill(value: value),
                              ),
                              if (store.categories.length > categories.length)
                                _CategoryPill(
                                  value:
                                      '+${store.categories.length - categories.length}',
                                ),
                              if (categories.isEmpty)
                                _CategoryPill(
                                  value: store.productCount > 0
                                      ? '${store.productCount} products'
                                      : 'Kirana',
                                ),
                              _CategoryPill(
                                value: store.minimumOrder <= 0
                                    ? 'No minimum'
                                    : 'Min ${formatRupees(store.minimumOrder)}',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Padding(
                      padding: EdgeInsets.only(top: 47),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: CustomerPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (busy)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.white.withValues(alpha: 0.78),
                    child: const Center(
                      child: SizedBox.square(
                        dimension: 25,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreLogo extends StatelessWidget {
  const _StoreLogo({required this.store});

  final CustomerStore store;

  @override
  Widget build(BuildContext context) {
    final Widget fallback = _StoreMonogram(store: store);
    final Uri? uri = Uri.tryParse(store.logoUrl.trim());
    return Container(
      width: 58,
      height: 58,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CustomerPalette.border),
      ),
      child: uri != null && uri.hasScheme && uri.host.isNotEmpty
          ? Image.network(
              uri.toString(),
              fit: BoxFit.cover,
              cacheWidth: 180,
              errorBuilder: (_, _, _) => fallback,
              loadingBuilder: (_, Widget child, ImageChunkEvent? event) =>
                  event == null ? child : fallback,
            )
          : fallback,
    );
  }
}

class _StoreMonogram extends StatelessWidget {
  const _StoreMonogram({required this.store});

  final CustomerStore store;

  @override
  Widget build(BuildContext context) {
    final String source = store.name.trim().isEmpty
        ? store.code.trim()
        : store.name.trim();
    final String initial = source.isEmpty ? 'K' : source[0].toUpperCase();
    final Color accent = _storeAccent(store);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            accent.withValues(alpha: 0.08),
            accent.withValues(alpha: 0.2),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: accent,
            fontSize: 31,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _StoreStatus extends StatelessWidget {
  const _StoreStatus({required this.open});

  final bool open;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: open ? CustomerPalette.primary : CustomerPalette.danger,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          open ? 'OPEN' : 'CLOSED',
          style: TextStyle(
            color: open ? CustomerPalette.primaryDark : CustomerPalette.danger,
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _SavingBadge extends StatelessWidget {
  const _SavingBadge({required this.saving});

  final double saving;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: CustomerPalette.primaryLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'SAVE ${formatRupees(saving)}',
        style: const TextStyle(
          color: CustomerPalette.primaryDark,
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CustomerPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: CustomerPalette.textSecondary,
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StoreCodeSheet extends StatefulWidget {
  const _StoreCodeSheet({required this.controller});

  final CustomerController controller;

  @override
  State<_StoreCodeSheet> createState() => _StoreCodeSheetState();
}

class _StoreCodeSheetState extends State<_StoreCodeSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.controller.connectByCode(_controller.text);
      if (mounted) Navigator.of(context).pop();
    } on CustomerRepositoryException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on Object catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Dukaan connect nahi ho paayi. Dobara try karein.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 2, 20, 20 + keyboard),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Store code se connect karein',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 5),
            const Text(
              'Dukaan se mila code daaliye, jaise BALAJI123.',
              style: TextStyle(
                color: CustomerPalette.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('store-code'),
              controller: _controller,
              autofocus: true,
              enabled: !_busy,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_-]')),
                LengthLimitingTextInputFormatter(32),
              ],
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _connect(),
              decoration: InputDecoration(
                hintText: 'BALAJI123',
                errorText: _error,
                prefixIcon: const Icon(Icons.sell_outlined),
              ),
            ),
            const SizedBox(height: 12),
            CustomerPrimaryButton(
              label: _busy ? 'Connecting...' : 'Connect store',
              icon: Icons.arrow_forward_rounded,
              busy: _busy,
              onPressed: _busy ? null : _connect,
              key: const Key('connect-store'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileLine extends StatelessWidget {
  const _ProfileLine({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: CustomerPalette.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: CustomerPalette.primaryDark, size: 20),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _InlineStoreError extends StatelessWidget {
  const _InlineStoreError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD8D2)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.cloud_off_rounded, color: CustomerPalette.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5, height: 1.3),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _SessionWarning extends StatelessWidget {
  const _SessionWarning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.warning_amber_rounded,
            color: CustomerPalette.warning,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: const TextStyle(fontSize: 11.5)),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.cloud_off_rounded,
              color: CustomerPalette.danger,
              size: 42,
            ),
            const SizedBox(height: 11),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 13),
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
  const _EmptyStores({required this.filtered});

  final bool filtered;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.store_mall_directory_outlined,
              color: CustomerPalette.textMuted,
              size: 48,
            ),
            const SizedBox(height: 11),
            Text(
              filtered
                  ? 'Is search mein koi store nahi mila.'
                  : 'Abhi koi store list mein available nahi hai.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (!filtered) ...<Widget>[
              const SizedBox(height: 5),
              const Text(
                'Store code se connect kar sakte hain.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: CustomerPalette.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StoreCardSkeleton extends StatelessWidget {
  const _StoreCardSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget block(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: CustomerPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
      ),
    );
    return Container(
      height: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CustomerPalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CustomerPalette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          block(58, 58),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                block(180, 16),
                const SizedBox(height: 11),
                block(130, 12),
                const SizedBox(height: 11),
                block(double.infinity, 12),
                const SizedBox(height: 13),
                Row(
                  children: <Widget>[
                    block(70, 24),
                    const SizedBox(width: 7),
                    block(82, 24),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

List<String> _storeCategories(List<CustomerStore> stores) {
  final Set<String> result = <String>{};
  for (final CustomerStore store in stores) {
    result.addAll(
      store.categories.where((String value) => value.trim().isNotEmpty),
    );
  }
  final List<String> values = result.toList()..sort();
  return values;
}

List<CustomerStore> _filteredStores(
  List<CustomerStore> stores,
  String query,
  String category,
  _StoreSort sort,
) {
  final String normalized = query.trim().toLowerCase();
  final List<CustomerStore> result = stores
      .where((CustomerStore store) {
        final bool categoryMatches =
            category == 'All' || store.categories.contains(category);
        if (!categoryMatches) return false;
        if (normalized.isEmpty) return true;
        return <String>[
          store.name,
          store.code,
          store.address,
          store.description,
          ...store.categories,
        ].any((String value) => value.toLowerCase().contains(normalized));
      })
      .toList(growable: false);
  result.sort((CustomerStore a, CustomerStore b) {
    final int availability = _availabilityRank(
      a,
    ).compareTo(_availabilityRank(b));
    if (availability != 0) return availability;
    return switch (sort) {
      _StoreSort.fastest => _etaMinutes(
        a.expectedDeliveryTime,
      ).compareTo(_etaMinutes(b.expectedDeliveryTime)),
      _StoreSort.name => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      _StoreSort.freeDelivery => a.freeDeliveryAbove.compareTo(
        b.freeDeliveryAbove,
      ),
    };
  });
  return result;
}

int _availabilityRank(CustomerStore store) {
  if (store.isOpen && store.deliveryAvailable) return 0;
  if (store.isOpen) return 1;
  return 2;
}

int _etaMinutes(String value) {
  final RegExpMatch? match = RegExp(r'\d+').firstMatch(value);
  return int.tryParse(match?.group(0) ?? '') ?? 9999;
}

String _sortLabel(_StoreSort value) => switch (value) {
  _StoreSort.fastest => 'Fastest',
  _StoreSort.name => 'Name',
  _StoreSort.freeDelivery => 'Free delivery',
};

Color _storeAccent(CustomerStore store) {
  const List<Color> colors = <Color>[
    Color(0xFF078A27),
    Color(0xFF5E35B1),
    Color(0xFFE56A26),
    Color(0xFF1565C0),
    Color(0xFF00897B),
  ];
  return colors[store.id.abs() % colors.length];
}

String _selectionMessage(Object error) {
  if (error is CustomerRepositoryException) return error.message;
  return 'Dukaan connect nahi ho paayi. Dobara try karein.';
}
