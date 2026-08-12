import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_customer/src/customer_controller.dart';
import 'package:kirana_customer/src/domain.dart';
import 'package:kirana_customer/src/repository.dart';
import 'package:kirana_customer/src/screens/checkout_page.dart';
import 'package:kirana_customer/src/screens/home_shell.dart';
import 'package:kirana_customer/src/session_store.dart';

void main() {
  testWidgets(
    'product, category search, and basket navigation stay connected',
    (WidgetTester tester) async {
      _usePhoneViewport(tester);
      final _NavigationRepository repository = _NavigationRepository();
      final CustomerController controller = await _connectedController(
        repository,
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(home: HomeShell(controller: controller)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Toor Dal').first);
      await tester.pumpAndSettle();
      expect(find.text('Product details'), findsWidgets);

      await tester.tap(find.byKey(const Key('detail-add-11')));
      await tester.pump();
      expect(controller.cartCount, 1);
      expect(find.text('Go to basket'), findsOneWidget);

      await tester.tap(find.text('Go to basket'));
      await tester.pumpAndSettle();
      expect(find.text('Your basket'), findsOneWidget);
      expect(find.text('Toor Dal'), findsOneWidget);

      await tester.tap(find.text('Shop'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View all'));
      await tester.pumpAndSettle();
      expect(find.text('All products'), findsOneWidget);

      await tester.tap(find.byTooltip('Search products'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'missing item');
      await tester.pump();
      expect(
        find.text('Is category mein abhi products nahi hain.'),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Search products'));
      await tester.pump();
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Toor Dal'), findsOneWidget);

      await tester.tap(find.text('Basket'));
      await tester.pumpAndSettle();
      expect(find.text('Your basket'), findsOneWidget);
    },
  );

  testWidgets('checkout shows busy state and submits only once', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    final Completer<CustomerOrder> pendingOrder = Completer<CustomerOrder>();
    final _NavigationRepository repository = _NavigationRepository(
      createOrderHandler: (CheckoutDraft draft) {
        return pendingOrder.future;
      },
    );
    final CustomerController controller = await _connectedController(
      repository,
    );
    addTearDown(controller.dispose);
    controller.setQuantity(_product, 1);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: Center(
              child: FilledButton(
                key: const Key('open-checkout'),
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) =>
                        CheckoutPage(controller: controller),
                  ),
                ),
                child: const Text('Open checkout'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open-checkout')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('checkout-address')),
      '12 Main Market Road',
    );
    await tester.ensureVisible(find.byKey(const Key('checkout-pincode')));
    await tester.enterText(find.byKey(const Key('checkout-pincode')), '302003');
    await tester.ensureVisible(find.byKey(const Key('place-order')));
    await tester.tap(find.byKey(const Key('place-order')));
    await tester.pump();

    expect(repository.createCalls, 1);
    expect(find.text('Order place ho raha hai...'), findsOneWidget);
    expect(controller.placingOrder, isTrue);

    await tester.tap(find.byKey(const Key('place-order')));
    await tester.pump();
    expect(repository.createCalls, 1);

    pendingOrder.complete(_createdOrder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Order placed!'), findsOneWidget);
    await tester.tap(find.text('Track order'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('open-checkout')), findsOneWidget);
    expect(controller.orders, <CustomerOrder>[_createdOrder]);
  });

  testWidgets('orders filter and profile help use live store data', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    final _NavigationRepository repository = _NavigationRepository(
      orders: <CustomerOrder>[
        _createdOrder,
        CustomerOrder(
          id: 'KS-DONE-2',
          storeId: 7,
          status: 'DELIVERED',
          paymentMethod: 'UPI',
          total: 90,
          createdAt: DateTime(2026, 8, 10),
          items: const <CustomerOrderItem>[],
        ),
      ],
    );
    final CustomerController controller = await _connectedController(
      repository,
    );
    addTearDown(controller.dispose);
    controller.setQuantity(_product, 1);
    await tester.pumpWidget(
      MaterialApp(home: HomeShell(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Orders'));
    await tester.pump();
    expect(find.text('Order #KS-TEST-1'), findsOneWidget);
    expect(find.text('Order #KS-DONE-2'), findsOneWidget);

    await tester.tap(find.text('Completed'));
    await tester.pump();
    expect(find.text('Order #KS-TEST-1'), findsNothing);
    expect(find.text('Order #KS-DONE-2'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pump();
    await tester.tap(find.text('Need help?'));
    await tester.pumpAndSettle();
    expect(find.text('Store contact'), findsOneWidget);
    expect(find.text('9876543210'), findsOneWidget);
    expect(find.text('Main Market'), findsWidgets);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Change store'));
    await tester.pumpAndSettle();
    expect(
      find.text('Store change karne par aapki current basket clear ho jayegi.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(controller.selectedStore, _store);
    expect(controller.cartCount, 1);
  });
}

void _usePhoneViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(411, 890);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
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
  openingTime: '08:00',
  closingTime: '22:00',
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
  _NavigationRepository repository,
) async {
  final CustomerController controller = CustomerController(
    repository,
    _NavigationSessionStore(),
  );
  await controller.initialize();
  return controller;
}

class _NavigationRepository implements CustomerRepository {
  _NavigationRepository({
    this.orders = const <CustomerOrder>[],
    this.createOrderHandler,
  });

  final List<CustomerOrder> orders;
  final Future<CustomerOrder> Function(CheckoutDraft draft)? createOrderHandler;
  int createCalls = 0;

  @override
  Future<CustomerOrder> createOrder(CheckoutDraft draft) {
    createCalls++;
    final Future<CustomerOrder> Function(CheckoutDraft draft)? handler =
        createOrderHandler;
    return handler == null
        ? Future<CustomerOrder>.value(_createdOrder)
        : handler(draft);
  }

  @override
  Future<List<CustomerOrder>> getOrders({
    required int storeId,
    required String customerPhone,
  }) async => orders;

  @override
  Future<List<CustomerProduct>> getProducts(int storeId) async =>
      const <CustomerProduct>[_product];

  @override
  Future<CustomerStore> getStoreByCode(String code) async => _store;

  @override
  Future<List<CustomerStore>> getStores() async => const <CustomerStore>[
    _store,
  ];
}

class _NavigationSessionStore implements SessionStore {
  SavedSession value = const SavedSession(
    profile: CustomerProfile(name: 'Riya', mobile: '9876543210'),
    storeId: 7,
  );

  @override
  Future<void> clear() async => value = const SavedSession();

  @override
  Future<SavedSession> read() async => value;

  @override
  Future<void> write({required CustomerProfile profile, int? storeId}) async {
    value = SavedSession(profile: profile, storeId: storeId);
  }
}
