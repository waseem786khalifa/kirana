# Kirana Saarthi Customer

Material 3 Android client for browsing a connected kirana store, managing a
basket, placing COD/UPI orders, and tracking order status.

The app uses the shared `../../packages/kirana_core` API package. By default the
core client points Android emulators at the local Kirana API. Override it for a
device or another environment with:

```sh
flutter run --dart-define=API_BASE_URL=http://10.0.2.2/kirana_api/public
```

Profile and selected-store details are kept in a small app-private temporary
file; no third-party persistence package is required.
