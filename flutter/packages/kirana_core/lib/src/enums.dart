/// Lifecycle states used by the order API.
enum OrderStatus {
  newOrder('NEW', 'New'),
  accepted('ACCEPTED', 'Accepted'),
  preparing('PREPARING', 'Preparing'),
  ready('READY', 'Ready'),
  outForDelivery('OUT_FOR_DELIVERY', 'Out for delivery'),
  delivered('DELIVERED', 'Delivered'),
  cancelled('CANCELLED', 'Cancelled');

  const OrderStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  bool get isTerminal => this == delivered || this == cancelled;

  bool get isInProgress => !isTerminal && this != newOrder;

  List<OrderStatus> get allowedTransitions => switch (this) {
    newOrder => const [accepted, cancelled],
    accepted => const [preparing, cancelled],
    preparing => const [ready, cancelled],
    ready => const [outForDelivery, cancelled],
    outForDelivery => const [delivered],
    delivered || cancelled => const [],
  };

  bool canTransitionTo(OrderStatus next) => allowedTransitions.contains(next);

  static OrderStatus fromJson(Object? value) {
    final normalized = value?.toString().trim().toUpperCase();
    return values.firstWhere(
      (status) => status.apiValue == normalized,
      orElse: () => throw FormatException('Unknown order status: $value'),
    );
  }
}

enum PaymentMethod {
  cod('COD', 'Cash on delivery'),
  upi('UPI', 'UPI'),
  payAtShop('PAY_AT_SHOP', 'Pay at shop'),
  udhaar('UDHAAR', 'Udhaar');

  const PaymentMethod(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static PaymentMethod fromJson(Object? value) {
    final normalized = value?.toString().trim().toUpperCase();
    return values.firstWhere(
      (method) => method.apiValue == normalized,
      orElse: () => throw FormatException('Unknown payment method: $value'),
    );
  }
}

enum PaymentStatus {
  pending('PENDING', 'Pending'),
  collected('COLLECTED', 'Collected'),
  udhaarPosted('UDHAAR_POSTED', 'Posted to khata');

  const PaymentStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  bool get isSettled => this == collected || this == udhaarPosted;

  static PaymentStatus fromJson(Object? value) {
    final normalized = value?.toString().trim().toUpperCase();
    return values.firstWhere(
      (status) => status.apiValue == normalized,
      orElse: () => throw FormatException('Unknown payment status: $value'),
    );
  }
}

enum KhataEntryType {
  debit('DEBIT', 'Debit'),
  credit('CREDIT', 'Credit');

  const KhataEntryType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static KhataEntryType fromJson(Object? value) {
    final normalized = value?.toString().trim().toUpperCase();
    return values.firstWhere(
      (type) => type.apiValue == normalized,
      orElse: () => throw FormatException('Unknown khata entry type: $value'),
    );
  }
}
