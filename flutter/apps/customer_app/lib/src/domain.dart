enum PaymentChoice { cod, upi }

class CustomerProfile {
  const CustomerProfile({required this.name, required this.mobile});

  final String name;
  final String mobile;

  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    'mobile': mobile,
  };

  factory CustomerProfile.fromJson(Map<String, Object?> json) {
    return CustomerProfile(
      name: json['name'] as String? ?? '',
      mobile: json['mobile'] as String? ?? '',
    );
  }
}

class CustomerStore {
  const CustomerStore({
    required this.id,
    required this.code,
    required this.name,
    required this.address,
    required this.isOpen,
    required this.deliveryAvailable,
    required this.minimumOrder,
    required this.freeDeliveryAbove,
    required this.deliveryCharge,
    required this.expectedDeliveryTime,
    required this.codEnabled,
    required this.upiEnabled,
    this.phone = '',
    this.logoUrl = '',
    this.bannerUrl = '',
    this.description = '',
    this.openingTime = '',
    this.closingTime = '',
    this.categories = const <String>[],
    this.productCount = 0,
    this.maxSaving = 0,
    this.maxDiscountPercent = 0,
  });

  final int id;
  final String code;
  final String name;
  final String address;
  final bool isOpen;
  final bool deliveryAvailable;
  final double minimumOrder;
  final double freeDeliveryAbove;
  final double deliveryCharge;
  final String expectedDeliveryTime;
  final bool codEnabled;
  final bool upiEnabled;
  final String phone;
  final String logoUrl;
  final String bannerUrl;
  final String description;
  final String openingTime;
  final String closingTime;
  final List<String> categories;
  final int productCount;
  final double maxSaving;
  final int maxDiscountPercent;
}

class CustomerProduct {
  const CustomerProduct({
    required this.id,
    required this.storeId,
    required this.name,
    required this.category,
    required this.packSize,
    required this.mrp,
    required this.price,
    required this.stock,
    required this.imageUrl,
    required this.available,
  });

  final int id;
  final int storeId;
  final String name;
  final String category;
  final String packSize;
  final double mrp;
  final double price;
  final int stock;
  final String imageUrl;
  final bool available;

  double get saving => (mrp - price).clamp(0, double.infinity);
}

class CartLine {
  const CartLine({required this.product, required this.quantity});

  final CustomerProduct product;
  final int quantity;

  double get total => product.price * quantity;

  CartLine copyWith({int? quantity}) =>
      CartLine(product: product, quantity: quantity ?? this.quantity);
}

class DeliveryAddress {
  const DeliveryAddress({
    required this.addressLine,
    required this.landmark,
    required this.pincode,
  });

  final String addressLine;
  final String landmark;
  final String pincode;
}

class CheckoutDraft {
  const CheckoutDraft({
    required this.profile,
    required this.store,
    required this.lines,
    required this.address,
    required this.payment,
    required this.subtotal,
    required this.deliveryCharge,
    required this.total,
    required this.idempotencyKey,
  });

  final CustomerProfile profile;
  final CustomerStore store;
  final List<CartLine> lines;
  final DeliveryAddress address;
  final PaymentChoice payment;
  final double subtotal;
  final double deliveryCharge;
  final double total;
  final String idempotencyKey;
}

class CustomerOrderItem {
  const CustomerOrderItem({
    required this.name,
    required this.packSize,
    required this.price,
    required this.quantity,
  });

  final String name;
  final String packSize;
  final double price;
  final int quantity;
}

class CustomerOrder {
  const CustomerOrder({
    required this.id,
    required this.storeId,
    required this.status,
    required this.paymentMethod,
    required this.total,
    required this.createdAt,
    required this.items,
    this.rejectionReason,
  });

  final String id;
  final int storeId;
  final String status;
  final String paymentMethod;
  final double total;
  final DateTime createdAt;
  final List<CustomerOrderItem> items;
  final String? rejectionReason;
}

String formatRupees(num value) {
  final bool hasPaise = value % 1 != 0;
  final String raw = value.toStringAsFixed(hasPaise ? 2 : 0);
  final List<String> parts = raw.split('.');
  final String digits = parts.first;
  if (digits.length <= 3) return '₹$raw';

  final String tail = digits.substring(digits.length - 3);
  String head = digits.substring(0, digits.length - 3);
  final List<String> groups = <String>[];
  while (head.length > 2) {
    groups.insert(0, head.substring(head.length - 2));
    head = head.substring(0, head.length - 2);
  }
  if (head.isNotEmpty) groups.insert(0, head);
  final String formatted = '${groups.join(',')},$tail';
  return parts.length == 2 ? '₹$formatted.${parts[1]}' : '₹$formatted';
}
