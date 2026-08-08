# kirana_core

Shared, dependency-light building blocks for the Kirana Saarthi Flutter apps:

- immutable API models with hand-written snake_case JSON serialization;
- a typed `dart:io` API client and structured `ApiException` failures;
- Material 3 light/dark themes and shared layout tokens;
- Indian currency, date, phone, distance, and order-number formatters.

## API setup

`KiranaApi()` reads its default URL at compile time. Android emulator builds use
the bundled default (`http://10.0.2.2/kirana_api/public`):

```dart
final api = KiranaApi();
final stores = await api.getStores();
```

Override the server per environment without changing source code:

```sh
flutter run --dart-define=API_BASE_URL=https://api.example.com
```

For delivery staff, `loginDeliveryStaff` returns a `DeliveryLoginResult` and
automatically applies its bearer token to subsequent calls made by that client.
Call `close()` when a long-lived client is no longer needed.

## Theme and formatting

```dart
MaterialApp(
  theme: KiranaTheme.lightTheme,
  darkTheme: KiranaTheme.darkTheme,
);

final amount = formatCurrency(123456); // ₹1,23,456
```
