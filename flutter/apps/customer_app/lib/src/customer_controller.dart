import 'package:flutter/foundation.dart';

import 'domain.dart';
import 'repository.dart';
import 'session_store.dart';

class CustomerController extends ChangeNotifier {
  CustomerController(this._repository, this._sessionStore);

  final CustomerRepository _repository;
  final SessionStore _sessionStore;

  bool _disposed = false;
  int _storeRequest = 0;
  int _catalogRequest = 0;
  int _ordersRequest = 0;
  String? _pendingOrderKey;

  bool booting = true;
  bool loadingStores = false;
  bool loadingCatalog = false;
  bool loadingOrders = false;
  bool placingOrder = false;
  String? storesError;
  String? catalogError;
  String? ordersError;
  String? sessionWarning;

  CustomerProfile? profile;
  List<CustomerStore> stores = const <CustomerStore>[];
  CustomerStore? selectedStore;
  List<CustomerProduct> products = const <CustomerProduct>[];
  List<CustomerOrder> orders = const <CustomerOrder>[];
  final Map<int, CartLine> _cart = <int, CartLine>{};

  List<CartLine> get cartLines => List<CartLine>.unmodifiable(_cart.values);
  int get cartCount => _cart.values.fold<int>(
    0,
    (int sum, CartLine line) => sum + line.quantity,
  );
  double get subtotal => _cart.values.fold<double>(
    0,
    (double sum, CartLine line) => sum + line.total,
  );
  double get mrpTotal => _cart.values.fold<double>(
    0,
    (double sum, CartLine line) => sum + (line.product.mrp * line.quantity),
  );
  double get discount => (mrpTotal - subtotal).clamp(0, double.infinity);
  double get deliveryCharge {
    final CustomerStore? store = selectedStore;
    if (store == null || subtotal == 0) return 0;
    return subtotal >= store.freeDeliveryAbove ? 0 : store.deliveryCharge;
  }

  double get total => subtotal + deliveryCharge;
  double get amountUntilMinimum {
    final CustomerStore? store = selectedStore;
    if (store == null) return 0;
    return (store.minimumOrder - subtotal).clamp(0, double.infinity);
  }

  bool get canCheckout {
    final CustomerStore? store = selectedStore;
    return store != null &&
        store.isOpen &&
        store.deliveryAvailable &&
        _cart.isNotEmpty &&
        amountUntilMinimum == 0 &&
        (store.codEnabled || store.upiEnabled);
  }

  Future<void> initialize() async {
    booting = true;
    _notify();
    final SavedSession saved = await _sessionStore.read();
    if (_disposed) return;
    profile = saved.profile;
    booting = false;
    _notify();
    if (profile != null) {
      await loadStores(preferredStoreId: saved.storeId);
    }
  }

  Future<void> saveProfile(CustomerProfile value) async {
    profile = value;
    sessionWarning = null;
    _notify();
    await _persistSession();
    if (_disposed) return;
    await loadStores();
  }

  Future<void> loadStores({int? preferredStoreId}) async {
    final int request = ++_storeRequest;
    loadingStores = true;
    storesError = null;
    _notify();
    try {
      final List<CustomerStore> result = await _repository.getStores();
      if (_disposed || request != _storeRequest) return;
      stores = result;
      loadingStores = false;
      _notify();
      final int? targetId = preferredStoreId ?? selectedStore?.id;
      if (targetId != null) {
        final CustomerStore? match = _findStore(targetId);
        if (match != null) await selectStore(match);
      }
    } catch (error) {
      if (_disposed || request != _storeRequest) return;
      loadingStores = false;
      storesError = _friendlyError(error, 'Dukaan ki list load nahi ho paayi.');
      _notify();
    }
  }

