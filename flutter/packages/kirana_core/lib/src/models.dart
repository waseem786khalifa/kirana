import 'enums.dart';
import 'json_utils.dart';

class DeliverySettings {
  const DeliverySettings({
    this.deliveryAvailable = false,
    this.radiusKm = 0,
    this.minOrder = 0,
    this.freeDeliveryAbove = 0,
    this.deliveryCharge = 0,
    this.expectedDeliveryTime = '',
    this.scheduledDeliveryEnabled = false,
  });

  final bool deliveryAvailable;
  final double radiusKm;
  final double minOrder;
  final double freeDeliveryAbove;
  final double deliveryCharge;
  final String expectedDeliveryTime;
  final bool scheduledDeliveryEnabled;

  factory DeliverySettings.fromJson(JsonMap json) => DeliverySettings(
    deliveryAvailable: boolValue(json['delivery_available']),
    radiusKm: doubleValue(json['radius_km']),
    minOrder: doubleValue(json['min_order']),
    freeDeliveryAbove: doubleValue(json['free_delivery_above']),
    deliveryCharge: doubleValue(json['delivery_charge']),
    expectedDeliveryTime: stringValue(json['expected_delivery_time']),
    scheduledDeliveryEnabled: boolValue(json['scheduled_delivery_enabled']),
  );

  JsonMap toJson() => {
    'delivery_available': deliveryAvailable,
    'radius_km': radiusKm,
    'min_order': minOrder,
    'free_delivery_above': freeDeliveryAbove,
    'delivery_charge': deliveryCharge,
    'expected_delivery_time': expectedDeliveryTime,
    'scheduled_delivery_enabled': scheduledDeliveryEnabled,
  };
}

class PaymentSettings {
  const PaymentSettings({
    this.codEnabled = true,
    this.upiEnabled = false,
    this.payAtShopEnabled = false,
    this.onlineUdhaarEnabled = false,
  });

  final bool codEnabled;
  final bool upiEnabled;
  final bool payAtShopEnabled;
  final bool onlineUdhaarEnabled;

  factory PaymentSettings.fromJson(JsonMap json) => PaymentSettings(
    codEnabled: boolValue(json['cod_enabled'], fallback: true),
    upiEnabled: boolValue(json['upi_enabled']),
    payAtShopEnabled: boolValue(json['pay_at_shop_enabled']),
    onlineUdhaarEnabled: boolValue(json['online_udhaar_enabled']),
  );

  JsonMap toJson() => {
    'cod_enabled': codEnabled,
    'upi_enabled': upiEnabled,
    'pay_at_shop_enabled': payAtShopEnabled,
    'online_udhaar_enabled': onlineUdhaarEnabled,
  };
}

class Store {
  const Store({
    required this.id,
    required this.code,
    required this.name,
    this.ownerName = '',
    this.phone = '',
    this.address = '',
    this.landmark = '',
    this.pincode = '',
    this.distanceKm,
    this.isOpen = true,
    this.logo = '',
    this.banner = '',
    this.description = '',
    this.openingTime = '',
    this.closingTime = '',
    this.deliverySettings = const DeliverySettings(),
    this.paymentSettings = const PaymentSettings(),
    this.allowNearbyDiscovery = false,
    this.categories = const <String>[],
    this.productCount = 0,
    this.maxSaving = 0,
    this.maxDiscountPercent = 0,
  });

  final int id;
  final String code;
  final String name;
  final String ownerName;
  final String phone;
  final String address;
  final String landmark;
  final String pincode;
  final double? distanceKm;
  final bool isOpen;
  final String logo;
  final String banner;
  final String description;
  final String openingTime;
  final String closingTime;
  final DeliverySettings deliverySettings;
  final PaymentSettings paymentSettings;
  final bool allowNearbyDiscovery;
  final List<String> categories;
  final int productCount;
  final double maxSaving;
  final int maxDiscountPercent;

