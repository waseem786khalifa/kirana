import 'domain.dart';

abstract interface class CustomerRepository {
  Future<List<CustomerStore>> getStores();

  Future<CustomerStore> getStoreByCode(String code);

  Future<List<CustomerProduct>> getProducts(int storeId);

  Future<List<CustomerOrder>> getOrders({
    required int storeId,
    required String customerPhone,
  });

  Future<CustomerOrder> createOrder(CheckoutDraft draft);
}

class CustomerRepositoryException implements Exception {
  const CustomerRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
