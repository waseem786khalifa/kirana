import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_core/kirana_core.dart' as core;
import 'package:kirana_customer/src/core_customer_repository.dart';
import 'package:kirana_customer/src/customer_controller.dart';
import 'package:kirana_customer/src/domain.dart';
import 'package:kirana_customer/src/repository.dart';
import 'package:kirana_customer/src/session_store.dart';

void main() {
  test('a pending checkout cannot submit the same basket twice', () async {
    final Completer<CustomerOrder> pendingOrder = Completer<CustomerOrder>();
    int createCalls = 0;
    final _FlowRepository repository = _FlowRepository(
      stores: const <CustomerStore>[_store],
      products: const <CustomerProduct>[_product],
      createOrderHandler: (CheckoutDraft draft) {
        createCalls++;
        return pendingOrder.future;
      },
    );
    final CustomerController controller = await _connectedController(
      repository,
    );
    controller.setQuantity(_product, 1);

    final Future<CustomerOrder> first = controller.placeOrder(
      address: _address,
      payment: PaymentChoice.cod,
    );

    expect(controller.placingOrder, isTrue);
    await expectLater(
      controller.placeOrder(address: _address, payment: PaymentChoice.cod),
      throwsA(
        isA<CustomerRepositoryException>().having(
          (CustomerRepositoryException error) => error.message,
          'message',
          contains('already place ho raha hai'),
        ),
      ),
    );
    expect(createCalls, 1);

    pendingOrder.complete(_createdOrder);
    expect(await first, _createdOrder);
    expect(controller.placingOrder, isFalse);
    expect(controller.cartLines, isEmpty);
    expect(controller.orders, <CustomerOrder>[_createdOrder]);
    controller.dispose();
  });

  test('catalog refresh reconciles basket price and reduced stock', () async {
    final _FlowRepository repository = _FlowRepository(
      stores: const <CustomerStore>[_store],
      products: const <CustomerProduct>[_product],
    );
    final CustomerController controller = await _connectedController(
      repository,
    );
    controller.setQuantity(_product, 4);

    const CustomerProduct refreshed = CustomerProduct(
      id: 11,
      storeId: 7,
      name: 'Toor Dal',
      category: 'Dal',
      packSize: '1 kg',
      mrp: 100,
      price: 80,
      stock: 2,
      imageUrl: '',
      available: true,
    );
    repository.products = const <CustomerProduct>[refreshed];
    await controller.loadProducts();

    expect(controller.quantityFor(refreshed.id), 2);
    expect(controller.cartLines.single.product.price, 80);
    expect(controller.subtotal, 160);
    controller.dispose();
  });

  test('malformed HTML API response becomes an actionable error', () async {
    final HttpServer server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    final StreamSubscription<HttpRequest> subscription = server.listen((
      HttpRequest request,
    ) async {
      request.response
        ..statusCode = HttpStatus.notFound
        ..headers.contentType = ContentType.html
        ..write('<html><body>Not Found</body></html>');
      await request.response.close();
    });
    final core.KiranaApi api = core.KiranaApi(
      baseUrl: 'http://127.0.0.1:${server.port}',
    );
    final CoreCustomerRepository repository = CoreCustomerRepository(api: api);

    try {
      await expectLater(
        repository.getStores(),
        throwsA(
          isA<CustomerRepositoryException>().having(
            (CustomerRepositoryException error) => error.message,
            'message',
            contains('Backend/API URL'),
          ),
        ),
      );
    } finally {
      api.close(force: true);
      await subscription.cancel();
      await server.close(force: true);
    }
  });
}

const CustomerStore _store = CustomerStore(
  id: 7,
  code: 'TEST007',
  name: 'Test Kirana',
  address: 'Main Market',
  isOpen: true,
  deliveryAvailable: true,
  minimumOrder: 0,
  freeDeliveryAbove: 500,
  deliveryCharge: 30,
  expectedDeliveryTime: '30 min',
  codEnabled: true,
  upiEnabled: true,
  phone: '9876543210',
);

const CustomerProduct _product = CustomerProduct(
  id: 11,
  storeId: 7,
  name: 'Toor Dal',
  category: 'Dal',
  packSize: '1 kg',
  mrp: 100,
  price: 90,
  stock: 5,
  imageUrl: '',
  available: true,
);

const DeliveryAddress _address = DeliveryAddress(
  addressLine: '12 Main Market Road',
  landmark: '',
  pincode: '302003',
);

final CustomerOrder _createdOrder = CustomerOrder(
  id: 'KS-TEST-1',
  storeId: 7,
  status: 'NEW',
  paymentMethod: 'COD',
  total: 120,
  createdAt: DateTime(2026, 8, 11),
  items: const <CustomerOrderItem>[
    CustomerOrderItem(
      name: 'Toor Dal',
      packSize: '1 kg',
      price: 90,
      quantity: 1,
    ),
  ],
);

Future<CustomerController> _connectedController(
  _FlowRepository repository,
) async {
  final CustomerController controller = CustomerController(
    repository,
    _FlowSessionStore(
      const SavedSession(
        profile: CustomerProfile(name: 'Riya', mobile: '9876543210'),
        storeId: 7,
      ),
    ),
  );
  await controller.initialize();
  return controller;
}

class _FlowRepository implements CustomerRepository {
  _FlowRepository({
    required this.stores,
    required this.products,
    this.createOrderHandler,
  });

  List<CustomerStore> stores;
  List<CustomerProduct> products;
  final Future<CustomerOrder> Function(CheckoutDraft draft)? createOrderHandler;

  @override
  Future<CustomerOrder> createOrder(CheckoutDraft draft) {
    final Future<CustomerOrder> Function(CheckoutDraft draft)? handler =
        createOrderHandler;
    if (handler == null) throw UnimplementedError();
    return handler(draft);
  }

  @override
  Future<List<CustomerOrder>> getOrders({
    required int storeId,
    required String customerPhone,
  }) async => const <CustomerOrder>[];

  @override
  Future<List<CustomerProduct>> getProducts(int storeId) async => products;

  @override
  Future<CustomerStore> getStoreByCode(String code) async =>
      stores.firstWhere((CustomerStore store) => store.code == code);

  @override
  Future<List<CustomerStore>> getStores() async => stores;
}

class _FlowSessionStore implements SessionStore {
  _FlowSessionStore(this.value);

  SavedSession value;

  @override
  Future<void> clear() async => value = const SavedSession();

  @override
  Future<SavedSession> read() async => value;

  @override
  Future<void> write({required CustomerProfile profile, int? storeId}) async {
    value = SavedSession(profile: profile, storeId: storeId);
  }
}