  factory Store.fromJson(JsonMap json) => Store(
    id: intValue(json['id']),
    code: stringValue(json['code']),
    name: stringValue(json['name']),
    ownerName: stringValue(json['owner_name']),
    phone: stringValue(json['phone']),
    address: stringValue(json['address']),
    landmark: stringValue(json['landmark']),
    pincode: stringValue(json['pincode']),
    distanceKm: nullableDoubleValue(json['distance_km']),
    isOpen: boolValue(json['is_open'], fallback: true),
    logo: stringValue(json['logo']),
    banner: stringValue(json['banner']),
    description: stringValue(json['description']),
    openingTime: stringValue(json['opening_time']),
    closingTime: stringValue(json['closing_time']),
    deliverySettings: json['delivery_settings'] == null
        ? const DeliverySettings()
        : DeliverySettings.fromJson(
            jsonMap(json['delivery_settings'], context: 'delivery_settings'),
          ),
    paymentSettings: json['payment_settings'] == null
        ? const PaymentSettings()
        : PaymentSettings.fromJson(
            jsonMap(json['payment_settings'], context: 'payment_settings'),
          ),
    allowNearbyDiscovery: boolValue(json['allow_nearby_discovery']),
    categories: json['categories'] is List
        ? jsonList(json['categories'], context: 'categories')
              .map(stringValue)
              .where((String value) => value.trim().isNotEmpty)
              .toList(growable: false)
        : const <String>[],
    productCount: intValue(json['product_count']),
    maxSaving: doubleValue(json['max_saving']),
    maxDiscountPercent: intValue(json['max_discount_percent']),
  );

  JsonMap toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'owner_name': ownerName,
    'phone': phone,
    'address': address,
    'landmark': landmark,
    'pincode': pincode,
    if (distanceKm != null) 'distance_km': distanceKm,
    'is_open': isOpen,
    'logo': logo,
    'banner': banner,
    'description': description,
    'opening_time': openingTime,
    'closing_time': closingTime,
    'delivery_settings': deliverySettings.toJson(),
    'payment_settings': paymentSettings.toJson(),
    'allow_nearby_discovery': allowNearbyDiscovery,
    'categories': categories,
    'product_count': productCount,
    'max_saving': maxSaving,
    'max_discount_percent': maxDiscountPercent,
  };
}

