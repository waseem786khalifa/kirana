import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/core_customer_repository.dart';
import 'src/customer_controller.dart';
import 'src/session_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    KiranaCustomerApp(
      controller: CustomerController(
        CoreCustomerRepository(),
        FileSessionStore(),
      ),
    ),
  );
}
