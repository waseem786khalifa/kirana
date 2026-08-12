import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_core/kirana_core.dart';

void main() {
  group('models', () {
    test('Store round-trips snake_case JSON', () {
      final store = Store.fromJson({
        'id': 7,
        'code': 'BALAJI123',
        'name': 'Balaji Kirana',
        'owner_name': 'Asha',
        'phone': '9876543210',
        'address': 'Station Road',
        'landmark': 'Clock tower',
        'pincode': '302001',
        'is_open': 1,
        'logo': 'logo.png',
        'banner': 'banner.png',
        'description': 'Daily essentials',
        'opening_time': '08:00',
        'closing_time': '21:00',
        'delivery_settings': {
          'delivery_available': true,
          'radius_km': '4.5',
          'min_order': 200,
          'free_delivery_above': 500,
          'delivery_charge': 25,
          'expected_delivery_time': '30-45 min',
          'scheduled_delivery_enabled': false,
        },
        'payment_settings': {
          'cod_enabled': true,
          'upi_enabled': true,
          'pay_at_shop_enabled': true,
          'online_udhaar_enabled': false,
        },
        'allow_nearby_discovery': true,
        'categories': ['Grocery', 'Snacks'],
        'product_count': 18,
        'max_saving': 75,
        'max_discount_percent': 20,
      });

      expect(store.id, 7);
      expect(store.deliverySettings.radiusKm, 4.5);
      expect(store.paymentSettings.upiEnabled, isTrue);
      expect(store.categories, ['Grocery', 'Snacks']);
      expect(store.productCount, 18);
      expect(store.maxSaving, 75);
      expect(store.maxDiscountPercent, 20);
      expect(store.toJson()['owner_name'], 'Asha');
    });

    test('Order decodes enums, items, dates, and immutable collections', () {
      final order = Order.fromJson({
        'id': 42,
        'order_number': 'KS1042',
        'store_id': 7,
        'customer_id': 3,
        'customer_name': 'Ravi',
        'customer_phone': '9876543210',
        'delivery_address': {
          'id': 9,
          'label': 'Home',
          'address_line': '12 Main Road',
          'landmark': '',
          'pincode': '302001',
        },
        'items': [
          {
            'id': 4,
            'product_id': 11,
            'name_en': 'Atta',
            'name_hi': 'आटा',
            'name_mrw': 'Aato',
            'pack_size': '5 kg',
            'price': 240,
            'mrp': 260,
            'quantity': 2,
          },
        ],
        'subtotal': 480,
        'discount': 0,
        'delivery_charge': 20,
        'total_amount': 500,
        'payment_method': 'COD',
        'payment_status': 'PENDING',
        'status': 'ACCEPTED',
        'created_at': '2026-08-08T10:30:00Z',
        'updated_at': '2026-08-08T10:35:00Z',
      });

      expect(order.status, OrderStatus.accepted);
      expect(order.paymentMethod, PaymentMethod.cod);
      expect(order.itemCount, 2);
      expect(order.items.single.lineTotal, 480);
      expect(order.createdAt, DateTime.utc(2026, 8, 8, 10, 30));
      expect(() => order.items.add(order.items.first), throwsUnsupportedError);
    });

    test('CreateOrderRequest only sends authoritative order inputs', () {
      const product = Product(
        id: 11,
        storeId: 7,
        nameEn: 'Atta',
        category: 'Staples',
        packSize: '5 kg',
        mrp: 260,
        sellingPrice: 240,
      );
      final request = CreateOrderRequest(
        storeId: 7,
        customerName: 'Ravi',
        customerPhone: '9876543210',
        deliveryAddress: const Address(
          label: 'Home',
          addressLine: '12 Main Road',
          pincode: '302001',
        ),
        items: const [CartItem(product: product, quantity: 2)],
        paymentMethod: PaymentMethod.upi,
        idempotencyKey: 'checkout-123',
      );

      final json = request.toJson();
      expect(json['store_id'], 7);
      expect(json['payment_method'], 'UPI');
      expect(json['items'], [
        {'product_id': 11, 'quantity': 2},
      ]);
      expect(json, isNot(contains('total_amount')));
      expect(json, isNot(contains('subtotal')));
    });
  });

  group('enum helpers', () {
    test('enforces backend order transition graph', () {
      expect(
        OrderStatus.newOrder.canTransitionTo(OrderStatus.accepted),
        isTrue,
      );
      expect(
        OrderStatus.outForDelivery.canTransitionTo(OrderStatus.cancelled),
        isFalse,
      );
      expect(OrderStatus.delivered.isTerminal, isTrue);
      expect(
        OrderStatus.fromJson('OUT_FOR_DELIVERY'),
        OrderStatus.outForDelivery,
      );
    });
  });
}
