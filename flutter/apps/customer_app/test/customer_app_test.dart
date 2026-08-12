import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_customer/src/app.dart';
import 'package:kirana_customer/src/customer_controller.dart';
import 'package:kirana_customer/src/domain.dart';
import 'package:kirana_customer/src/repository.dart';
import 'package:kirana_customer/src/session_store.dart';

void main() {
  test('formats amounts using the Indian grouping system', () {
    expect(formatRupees(99), '₹99');
    expect(formatRupees(1250), '₹1,250');
    expect(formatRupees(125000.5), '₹1,25,000.50');
  });

  test('restores a store and calculates stock-safe basket totals', () async {
    const CustomerStore store = CustomerStore(
      id: 7,
      code: 'TEST007',
      name: 'Test Kirana',
      address: 'Main Market',
      isOpen: true,
      deliveryAvailable: true,
      minimumOrder: 100,
      freeDeliveryAbove: 500,
      deliveryCharge: 30,
      expectedDeliveryTime: '30 min',
      codEnabled: true,
      upiEnabled: true,
    );
    const CustomerProduct product = CustomerProduct(
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
    final _MemorySessionStore storage = _MemorySessionStore()
      ..value = const SavedSession(
        profile: CustomerProfile(name: 'Riya Sharma', mobile: '9876543210'),
        storeId: 7,
      );
    final CustomerController controller = CustomerController(
      _FakeRepository(
        stores: const <CustomerStore>[store],
        products: const <CustomerProduct>[product],
      ),
      storage,
    );

    await controller.initialize();
    controller.setQuantity(product, 99);

    expect(controller.selectedStore?.id, 7);
    expect(controller.quantityFor(product.id), 2);
    expect(controller.subtotal, 160);
    expect(controller.discount, 40);
    expect(controller.deliveryCharge, 30);
    expect(controller.total, 190);
    expect(controller.canCheckout, isTrue);
    controller.dispose();
  });

  testWidgets('profile requires a valid Indian mobile before continuing', (
    WidgetTester tester,
  ) async {
    final CustomerController controller = CustomerController(
      _FakeRepository(),
      _MemorySessionStore(),
    );

    await tester.pumpWidget(KiranaCustomerApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('profile-name')),
      'Riya Sharma',
    );
    await tester.enterText(find.byKey(const Key('profile-mobile')), '12345');
    final Finder continueButton = find.byKey(const Key('profile-continue'));
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pump();

    expect(
      find.text('Valid 10-digit Indian mobile number daaliye'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('store-code')), findsNothing);

    await tester.enterText(
      find.byKey(const Key('profile-mobile')),
      '9876543210',
    );
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.text('All stores'), findsOneWidget);
    expect(find.byKey(const Key('store-code-action')), findsOneWidget);
    await tester.tap(find.byKey(const Key('store-code-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('store-code')), findsOneWidget);
  });
}

class _FakeRepository implements CustomerRepository {
  _FakeRepository({
    this.stores = const <CustomerStore>[],
    this.products = const <CustomerProduct>[],
  });

  final List<CustomerStore> stores;
  final List<CustomerProduct> products;

  @override
  Future<CustomerOrder> createOrder(CheckoutDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<List<CustomerOrder>> getOrders({
    required int storeId,
    required String customerPhone,
  }) async => const <CustomerOrder>[];

  @override
  Future<List<CustomerProduct>> getProducts(int storeId) async => products;

  @override
  Future<CustomerStore> getStoreByCode(String code) {
    return Future<CustomerStore>.value(
      stores.firstWhere(
        (CustomerStore store) => store.code == code,
        orElse: () => throw const CustomerRepositoryException('Not found'),
      ),
    );
  }

  @override
  Future<List<CustomerStore>> getStores() async => stores;
}

class _MemorySessionStore implements SessionStore {
  SavedSession value = const SavedSession();

  @override
  Future<void> clear() async => value = const SavedSession();

  @override
  Future<SavedSession> read() async => value;

  @override
  Future<void> write({required CustomerProfile profile, int? storeId}) async {
    value = SavedSession(profile: profile, storeId: storeId);
  }
}