  Future<void> connectByCode(String code) async {
    final String normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) {
      throw const CustomerRepositoryException('Dukaan code daaliye.');
    }
    try {
      final CustomerStore store = await _repository.getStoreByCode(normalized);
      if (_disposed) return;
      if (!stores.any((CustomerStore item) => item.id == store.id)) {
        stores = <CustomerStore>[...stores, store];
      }
      await selectStore(store);
    } catch (error) {
      throw CustomerRepositoryException(
        _friendlyError(
          error,
          'Yeh dukaan code nahi mila. Dobara check karein.',
        ),
      );
    }
  }

  Future<void> selectStore(CustomerStore store) async {
    if (selectedStore?.id != store.id) {
      _cart.clear();
      _pendingOrderKey = null;
    }
    selectedStore = store;
    products = const <CustomerProduct>[];
    orders = const <CustomerOrder>[];
    catalogError = null;
    ordersError = null;
    _notify();
    await _persistSession();
    if (_disposed) return;
    await Future.wait<void>(<Future<void>>[loadProducts(), loadOrders()]);
  }

  Future<void> changeStore() async {
    selectedStore = null;
    products = const <CustomerProduct>[];
    orders = const <CustomerOrder>[];
    _cart.clear();
    _pendingOrderKey = null;
    _catalogRequest++;
    _ordersRequest++;
    _notify();
    await _persistSession();
  }

  Future<void> loadProducts() async {
    final CustomerStore? store = selectedStore;
    if (store == null) return;
    final int request = ++_catalogRequest;
    loadingCatalog = true;
    catalogError = null;
    _notify();
    try {
      final List<CustomerProduct> result = await _repository.getProducts(
        store.id,
      );
      if (_disposed ||
          request != _catalogRequest ||
          selectedStore?.id != store.id) {
        return;
      }
      products = result
          .where(
            (CustomerProduct product) =>
                product.storeId == store.id && product.available,
          )
          .toList(growable: false);
      loadingCatalog = false;
      _reconcileCart();
      _notify();
    } catch (error) {
      if (_disposed || request != _catalogRequest) return;
      loadingCatalog = false;
      catalogError = _friendlyError(error, 'Samaan load nahi ho paaya.');
      _notify();
    }
  }

  Future<void> loadOrders() async {
    final CustomerStore? store = selectedStore;
    final CustomerProfile? currentProfile = profile;
    if (store == null || currentProfile == null) return;
    final int request = ++_ordersRequest;
    loadingOrders = true;
    ordersError = null;
    _notify();
    try {
      final List<CustomerOrder> result = await _repository.getOrders(
        storeId: store.id,
        customerPhone: currentProfile.mobile,
      );
      if (_disposed ||
          request != _ordersRequest ||
          selectedStore?.id != store.id) {
        return;
      }
      orders =
          result
              .where((CustomerOrder order) => order.storeId == store.id)
              .toList()
            ..sort(
              (CustomerOrder a, CustomerOrder b) =>
                  b.createdAt.compareTo(a.createdAt),
            );
      loadingOrders = false;
      _notify();
    } catch (error) {
      if (_disposed || request != _ordersRequest) return;
      loadingOrders = false;
      ordersError = _friendlyError(error, 'Orders refresh nahi ho paaye.');
      _notify();
    }
  }

  int quantityFor(int productId) => _cart[productId]?.quantity ?? 0;

  void setQuantity(CustomerProduct product, int quantity) {
    if (product.stock <= 0 || quantity <= 0) {
      _cart.remove(product.id);
    } else {
      _cart[product.id] = CartLine(
        product: product,
        quantity: quantity.clamp(1, product.stock),
      );
    }
    _pendingOrderKey = null;
    _notify();
  }

  void removeFromCart(int productId) {
    _cart.remove(productId);
    _pendingOrderKey = null;
    _notify();
  }

  Future<CustomerOrder> placeOrder({
    required DeliveryAddress address,
    required PaymentChoice payment,
  }) async {
    final CustomerProfile? currentProfile = profile;
    final CustomerStore? store = selectedStore;
    if (currentProfile == null || store == null || _cart.isEmpty) {
      throw const CustomerRepositoryException('Cart khaali hai.');
    }
    if (!canCheckout) {
      throw const CustomerRepositoryException(
        'Checkout ke liye dukaan aur minimum order ki jaankari check karein.',
      );
    }
    if (payment == PaymentChoice.cod && !store.codEnabled) {
      throw const CustomerRepositoryException(
        'COD is dukaan par available nahi hai.',
      );
    }
    if (payment == PaymentChoice.upi && !store.upiEnabled) {
      throw const CustomerRepositoryException(
        'UPI is dukaan par available nahi hai.',
      );
    }

    placingOrder = true;
    _pendingOrderKey ??=
        'customer-${currentProfile.mobile}-${DateTime.now().microsecondsSinceEpoch}';
    _notify();
    try {
      final CustomerOrder created = await _repository.createOrder(
        CheckoutDraft(
          profile: currentProfile,
          store: store,
          lines: List<CartLine>.unmodifiable(_cart.values),
          address: address,
          payment: payment,
          subtotal: subtotal,
          deliveryCharge: deliveryCharge,
          total: total,
          idempotencyKey: _pendingOrderKey!,
        ),
      );
      if (_disposed) return created;
      _cart.clear();
      _pendingOrderKey = null;
      orders = <CustomerOrder>[created, ...orders];
      placingOrder = false;
      _notify();
      return created;
    } catch (error) {
      if (!_disposed) {
        placingOrder = false;
        _notify();
      }
      throw CustomerRepositoryException(
        _friendlyError(
          error,
          'Order place nahi ho paaya. Dobara koshish karein.',
        ),
      );
    }
  }

  Future<void> signOut() async {
    profile = null;
    selectedStore = null;
    stores = const <CustomerStore>[];
    products = const <CustomerProduct>[];
    orders = const <CustomerOrder>[];
    _cart.clear();
    _pendingOrderKey = null;
    _storeRequest++;
    _catalogRequest++;
    _ordersRequest++;
    _notify();
    try {
      await _sessionStore.clear();
    } on Object {
      // The in-memory sign-out is still valid if storage cleanup fails.
    }
  }

  CustomerStore? _findStore(int id) {
    for (final CustomerStore store in stores) {
      if (store.id == id) return store;
    }
    return null;
  }

  void _reconcileCart() {
    final Map<int, CustomerProduct> fresh = <int, CustomerProduct>{
      for (final CustomerProduct product in products) product.id: product,
    };
    final List<int> ids = _cart.keys.toList(growable: false);
    for (final int id in ids) {
      final CustomerProduct? product = fresh[id];
      if (product == null || product.stock <= 0) {
        _cart.remove(id);
      } else {
        final int quantity = _cart[id]!.quantity.clamp(1, product.stock);
        _cart[id] = CartLine(product: product, quantity: quantity);
      }
    }
  }

  Future<void> _persistSession() async {
    final CustomerProfile? currentProfile = profile;
    if (currentProfile == null) return;
    try {
      await _sessionStore.write(
        profile: currentProfile,
        storeId: selectedStore?.id,
      );
    } on Object {
      if (_disposed) return;
      sessionWarning = 'Profile is device par save nahi ho paayi.';
      _notify();
    }
  }

  String _friendlyError(Object error, String fallback) {
    if (error is CustomerRepositoryException &&
        error.message.trim().isNotEmpty) {
      return error.message;
    }
    return fallback;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
