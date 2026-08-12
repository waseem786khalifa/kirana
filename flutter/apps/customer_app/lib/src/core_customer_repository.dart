import 'package:kirana_core/kirana_core.dart' as core;

import 'domain.dart';
import 'repository.dart';

class CoreCustomerRepository implements CustomerRepository {
  CoreCustomerRepository({core.KiranaApi? api})
    : _api = api ?? core.KiranaApi();

  final core.KiranaApi _api;

  @override
  Future<List<CustomerStore>> getStores() async {
    try {
      final List<core.Store> stores = await _api.getStores();
      return stores.map(_mapStore).toList(growable: false);
    } on Object catch (error) {
      throw CustomerRepositoryException(
        _message(error, 'Stores load nahi ho paaye.'),
      );
    }
  }

  @override
  Future<CustomerStore> getStoreByCode(String code) async {
    try {
      return _mapStore(await _api.getStoreByCode(code));
    } on Object catch (error) {
      throw CustomerRepositoryException(
        _message(error, 'Dukaan code nahi mila.'),
      );
    }
  }

  @override
  Future<List<CustomerProduct>> getProducts(int storeId) async {
    try {
      final List<core.Product> products = await _api.getProducts(
        storeId: storeId,
        availableOnline: true,
      );
      return products
          .where((core.Product product) => !product.isHidden)
          .map(_mapProduct)
          .toList(growable: false);
    } on Object catch (error) {
      throw CustomerRepositoryException(
        _message(error, 'Catalogue load nahi hua.'),
      );
    }
  }

  @override
  Future<List<CustomerOrder>> getOrders({
    required int storeId,
    required String customerPhone,
  }) async {
    try {
      final List<core.Order> orders = await _api.getOrders(
        storeId: storeId,
        customerPhone: customerPhone,
      );
      return orders.map(_mapOrder).toList(growable: false);
    } on Object catch (error) {
      throw CustomerRepositoryException(
        _message(error, 'Orders load nahi hue.'),
      );
    }
  }

  @override
  Future<CustomerOrder> createOrder(CheckoutDraft draft) async {
    try {
      final core.Order created = await _api.createOrder(
        core.CreateOrderRequest(
          storeId: draft.store.id,
          customerName: draft.profile.name,
          customerPhone: draft.profile.mobile,
          deliveryAddress: core.Address(
            label: 'Home',
            addressLine: draft.address.addressLine,
            landmark: draft.address.landmark,
            pincode: draft.address.pincode,
          ),
          items: draft.lines
              .map(
                (CartLine line) => core.CartItem(
                  product: _toCoreProduct(line.product),
                  quantity: line.quantity,
                ),
              )
              .toList(growable: false),
          paymentMethod: draft.payment == PaymentChoice.cod
              ? core.PaymentMethod.cod
              : core.PaymentMethod.upi,
          idempotencyKey: draft.idempotencyKey,
        ),
      );
      return _mapOrder(created);
    } on Object catch (error) {
      throw CustomerRepositoryException(
        _message(error, 'Order place nahi ho paaya.'),
      );
    }
  }

  CustomerStore _mapStore(core.Store store) {
    return CustomerStore(
      id: store.id,
      code: store.code,
      name: store.name,
      address: <String>[
        store.address,
        if (store.landmark.isNotEmpty) store.landmark,
        if (store.pincode.isNotEmpty) store.pincode,
      ].where((String part) => part.trim().isNotEmpty).join(', '),
      isOpen: store.isOpen,
      deliveryAvailable: store.deliverySettings.deliveryAvailable,
      minimumOrder: store.deliverySettings.minOrder,
      freeDeliveryAbove: store.deliverySettings.freeDeliveryAbove,
      deliveryCharge: store.deliverySettings.deliveryCharge,
      expectedDeliveryTime: store.deliverySettings.expectedDeliveryTime.isEmpty
          ? '30–45 min'
          : store.deliverySettings.expectedDeliveryTime,
      codEnabled: store.paymentSettings.codEnabled,
      upiEnabled: store.paymentSettings.upiEnabled,
      phone: store.phone,
      logoUrl: store.logo,
      bannerUrl: store.banner,
      description: store.description,
      openingTime: store.openingTime,
      closingTime: store.closingTime,
      categories: store.categories,
      productCount: store.productCount,
      maxSaving: store.maxSaving,
      maxDiscountPercent: store.maxDiscountPercent,
    );
  }

  CustomerProduct _mapProduct(core.Product product) {
    return CustomerProduct(
      id: product.id,
      storeId: product.storeId,
      name: product.nameEn,
      category: product.category,
      packSize: product.packSize,
      mrp: product.mrp,
      price: product.sellingPrice,
      stock: product.stock,
      imageUrl: product.image,
      available: product.availableForOnline && !product.isHidden,
    );
  }

  core.Product _toCoreProduct(CustomerProduct product) {
    return core.Product(
      id: product.id,
      storeId: product.storeId,
      nameEn: product.name,
      category: product.category,
      packSize: product.packSize,
      mrp: product.mrp,
      sellingPrice: product.price,
      stock: product.stock,
      image: product.imageUrl,
      availableForOnline: product.available,
    );
  }

  CustomerOrder _mapOrder(core.Order order) {
    return CustomerOrder(
      id: order.displayNumber,
      storeId: order.storeId,
      status: order.status.apiValue,
      paymentMethod: order.paymentMethod.apiValue,
      total: order.totalAmount,
      createdAt: order.createdAt ?? order.updatedAt ?? DateTime.now(),
      rejectionReason: order.rejectionReason,
      items: order.items
          .map(
            (core.OrderItem item) => CustomerOrderItem(
              name: item.nameEn,
              packSize: item.packSize,
              price: item.price,
              quantity: item.quantity,
            ),
          )
          .toList(growable: false),
    );
  }

  String _message(Object error, String fallback) {
    if (error is core.ApiException) {
      if (error.code == 'INVALID_RESPONSE') {
        return error.statusCode == 404
            ? 'Customer API endpoint nahi mila. Backend/API URL check karke Retry karein.'
            : 'Server se valid data nahi mila. Backend check karke Retry karein.';
      }
      if (error.code == 'TIMEOUT') {
        return 'Server response mein zyada time lag raha hai. Dobara Retry karein.';
      }
      if (error.isNetworkError) {
        return 'Server se connection nahi ho paaya. Backend/internet check karke Retry karein.';
      }
      if (error.message.trim().isNotEmpty) return error.message;
      return fallback;
    }
    final dynamic value = error;
    try {
      final Object? message = value.message;
      if (message is String && message.trim().isNotEmpty) return message;
    } on Object {
      // Some exception types do not expose a message property.
    }
    return fallback;
  }
}
