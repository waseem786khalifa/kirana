import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_customer/src/customer_controller.dart';
import 'package:kirana_customer/src/domain.dart';
import 'package:kirana_customer/src/repository.dart';
import 'package:kirana_customer/src/screens/store_connect_page.dart';
import 'package:kirana_customer/src/session_store.dart';

void main() {
  testWidgets('renders a truthful dynamic three-store listing at phone size', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    final CustomerController controller = _controller(
      _ListingRepository(stores: _stores),
    )..stores = _stores;
    addTearDown(controller.dispose);

    await tester.pumpWidget(_harness(controller));
    await tester.pumpAndSettle();

    expect(find.text('3 stores  •  1 delivering now'), findsOneWidget);
    expect(find.text('Available now'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('featured-store-1')),
      findsOneWidget,
    );
    expect(find.text('Balaji General Store'), findsWidgets);
    expect(find.text('SAVE ₹80'), findsWidgets);
    expect(find.text('FREE delivery above ₹299'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('all-store-3')),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(find.text('Home delivery unavailable'), findsOneWidget);
    expect(find.textContaining('99 min'), findsNothing);
    expect(
      find.text(
        'Gupta Neighbourhood Supermarket With A Very Long Customer Facing Name',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('all-store-2')),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(find.text('CLOSED'), findsOneWidget);
    expect(find.textContaining('35-50 min'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('searches by area and name, then filters dynamic categories', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    final CustomerController controller = _controller(
      _ListingRepository(stores: _stores),
    )..stores = _stores;
    addTearDown(controller.dispose);

    await tester.pumpWidget(_harness(controller));
    await tester.pumpAndSettle();

    final Finder search = find.byKey(const Key('store-search'));
    await tester.enterText(search, 'jaipur');
    await tester.pump();
    expect(find.text('All stores (1)'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('all-store-1')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('all-store-2')), findsNothing);
    expect(find.byKey(const ValueKey<String>('all-store-3')), findsNothing);

    await tester.enterText(search, 'sharma');
    await tester.pump();
    expect(find.text('All stores (1)'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('all-store-1')), findsNothing);
    expect(find.byKey(const ValueKey<String>('all-store-2')), findsOneWidget);
    expect(find.text('CLOSED'), findsOneWidget);

    await tester.enterText(search, '');
    await tester.pump();
    final Finder oilCategory = find.bySemanticsLabel(
      RegExp('Cooking Oil category'),
    );
    expect(oilCategory, findsOneWidget);
    await tester.tap(oilCategory);
    await tester.pump();

    expect(find.text('All stores (1)'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('all-store-1')), findsNothing);
    expect(find.byKey(const ValueKey<String>('all-store-2')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('all-store-3')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('code sheet clears an error and normalizes successful input', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    final _ListingRepository repository = _ListingRepository(
      stores: const <CustomerStore>[],
      codeStore: _stores.first,
      failFirstCode: true,
    );
    final CustomerController controller = _controller(repository);
    addTearDown(controller.dispose);

    await tester.pumpWidget(_harness(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('store-code-action')));
    await tester.pumpAndSettle();
    expect(find.text('Store code se connect karein'), findsOneWidget);

    final Finder codeField = find.byKey(const Key('store-code'));
    await tester.enterText(codeField, 'balaji123');
    await tester.tap(find.byKey(const Key('connect-store')));
    await tester.pumpAndSettle();

    expect(find.text('Store code nahi mila.'), findsOneWidget);
    expect(repository.requestedCodes, <String>['BALAJI123']);

    await tester.enterText(codeField, 'balaji12');
    await tester.pump();
    expect(find.text('Store code nahi mila.'), findsNothing);
    await tester.enterText(codeField, 'balaji123');
    await tester.tap(find.byKey(const Key('connect-store')));
    await tester.pumpAndSettle();

    expect(repository.requestedCodes, <String>['BALAJI123', 'BALAJI123']);
    expect(controller.selectedStore?.id, 1);
    expect(find.text('Store code se connect karein'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows loading, recoverable error, and empty states', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);

    final CustomerController loading = _controller(
      _ListingRepository(stores: _stores),
    )..loadingStores = true;
    addTearDown(loading.dispose);
    await tester.pumpWidget(_harness(loading));
    await tester.pump();
    expect(find.text('Finding available kirana stores...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    expect(
      find.text('Abhi koi store list mein available nahi hai.'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);

    final CustomerController failed = _controller(
      _ListingRepository(stores: <CustomerStore>[_stores.first]),
    )..storesError = 'Store server unavailable.';
    addTearDown(failed.dispose);
    await tester.pumpWidget(_harness(failed));
    await tester.pump();
    expect(find.text('Store server unavailable.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Store server unavailable.'), findsNothing);
    expect(find.text('1 stores  •  1 delivering now'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final CustomerController empty = _controller(
      _ListingRepository(stores: const <CustomerStore>[]),
    );
    addTearDown(empty.dispose);
    await tester.pumpWidget(_harness(empty));
    await tester.pump();
    expect(
      find.text('Abhi koi store list mein available nahi hai.'),
      findsOneWidget,
    );
    expect(find.text('Store code se connect kar sakte hain.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _usePhoneViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(411, 890);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Widget _harness(CustomerController controller) {
  return MaterialApp(
    home: AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) => StoreConnectPage(
        key: ValueKey<CustomerController>(controller),
        controller: controller,
      ),
    ),
  );
}

CustomerController _controller(_ListingRepository repository) {
  return CustomerController(repository, _ListingSessionStore())
    ..profile = const CustomerProfile(name: 'Waseem', mobile: '9876543210')
    ..booting = false;
}

final List<CustomerStore> _stores = <CustomerStore>[
  const CustomerStore(
    id: 1,
    code: 'BALAJI123',
    name: 'Balaji General Store',
    address:
        'Shop No. 12, Main Market, Chaura Rasta, Jaipur, Near City Post Office, 302003',
    isOpen: true,
    deliveryAvailable: true,
    minimumOrder: 100,
    freeDeliveryAbove: 299,
    deliveryCharge: 30,
    expectedDeliveryTime: '30-45 min',
    codEnabled: true,
    upiEnabled: true,
    description: 'Daily groceries and household essentials.',
    categories: <String>['Atta & Flour', 'Rice'],
    productCount: 42,
    maxSaving: 80,
    maxDiscountPercent: 20,
  ),
  const CustomerStore(
    id: 2,
    code: 'SHARMA456',
    name: 'Sharma Daily Needs',
    address: 'Plot 45, Station Road, Jodhpur, Rajasthan, 342001',
    isOpen: false,
    deliveryAvailable: true,
    minimumOrder: 150,
    freeDeliveryAbove: 600,
    deliveryCharge: 35,
    expectedDeliveryTime: '35-50 min',
    codEnabled: true,
    upiEnabled: false,
    description: 'Trusted neighbourhood kirana store.',
    categories: <String>['Cooking Oil', 'Ghee'],
    productCount: 18,
    maxSaving: 65,
    maxDiscountPercent: 15,
  ),
  const CustomerStore(
    id: 3,
    code: 'GUPTA789',
    name:
        'Gupta Neighbourhood Supermarket With A Very Long Customer Facing Name',
    address:
        'A deliberately long address near the Old Bus Stand, Bikaner, beside the Hanuman Temple, Rajasthan, 334001',
    isOpen: true,
    deliveryAvailable: false,
    minimumOrder: 0,
    freeDeliveryAbove: 0,
    deliveryCharge: 0,
    expectedDeliveryTime: '99 min should not be shown',
    codEnabled: true,
    upiEnabled: true,
    description:
        'A long searchable description for groceries and household supplies.',
    categories: <String>[
      'Snacks & Namkeen',
      'Household and Personal Care Essentials',
    ],
    productCount: 7,
    maxSaving: 999,
    maxDiscountPercent: 30,
  ),
];

class _ListingRepository implements CustomerRepository {
  _ListingRepository({
    required this.stores,
    this.codeStore,
    this.failFirstCode = false,
  });

  final List<CustomerStore> stores;
  final CustomerStore? codeStore;
  final bool failFirstCode;
  final List<String> requestedCodes = <String>[];

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
  Future<List<CustomerProduct>> getProducts(int storeId) async =>
      const <CustomerProduct>[];

  @override
  Future<CustomerStore> getStoreByCode(String code) async {
    requestedCodes.add(code);
    if (failFirstCode && requestedCodes.length == 1) {
      throw const CustomerRepositoryException('Store code nahi mila.');
    }
    final CustomerStore? result = codeStore;
    if (result == null) {
      throw const CustomerRepositoryException('Store code nahi mila.');
    }
    return result;
  }

  @override
  Future<List<CustomerStore>> getStores() async => stores;
}

class _ListingSessionStore implements SessionStore {
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