class Product {
  const Product({
    required this.id,
    required this.storeId,
    required this.nameEn,
    this.nameHi = '',
    this.nameMrw = '',
    required this.category,
    required this.packSize,
    required this.mrp,
    required this.sellingPrice,
    this.stock = 0,
    this.image = '',
    this.availableForOnline = true,
    this.isHidden = false,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int storeId;
  final String nameEn;
  final String nameHi;
  final String nameMrw;
  final String category;
  final String packSize;
  final double mrp;
  final double sellingPrice;
  final int stock;
  final String image;
  final bool availableForOnline;
  final bool isHidden;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  double get discountPercent => mrp <= 0
      ? 0
      : ((mrp - sellingPrice) / mrp * 100).clamp(0, 100).toDouble();

  bool get isInStock => stock > 0;

  factory Product.fromJson(JsonMap json) => Product(
    id: intValue(json['id']),
    storeId: intValue(json['store_id']),
    nameEn: stringValue(json['name_en']),
    nameHi: stringValue(json['name_hi']),
    nameMrw: stringValue(json['name_mrw']),
    category: stringValue(json['category']),
    packSize: stringValue(json['pack_size']),
    mrp: doubleValue(json['mrp']),
    sellingPrice: doubleValue(json['selling_price']),
    stock: intValue(json['stock']),
    image: stringValue(json['image']),
    availableForOnline: boolValue(json['available_for_online'], fallback: true),
    isHidden: boolValue(json['is_hidden']),
    createdAt: dateTimeValue(json['created_at']),
    updatedAt: dateTimeValue(json['updated_at']),
  );

  JsonMap toJson() => {
    'id': id,
    'store_id': storeId,
    'name_en': nameEn,
    'name_hi': nameHi,
    'name_mrw': nameMrw,
    'category': category,
    'pack_size': packSize,
    'mrp': mrp,
    'selling_price': sellingPrice,
    'stock': stock,
    'image': image,
    'available_for_online': availableForOnline,
    'is_hidden': isHidden,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
  };
}

class CartItem {
  const CartItem({required this.product, this.quantity = 1})
    : assert(quantity > 0, 'quantity must be greater than zero');

  final Product product;
  final int quantity;

  double get lineTotal => product.sellingPrice * quantity;
  double get lineMrp => product.mrp * quantity;

  CartItem copyWith({Product? product, int? quantity}) => CartItem(
    product: product ?? this.product,
    quantity: quantity ?? this.quantity,
  );

  factory CartItem.fromJson(JsonMap json) => CartItem(
    product: Product.fromJson(jsonMap(json['product'], context: 'product')),
    quantity: intValue(json['quantity'], fallback: 1),
  );

  JsonMap toJson() => {'product': product.toJson(), 'quantity': quantity};

  JsonMap toOrderJson() => {'product_id': product.id, 'quantity': quantity};
}

class Address {
  const Address({
    this.id,
    required this.label,
    required this.addressLine,
    this.landmark = '',
    this.pincode = '',
  });

  final int? id;
  final String label;
  final String addressLine;
  final String landmark;
  final String pincode;

  factory Address.fromJson(JsonMap json) => Address(
    id: nullableIntValue(json['id']),
    label: stringValue(json['label'], fallback: 'Home'),
    addressLine: stringValue(json['address_line']),
    landmark: stringValue(json['landmark']),
    pincode: stringValue(json['pincode']),
  );

  JsonMap toJson() => {
    if (id != null) 'id': id,
    'label': label,
    'address_line': addressLine,
    'landmark': landmark,
    'pincode': pincode,
  };
}

class Customer {
  Customer({
    required this.id,
    required this.storeId,
    required this.name,
    required this.mobile,
    List<Address> addresses = const [],
    this.allowOnlineUdhaar = false,
    this.udhaarBalance = 0,
    this.totalOrders = 0,
    this.totalSpent = 0,
    this.lastOrderDate,
    this.createdAt,
    this.updatedAt,
  }) : addresses = List.unmodifiable(addresses);

  final int id;
  final int storeId;
  final String name;
  final String mobile;
  final List<Address> addresses;
  final bool allowOnlineUdhaar;
  final double udhaarBalance;
  final int totalOrders;
  final double totalSpent;
  final DateTime? lastOrderDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Customer.fromJson(JsonMap json) => Customer(
    id: intValue(json['id']),
    storeId: intValue(json['store_id']),
    name: stringValue(json['name']),
    mobile: stringValue(json['mobile']),
    addresses: json['addresses'] is List
        ? jsonList(json['addresses'], context: 'addresses')
              .map(
                (item) => Address.fromJson(jsonMap(item, context: 'address')),
              )
              .toList()
        : const [],
    allowOnlineUdhaar: boolValue(json['allow_online_udhaar']),
    udhaarBalance: doubleValue(json['udhaar_balance']),
    totalOrders: intValue(json['total_orders']),
    totalSpent: doubleValue(json['total_spent']),
    lastOrderDate: dateTimeValue(json['last_order_date']),
    createdAt: dateTimeValue(json['created_at']),
    updatedAt: dateTimeValue(json['updated_at']),
  );

  JsonMap toJson() => {
    'id': id,
    'store_id': storeId,
    'name': name,
    'mobile': mobile,
    'addresses': addresses.map((address) => address.toJson()).toList(),
    'allow_online_udhaar': allowOnlineUdhaar,
    'udhaar_balance': udhaarBalance,
    'total_orders': totalOrders,
    'total_spent': totalSpent,
    if (lastOrderDate != null)
      'last_order_date': lastOrderDate!.toIso8601String(),
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
  };
}

class OrderItem {
  const OrderItem({
    this.id,
    required this.productId,
    required this.nameEn,
    this.nameHi = '',
    this.nameMrw = '',
    this.packSize = '',
    required this.price,
    double? mrp,
    required this.quantity,
    this.originalQuantity,
  }) : mrp = mrp ?? price;

  final int? id;
  final int productId;
  final String nameEn;
  final String nameHi;
  final String nameMrw;
  final String packSize;
  final double price;
  final double mrp;
  final int quantity;
  final int? originalQuantity;

  double get lineTotal => price * quantity;
  double get lineMrp => mrp * quantity;
  bool get wasModified =>
      originalQuantity != null && originalQuantity != quantity;

  factory OrderItem.fromJson(JsonMap json) => OrderItem(
    id: nullableIntValue(json['id']),
    productId: intValue(json['product_id']),
    nameEn: stringValue(json['name_en']),
    nameHi: stringValue(json['name_hi']),
    nameMrw: stringValue(json['name_mrw']),
    packSize: stringValue(json['pack_size']),
    price: doubleValue(json['price']),
    mrp: nullableDoubleValue(json['mrp']),
    quantity: intValue(json['quantity'], fallback: 1),
    originalQuantity: nullableIntValue(json['original_quantity']),
  );

  JsonMap toJson() => {
    if (id != null) 'id': id,
    'product_id': productId,
    'name_en': nameEn,
    'name_hi': nameHi,
    'name_mrw': nameMrw,
    'pack_size': packSize,
    'price': price,
    'mrp': mrp,
    'quantity': quantity,
    if (originalQuantity != null) 'original_quantity': originalQuantity,
  };
}

class Order {
  Order({
    required this.id,
    this.orderNumber = '',
    required this.storeId,
    this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required List<OrderItem> items,
    this.subtotal = 0,
    this.discount = 0,
    this.deliveryCharge = 0,
    this.totalAmount = 0,
    this.paymentMethod = PaymentMethod.cod,
    this.paymentStatus = PaymentStatus.pending,
    this.status = OrderStatus.newOrder,
    this.rejectionReason,
    this.deliveryInstructions,
    this.scheduledSlot,
    this.deliveryStaffId,
    this.deliveryStaffName,
    this.deliveryStaffPhone,
    this.deliveryOtp,
    this.createdAt,
    this.updatedAt,
    this.modifiedByMerchant = false,
  }) : items = List.unmodifiable(items);

  final int id;
  final String orderNumber;
  final int storeId;
  final int? customerId;
  final String customerName;
  final String customerPhone;
  final Address deliveryAddress;
  final List<OrderItem> items;
  final double subtotal;
  final double discount;
  final double deliveryCharge;
  final double totalAmount;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final OrderStatus status;
  final String? rejectionReason;
  final String? deliveryInstructions;
  final String? scheduledSlot;
  final int? deliveryStaffId;
  final String? deliveryStaffName;
  final String? deliveryStaffPhone;
  final String? deliveryOtp;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool modifiedByMerchant;

  int get itemCount => items.fold(0, (total, item) => total + item.quantity);
  bool get isTerminal => status.isTerminal;
  bool get canCancel =>
      status.allowedTransitions.contains(OrderStatus.cancelled);
  String get displayNumber => orderNumber.isEmpty ? id.toString() : orderNumber;

  factory Order.fromJson(JsonMap json) => Order(
    id: intValue(json['id']),
    orderNumber: stringValue(json['order_number']),
    storeId: intValue(json['store_id']),
    customerId: nullableIntValue(json['customer_id']),
    customerName: stringValue(json['customer_name']),
    customerPhone: stringValue(json['customer_phone']),
    deliveryAddress: Address.fromJson(
      jsonMap(json['delivery_address'], context: 'delivery_address'),
    ),
    items: jsonList(json['items'], context: 'items')
        .map((item) => OrderItem.fromJson(jsonMap(item, context: 'order item')))
        .toList(),
    subtotal: doubleValue(json['subtotal']),
    discount: doubleValue(json['discount']),
    deliveryCharge: doubleValue(json['delivery_charge']),
    totalAmount: doubleValue(json['total_amount']),
    paymentMethod: PaymentMethod.fromJson(json['payment_method']),
    paymentStatus: PaymentStatus.fromJson(json['payment_status']),
    status: OrderStatus.fromJson(json['status']),
    rejectionReason: json['rejection_reason']?.toString(),
    deliveryInstructions: json['delivery_instructions']?.toString(),
    scheduledSlot: json['scheduled_slot']?.toString(),
    deliveryStaffId: nullableIntValue(json['delivery_staff_id']),
    deliveryStaffName: json['delivery_staff_name']?.toString(),
    deliveryStaffPhone: json['delivery_staff_phone']?.toString(),
    deliveryOtp: json['delivery_otp']?.toString(),
    createdAt: dateTimeValue(json['created_at']),
    updatedAt: dateTimeValue(json['updated_at']),
    modifiedByMerchant: boolValue(json['modified_by_merchant']),
  );

  JsonMap toJson() => {
    'id': id,
    'order_number': orderNumber,
    'store_id': storeId,
    if (customerId != null) 'customer_id': customerId,
    'customer_name': customerName,
    'customer_phone': customerPhone,
    'delivery_address': deliveryAddress.toJson(),
    'items': items.map((item) => item.toJson()).toList(),
    'subtotal': subtotal,
    'discount': discount,
    'delivery_charge': deliveryCharge,
    'total_amount': totalAmount,
    'payment_method': paymentMethod.apiValue,
    'payment_status': paymentStatus.apiValue,
    'status': status.apiValue,
    if (rejectionReason != null) 'rejection_reason': rejectionReason,
    if (deliveryInstructions != null)
      'delivery_instructions': deliveryInstructions,
    if (scheduledSlot != null) 'scheduled_slot': scheduledSlot,
    if (deliveryStaffId != null) 'delivery_staff_id': deliveryStaffId,
    if (deliveryStaffName != null) 'delivery_staff_name': deliveryStaffName,
    if (deliveryStaffPhone != null) 'delivery_staff_phone': deliveryStaffPhone,
    if (deliveryOtp != null) 'delivery_otp': deliveryOtp,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    'modified_by_merchant': modifiedByMerchant,
  };
}

class CreateOrderRequest {
  CreateOrderRequest({
    required this.storeId,
    this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required List<CartItem> items,
    required this.paymentMethod,
    this.deliveryInstructions,
    this.scheduledSlot,
    this.idempotencyKey,
  }) : items = List.unmodifiable(items) {
    if (items.isEmpty) {
      throw ArgumentError.value(items, 'items', 'Order must contain an item.');
    }
  }

  final int storeId;
  final int? customerId;
  final String customerName;
  final String customerPhone;
  final Address deliveryAddress;
  final List<CartItem> items;
  final PaymentMethod paymentMethod;
  final String? deliveryInstructions;
  final String? scheduledSlot;
  final String? idempotencyKey;

  JsonMap toJson() => {
    'store_id': storeId,
    if (customerId != null)
      'customer_id': customerId
    else
      'customer': {
        'name': customerName,
        'mobile': customerPhone,
        'address': deliveryAddress.toJson(),
      },
    'items': items.map((item) => item.toOrderJson()).toList(),
    'payment_method': paymentMethod.apiValue,
    if (deliveryInstructions != null && deliveryInstructions!.isNotEmpty)
      'delivery_instructions': deliveryInstructions,
    if (scheduledSlot != null && scheduledSlot!.isNotEmpty)
      'scheduled_slot': scheduledSlot,
    if (idempotencyKey != null && idempotencyKey!.isNotEmpty)
      'idempotency_key': idempotencyKey,
  };
}

class DeliveryStaff {
  const DeliveryStaff({
    required this.id,
    required this.storeId,
    required this.name,
    required this.mobile,
    this.isActive = true,
    this.assignedOrdersCount = 0,
    this.cashCollectedToday = 0,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int storeId;
  final String name;
  final String mobile;
  final bool isActive;
  final int assignedOrdersCount;
  final double cashCollectedToday;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory DeliveryStaff.fromJson(JsonMap json) => DeliveryStaff(
    id: intValue(json['id']),
    storeId: intValue(json['store_id']),
    name: stringValue(json['name']),
    mobile: stringValue(json['mobile']),
    isActive: boolValue(json['is_active'], fallback: true),
    assignedOrdersCount: intValue(json['assigned_orders_count']),
    cashCollectedToday: doubleValue(json['cash_collected_today']),
    createdAt: dateTimeValue(json['created_at']),
    updatedAt: dateTimeValue(json['updated_at']),
  );

  JsonMap toJson() => {
    'id': id,
    'store_id': storeId,
    'name': name,
    'mobile': mobile,
    'is_active': isActive,
    'assigned_orders_count': assignedOrdersCount,
    'cash_collected_today': cashCollectedToday,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
  };
}

class DeliveryLoginResult {
  const DeliveryLoginResult({
    required this.token,
    required this.tokenType,
    required this.expiresAt,
    required this.staff,
  });

  final String token;
  final String tokenType;
  final DateTime? expiresAt;
  final DeliveryStaff staff;

  factory DeliveryLoginResult.fromJson(JsonMap json) => DeliveryLoginResult(
    token: stringValue(json['token']),
    tokenType: stringValue(json['token_type'], fallback: 'Bearer'),
    expiresAt: dateTimeValue(json['expires_at']),
    staff: DeliveryStaff.fromJson(jsonMap(json['staff'], context: 'staff')),
  );

  JsonMap toJson() => {
    'token': token,
    'token_type': tokenType,
    if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
    'staff': staff.toJson(),
  };
}

class KhataEntry {
  const KhataEntry({
    required this.id,
    required this.storeId,
    required this.customerId,
    this.date,
    required this.type,
    required this.amount,
    this.orderId,
    this.note = '',
    this.balanceAfter = 0,
    this.createdAt,
  });

  final int id;
  final int storeId;
  final int customerId;
  final DateTime? date;
  final KhataEntryType type;
  final double amount;
  final int? orderId;
  final String note;
  final double balanceAfter;
  final DateTime? createdAt;

  factory KhataEntry.fromJson(JsonMap json) => KhataEntry(
    id: intValue(json['id']),
    storeId: intValue(json['store_id']),
    customerId: intValue(json['customer_id']),
    date: dateTimeValue(json['date']),
    type: KhataEntryType.fromJson(json['type']),
    amount: doubleValue(json['amount']),
    orderId: nullableIntValue(json['order_id']),
    note: stringValue(json['note']),
    balanceAfter: doubleValue(json['balance_after']),
    createdAt: dateTimeValue(json['created_at']),
  );

  JsonMap toJson() => {
    'id': id,
    'store_id': storeId,
    'customer_id': customerId,
    if (date != null) 'date': _dateOnly(date!),
    'type': type.apiValue,
    'amount': amount,
    if (orderId != null) 'order_id': orderId,
    'note': note,
    'balance_after': balanceAfter,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
  };
}

class PaymentBreakdown {
  const PaymentBreakdown({
    this.cod = 0,
    this.upi = 0,
    this.payAtShop = 0,
    this.udhaar = 0,
  });

  final double cod;
  final double upi;
  final double payAtShop;
  final double udhaar;

  factory PaymentBreakdown.fromJson(JsonMap json) => PaymentBreakdown(
    cod: doubleValue(json['cod']),
    upi: doubleValue(json['upi']),
    payAtShop: doubleValue(json['pay_at_shop']),
    udhaar: doubleValue(json['udhaar']),
  );

  JsonMap toJson() => {
    'cod': cod,
    'upi': upi,
    'pay_at_shop': payAtShop,
    'udhaar': udhaar,
  };
}

class SaleRecord {
  const SaleRecord({
    required this.id,
    required this.storeId,
    this.orderId,
    required this.channel,
    required this.amount,
    required this.paymentMethod,
    this.date,
    this.itemCount = 0,
  });

  final int id;
  final int storeId;
  final int? orderId;
  final String channel;
  final double amount;
  final PaymentMethod paymentMethod;
  final DateTime? date;
  final int itemCount;

  factory SaleRecord.fromJson(JsonMap json) => SaleRecord(
    id: intValue(json['id']),
    storeId: intValue(json['store_id']),
    orderId: nullableIntValue(json['order_id']),
    channel: stringValue(json['channel']),
    amount: doubleValue(json['amount']),
    paymentMethod: PaymentMethod.fromJson(json['payment_method']),
    date: dateTimeValue(json['date']),
    itemCount: intValue(json['item_count']),
  );

  JsonMap toJson() => {
    'id': id,
    'store_id': storeId,
    if (orderId != null) 'order_id': orderId,
    'channel': channel,
    'amount': amount,
    'payment_method': paymentMethod.apiValue,
    if (date != null) 'date': _dateOnly(date!),
    'item_count': itemCount,
  };
}

class ReportSummary {
  ReportSummary({
    this.storeId = 0,
    this.dateFrom,
    this.dateTo,
    this.counterSales = 0,
    this.onlineSales = 0,
    this.totalSales = 0,
    this.orderCount = 0,
    this.deliveredOrders = 0,
    this.averageOrderValue = 0,
    this.paymentBreakdown = const PaymentBreakdown(),
    List<SaleRecord> salesRecords = const [],
  }) : salesRecords = List.unmodifiable(salesRecords);

  final int storeId;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final double counterSales;
  final double onlineSales;
  final double totalSales;
  final int orderCount;
  final int deliveredOrders;
  final double averageOrderValue;
  final PaymentBreakdown paymentBreakdown;
  final List<SaleRecord> salesRecords;

  int get totalOrders => orderCount;
  double get totalRevenue => totalSales;

  factory ReportSummary.fromJson(JsonMap json) => ReportSummary(
    storeId: intValue(json['store_id']),
    dateFrom: dateTimeValue(json['date_from']),
    dateTo: dateTimeValue(json['date_to']),
    counterSales: doubleValue(json['counter_sales']),
    onlineSales: doubleValue(json['online_sales']),
    totalSales: doubleValue(json['total_sales']),
    orderCount: intValue(json['order_count']),
    deliveredOrders: intValue(json['delivered_orders']),
    averageOrderValue: doubleValue(json['average_order_value']),
    paymentBreakdown: json['payment_breakdown'] == null
        ? const PaymentBreakdown()
        : PaymentBreakdown.fromJson(
            jsonMap(json['payment_breakdown'], context: 'payment_breakdown'),
          ),
    salesRecords: json['sales_records'] is List
        ? jsonList(json['sales_records'], context: 'sales_records')
              .map(
                (item) =>
                    SaleRecord.fromJson(jsonMap(item, context: 'sales record')),
              )
              .toList()
        : const [],
  );

  JsonMap toJson() => {
    'store_id': storeId,
    if (dateFrom != null) 'date_from': _dateOnly(dateFrom!),
    if (dateTo != null) 'date_to': _dateOnly(dateTo!),
    'counter_sales': counterSales,
    'online_sales': onlineSales,
    'total_sales': totalSales,
    'order_count': orderCount,
    'delivered_orders': deliveredOrders,
    'average_order_value': averageOrderValue,
    'payment_breakdown': paymentBreakdown.toJson(),
    'sales_records': salesRecords.map((record) => record.toJson()).toList(),
  };
}

String _dateOnly(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
