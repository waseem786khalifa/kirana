# Kirana Saarthi Flutter Suite

This folder contains three independent Android applications backed by one shared
PHP/MySQL API.

## Projects

- `apps/customer_app` — store discovery, catalog, cart, checkout and order tracking
- `apps/store_manager_app` — live order queue, inventory and delivery-team management
- `apps/delivery_staff_app` — rider login, assigned deliveries and status updates
- `packages/kirana_core` — shared models, API client, status enums, formatting and theme

Each app has its own Android application id:

- `com.kiranasaarthi.kirana_customer`
- `com.kiranasaarthi.kirana_manager`
- `com.kiranasaarthi.kirana_delivery`

## Local API URL

The default API URL is suitable for an Android emulator:

```text
http://10.0.2.2/kirana_api/public
```

For a physical phone on the same Wi-Fi, pass the computer's LAN address:

```powershell
flutter run --dart-define=API_BASE_URL=http://YOUR_PC_IP/kirana_api/public
```

Windows Firewall must allow Apache on the private network for a physical phone.

## XAMPP setup

1. Start Apache and MySQL from XAMPP.
2. Import `../backend/schema.sql` in phpMyAdmin. It creates the
   `kirana_saarthi` database without dropping existing data.
3. Copy `../backend` to XAMPP `htdocs` as `kirana_api`.
4. Verify `http://localhost/kirana_api/public/health` returns JSON with
   `"status": "ok"`.

The backend defaults match a normal local XAMPP installation: MySQL at
`127.0.0.1:3306`, database `kirana_saarthi`, user `root`, and an empty password.
Copy `backend/.env.example` to `backend/.env` when different credentials are
needed.

## Run an app

Run `flutter pub get` once in the selected app folder, then:

```powershell
cd apps/customer_app
flutter run
```

Use the same command from `store_manager_app` or `delivery_staff_app` for the
other portals.

## Demo data

- Store code: `BALAJI123`
- Customer mobile: any valid 10-digit number
- Delivery rider 1: `9828877665`, PIN `1234`
- Delivery rider 2: `9928112233`, PIN `5678`

## Connected order flow

1. Customer selects a store, adds products and places an order.
2. Manager accepts it, marks it preparing/ready and assigns a rider.
3. Rider logs in, starts delivery and marks the order delivered.
4. Customer order history and manager dashboard receive the new status on
   refresh; both operational apps also poll the API periodically.

Order totals and stock validation are performed by the PHP API. Client-supplied
prices are not trusted.
